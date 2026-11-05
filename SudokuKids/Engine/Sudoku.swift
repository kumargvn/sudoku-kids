import Foundation

/// Static geometry helpers for a standard 9x9 Sudoku grid.
/// A grid is stored as a flat array of 81 Ints, row by row. 0 means empty.
enum Sudoku {
    static let size = 9
    static let cellCount = 81
    /// Bits 1...9 set: every digit is still possible.
    static let allDigitsMask = 0b11_1111_1110

    static func row(_ i: Int) -> Int { i / 9 }
    static func col(_ i: Int) -> Int { i % 9 }
    static func box(_ i: Int) -> Int { (i / 27) * 3 + (i % 9) / 3 }

    static let rows: [[Int]] = (0..<9).map { r in (0..<9).map { r * 9 + $0 } }
    static let cols: [[Int]] = (0..<9).map { c in (0..<9).map { $0 * 9 + c } }
    static let boxes: [[Int]] = (0..<9).map { b in
        let r0 = (b / 3) * 3
        let c0 = (b % 3) * 3
        return (0..<9).map { (r0 + $0 / 3) * 9 + c0 + $0 % 3 }
    }

    /// A row, column or box.
    struct Unit {
        let kind: UnitKind
        let index: Int
        let cells: [Int]
    }

    /// All 27 units, tagged with their kind and index.
    static let units: [Unit] = {
        var all: [Unit] = []
        for (n, cells) in rows.enumerated() { all.append(Unit(kind: .row, index: n, cells: cells)) }
        for (n, cells) in cols.enumerated() { all.append(Unit(kind: .column, index: n, cells: cells)) }
        for (n, cells) in boxes.enumerated() { all.append(Unit(kind: .box, index: n, cells: cells)) }
        return all
    }()

    /// The 20 cells that share a row, column or box with each cell.
    static let peers: [[Int]] = (0..<81).map { i in
        var set = Set(rows[row(i)] + cols[col(i)] + boxes[box(i)])
        set.remove(i)
        return set.sorted()
    }

    static func areRelated(_ a: Int, _ b: Int) -> Bool {
        row(a) == row(b) || col(a) == col(b) || box(a) == box(b)
    }

    /// Bitmask of digits that could legally go in cell `i` given the other filled cells.
    static func candidateMask(_ grid: [Int], _ i: Int) -> Int {
        var mask = allDigitsMask
        for p in peers[i] {
            let v = grid[p]
            if v != 0 { mask &= ~(1 << v) }
        }
        return mask
    }

    static func digits(in mask: Int) -> [Int] {
        (1...9).filter { mask & (1 << $0) != 0 }
    }

    /// True when every row, column and box contains 1...9 exactly once.
    static func isSolved(_ grid: [Int]) -> Bool {
        guard grid.count == 81 else { return false }
        for unit in units {
            var seen = 0
            for i in unit.cells {
                let v = grid[i]
                guard (1...9).contains(v), seen & (1 << v) == 0 else { return false }
                seen |= 1 << v
            }
        }
        return true
    }
}

enum UnitKind: String, Codable, Equatable {
    case row, column, box

    var kidName: String {
        switch self {
        case .row: return "row"
        case .column: return "column"
        case .box: return "3×3 box"
        }
    }
}
