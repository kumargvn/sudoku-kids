import Foundation

/// Backtracking solver used to build full grids and to check uniqueness.
enum SudokuSolver {
    /// Fills every empty cell with a random valid digit. Returns false if impossible.
    static func fillRandom<G: RandomNumberGenerator>(_ grid: inout [Int], using rng: inout G) -> Bool {
        guard let cell = bestEmptyCell(grid) else { return true }
        let (index, mask) = cell
        if mask == 0 { return false }
        var choices = Sudoku.digits(in: mask)
        choices.shuffle(using: &rng)
        for digit in choices {
            grid[index] = digit
            if fillRandom(&grid, using: &rng) { return true }
        }
        grid[index] = 0
        return false
    }

    /// Counts solutions, stopping early once `limit` is reached.
    static func countSolutions(_ grid: [Int], limit: Int = 2) -> Int {
        var work = grid
        var count = 0

        func search() {
            if count >= limit { return }
            guard let cell = bestEmptyCell(work) else {
                count += 1
                return
            }
            let (index, mask) = cell
            if mask == 0 { return }
            for digit in Sudoku.digits(in: mask) {
                work[index] = digit
                search()
                if count >= limit { break }
            }
            work[index] = 0
        }

        search()
        return count
    }

    /// Returns the first solution found, or nil if there is none.
    static func solve(_ grid: [Int]) -> [Int]? {
        var work = grid
        var found: [Int]?

        func search() -> Bool {
            guard let cell = bestEmptyCell(work) else {
                found = work
                return true
            }
            let (index, mask) = cell
            if mask == 0 { return false }
            for digit in Sudoku.digits(in: mask) {
                work[index] = digit
                if search() { return true }
            }
            work[index] = 0
            return false
        }

        _ = search()
        return found
    }

    /// The empty cell with the fewest candidates (fastest to branch on), plus its candidate mask.
    static func bestEmptyCell(_ grid: [Int]) -> (Int, Int)? {
        var best: (Int, Int)?
        var bestCount = 10
        for i in 0..<Sudoku.cellCount where grid[i] == 0 {
            let mask = Sudoku.candidateMask(grid, i)
            let n = mask.nonzeroBitCount
            if n < bestCount {
                best = (i, mask)
                bestCount = n
                if n <= 1 { break }
            }
        }
        return best
    }
}
