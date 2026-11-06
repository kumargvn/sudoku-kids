import Foundation

/// Backtracking solver used to build full grids and to check that a puzzle has one answer.
enum SudokuSolver {
    /// Fills every empty cell with a random valid digit. Returns false if impossible.
    static func fillRandom<G: RandomNumberGenerator>(_ grid: inout [Int], geo: Geometry, using rng: inout G) -> Bool {
        guard let best = bestEmptyCell(grid, geo: geo) else { return true }
        let (index, mask) = best
        if mask == 0 { return false }
        var choices = geo.digits(in: mask)
        choices.shuffle(using: &rng)
        for digit in choices {
            grid[index] = digit
            if fillRandom(&grid, geo: geo, using: &rng) { return true }
        }
        grid[index] = 0
        return false
    }

    /// Counts solutions, stopping once `limit` is reached.
    static func countSolutions(_ grid: [Int], geo: Geometry, limit: Int = 2) -> Int {
        var work = grid
        var count = 0

        func search() {
            if count >= limit { return }
            guard let best = bestEmptyCell(work, geo: geo) else {
                count += 1
                return
            }
            let (index, mask) = best
            if mask == 0 { return }
            for digit in geo.digits(in: mask) {
                work[index] = digit
                search()
                if count >= limit { break }
            }
            work[index] = 0
        }

        search()
        return count
    }

    /// The first solution found, or nil.
    static func solve(_ grid: [Int], geo: Geometry) -> [Int]? {
        var work = grid
        var found: [Int]?

        func search() -> Bool {
            guard let best = bestEmptyCell(work, geo: geo) else {
                found = work
                return true
            }
            let (index, mask) = best
            if mask == 0 { return false }
            for digit in geo.digits(in: mask) {
                work[index] = digit
                if search() { return true }
            }
            work[index] = 0
            return false
        }

        _ = search()
        return found
    }

    /// The empty cell with the fewest candidates, plus its candidate mask.
    static func bestEmptyCell(_ grid: [Int], geo: Geometry) -> (Int, Int)? {
        var best: (Int, Int)?
        var bestCount = Int.max
        for i in 0..<geo.count where grid[i] == 0 {
            let mask = geo.candidateMask(grid, i)
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
