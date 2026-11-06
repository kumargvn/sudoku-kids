import Foundation

enum PuzzleGenerator {
    /// Builds a puzzle with exactly one answer that fits the level's rule.
    static func generate(size: GridSize, difficulty: Difficulty, seed: UInt64? = nil) -> Puzzle {
        var rng = SeededGenerator(seed: seed ?? UInt64.random(in: UInt64.min...UInt64.max))
        var best: Puzzle?
        for _ in 0..<8 {
            let candidate = attempt(size: size, difficulty: difficulty, rng: &rng)
            if candidate.clueCount <= difficulty.targetClues(for: size) { return candidate }
            if best == nil || candidate.clueCount < best!.clueCount { best = candidate }
        }
        return best!
    }

    private static func attempt(size: GridSize, difficulty: Difficulty, rng: inout SeededGenerator) -> Puzzle {
        let geo = size.geometry
        let target = difficulty.targetClues(for: size)
        var solution = [Int](repeating: 0, count: geo.count)
        _ = SudokuSolver.fillRandom(&solution, geo: geo, using: &rng)

        var givens = solution
        var clues = geo.count
        let order = Array(0..<geo.count).shuffled(using: &rng)

        for index in order {
            if clues <= target { break }
            let backup = givens[index]
            givens[index] = 0

            // Logic solving always reaches the single answer, so it also proves uniqueness.
            let keep: Bool
            switch difficulty.rule {
            case .placementsOnly: keep = LogicSolver.isSolvable(givens, geo: geo, allowEliminations: false)
            case .allTechniques: keep = LogicSolver.isSolvable(givens, geo: geo, allowEliminations: true)
            case .uniqueOnly: keep = SudokuSolver.countSolutions(givens, geo: geo, limit: 2) == 1
            }

            if keep {
                clues -= 1
            } else {
                givens[index] = backup
            }
        }
        return Puzzle(size: size, givens: givens, solution: solution, difficulty: difficulty)
    }
}
