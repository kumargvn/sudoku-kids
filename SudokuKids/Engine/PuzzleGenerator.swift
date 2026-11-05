import Foundation

enum PuzzleGenerator {
    /// Builds a puzzle with exactly one solution.
    /// Easy and Medium puzzles are also guaranteed to be solvable with
    /// "only one number fits" reasoning, which is what the hints explain.
    static func generate(difficulty: Difficulty, seed: UInt64? = nil) -> Puzzle {
        var rng = SeededGenerator(seed: seed ?? UInt64.random(in: UInt64.min...UInt64.max))
        var best: Puzzle?
        for _ in 0..<8 {
            let candidate = attempt(difficulty: difficulty, rng: &rng)
            if candidate.clueCount <= difficulty.targetClues { return candidate }
            if best == nil || candidate.clueCount < best!.clueCount { best = candidate }
        }
        return best!
    }

    private static func attempt(difficulty: Difficulty, rng: inout SeededGenerator) -> Puzzle {
        var solution = [Int](repeating: 0, count: Sudoku.cellCount)
        _ = SudokuSolver.fillRandom(&solution, using: &rng)

        var givens = solution
        var clues = Sudoku.cellCount
        let order = Array(0..<Sudoku.cellCount).shuffled(using: &rng)

        for index in order {
            if clues <= difficulty.targetClues { break }
            let backup = givens[index]
            givens[index] = 0

            // Beginner logic always leads to a single answer, so it also proves uniqueness.
            let keepRemoved = difficulty.requiresBeginnerLogic
                ? LogicSolver.solvableWithSingles(givens)
                : SudokuSolver.countSolutions(givens, limit: 2) == 1

            if keepRemoved {
                clues -= 1
            } else {
                givens[index] = backup
            }
        }
        return Puzzle(givens: givens, solution: solution, difficulty: difficulty)
    }
}

/// Human-style solving with the two beginner techniques.
enum LogicSolver {
    static func solvableWithSingles(_ grid: [Int]) -> Bool {
        var work = grid
        while work.contains(0) {
            guard let step = HintEngine.findSingle(in: work) else { return false }
            work[step.cell] = step.value
        }
        return true
    }
}
