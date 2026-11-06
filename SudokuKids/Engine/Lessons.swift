import Foundation

/// A real board where the next step uses one technique, for the Learn lessons.
struct LessonExample {
    let puzzle: Puzzle
    let values: [Int]
    let hint: Hint
    /// Answer choices for "which one goes in the glowing square?"
    let choices: [Int]
}

enum LessonBuilder {
    static func example(for technique: Technique, seed: UInt64 = UInt64.random(in: 1...UInt64.max)) -> LessonExample? {
        let geo = Geometry.nine
        var rng = SeededGenerator(seed: seed)

        for _ in 0..<60 {
            let simple = technique == .lastNumber || technique == .onlySpot
            let puzzle = PuzzleGenerator.generate(size: .nine, difficulty: simple ? .easy : .expert, seed: rng.next())
            var v = puzzle.givens

            switch technique {
            case .lastNumber:
                if let p = LogicSolver.nakedSingle(v, geo.candidates(v), geo: geo) {
                    return finish(puzzle, v, HintEngine.describe(p, after: nil, geo: geo, symbols: .numbers), &rng)
                }

            case .onlySpot:
                // A box where a number fits in one spot, and that spot still has other choices.
                let c = geo.candidates(v)
                for (index, box) in geo.boxes.enumerated() {
                    for digit in 1...9 where !box.contains(where: { v[$0] == digit }) {
                        let spots = box.filter { v[$0] == 0 && c[$0] & (1 << digit) != 0 }
                        if spots.count == 1, c[spots[0]].nonzeroBitCount > 1 {
                            let unit = GridUnit(kind: .box, index: index, cells: box)
                            let p = Placement(technique: .onlySpot, cell: spots[0], value: digit, unit: unit, focus: box)
                            return finish(puzzle, v, HintEngine.describe(p, after: nil, geo: geo, symbols: .numbers), &rng)
                        }
                    }
                }

            case .pointing, .twins:
                // Fill in easy steps until stuck, then see if this technique unlocks the next square.
                for _ in 0..<81 where v.contains(0) {
                    var c = geo.candidates(v)
                    if let p = LogicSolver.findPlacement(v, c, geo: geo) {
                        v[p.cell] = p.value
                        continue
                    }
                    var first: Elimination?
                    for _ in 0..<6 {
                        let found = technique == .pointing
                            ? LogicSolver.pointing(v, c, geo: geo)
                            : LogicSolver.twins(v, c, geo: geo)
                        guard let e = found else { break }
                        if first == nil { first = e }
                        LogicSolver.apply(e, to: &c)
                        if let q = LogicSolver.findPlacement(v, c, geo: geo) {
                            return finish(puzzle, v, HintEngine.describe(q, after: first, geo: geo, symbols: .numbers), &rng)
                        }
                    }
                    break
                }
            }
        }
        return nil
    }

    private static func finish(_ puzzle: Puzzle, _ values: [Int], _ hint: Hint, _ rng: inout SeededGenerator) -> LessonExample {
        var wrong = (1...9).filter { $0 != hint.value }
        wrong.shuffle(using: &rng)
        var choices = [hint.value] + wrong.prefix(2)
        choices.shuffle(using: &rng)
        return LessonExample(puzzle: puzzle, values: values, hint: hint, choices: choices)
    }
}
