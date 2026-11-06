import Foundation

/// The three board sizes. Grids are stored as flat arrays, row by row. 0 means empty.
enum GridSize: Int, Codable, CaseIterable, Identifiable, Hashable {
    case four = 4
    case six = 6
    case nine = 9

    var id: Int { rawValue }
    var n: Int { rawValue }
    var cellCount: Int { n * n }

    /// Boxes are 2×2 on 4×4, 2 rows × 3 columns on 6×6, and 3×3 on 9×9.
    var boxRows: Int { self == .nine ? 3 : 2 }
    var boxCols: Int { self == .four ? 2 : 3 }

    var label: String { "\(n)×\(n)" }

    var nickname: String {
        switch self {
        case .four: return "Tiny"
        case .six: return "Junior"
        case .nine: return "Classic"
        }
    }

    var emoji: String {
        switch self {
        case .four: return "🐣"
        case .six: return "🐥"
        case .nine: return "🦉"
        }
    }

    var geometry: Geometry {
        switch self {
        case .four: return Geometry.four
        case .six: return Geometry.six
        case .nine: return Geometry.nine
        }
    }
}

enum UnitKind: String, Codable, Equatable {
    case row, column, box
}

/// A row, column or box.
struct GridUnit: Equatable {
    let kind: UnitKind
    let index: Int
    let cells: [Int]
}

/// Precomputed rows, columns, boxes and neighbours for one board size.
struct Geometry {
    let n: Int
    let count: Int
    let boxRows: Int
    let boxCols: Int
    /// Bits 1...n set.
    let allMask: Int
    let rows: [[Int]]
    let cols: [[Int]]
    let boxes: [[Int]]
    /// Boxes first, then rows, then columns (boxes are the easiest for kids to scan).
    let units: [GridUnit]
    /// The cells that share a row, column or box with each cell.
    let peers: [[Int]]

    static let four = Geometry(n: 4, boxRows: 2, boxCols: 2)
    static let six = Geometry(n: 6, boxRows: 2, boxCols: 3)
    static let nine = Geometry(n: 9, boxRows: 3, boxCols: 3)

    private init(n: Int, boxRows: Int, boxCols: Int) {
        self.n = n
        self.count = n * n
        self.boxRows = boxRows
        self.boxCols = boxCols
        self.allMask = ((1 << (n + 1)) - 1) & ~1

        let boxesPerRow = n / boxCols
        var rows: [[Int]] = []
        var cols: [[Int]] = []
        var boxes: [[Int]] = []
        for k in 0..<n {
            rows.append((0..<n).map { k * n + $0 })
            cols.append((0..<n).map { $0 * n + k })
            let r0 = (k / boxesPerRow) * boxRows
            let c0 = (k % boxesPerRow) * boxCols
            var cells: [Int] = []
            for r in 0..<boxRows {
                for c in 0..<boxCols {
                    cells.append((r0 + r) * n + c0 + c)
                }
            }
            boxes.append(cells)
        }
        self.rows = rows
        self.cols = cols
        self.boxes = boxes

        var units: [GridUnit] = []
        for (i, cells) in boxes.enumerated() { units.append(GridUnit(kind: .box, index: i, cells: cells)) }
        for (i, cells) in rows.enumerated() { units.append(GridUnit(kind: .row, index: i, cells: cells)) }
        for (i, cells) in cols.enumerated() { units.append(GridUnit(kind: .column, index: i, cells: cells)) }
        self.units = units

        var peers: [[Int]] = []
        for i in 0..<(n * n) {
            let r = i / n
            let c = i % n
            let b = (r / boxRows) * boxesPerRow + c / boxCols
            var set = Set(rows[r] + cols[c] + boxes[b])
            set.remove(i)
            peers.append(set.sorted())
        }
        self.peers = peers
    }

    func row(_ i: Int) -> Int { i / n }
    func col(_ i: Int) -> Int { i % n }
    func box(_ i: Int) -> Int { (row(i) / boxRows) * (n / boxCols) + col(i) / boxCols }

    func areRelated(_ a: Int, _ b: Int) -> Bool {
        row(a) == row(b) || col(a) == col(b) || box(a) == box(b)
    }

    /// Bitmask of the digits that could go in cell `i`, given the other filled cells.
    func candidateMask(_ grid: [Int], _ i: Int) -> Int {
        var mask = allMask
        for p in peers[i] where grid[p] != 0 {
            mask &= ~(1 << grid[p])
        }
        return mask
    }

    /// Candidate masks for every empty cell (0 for filled cells).
    func candidates(_ grid: [Int]) -> [Int] {
        (0..<count).map { grid[$0] == 0 ? candidateMask(grid, $0) : 0 }
    }

    func digits(in mask: Int) -> [Int] {
        (1...n).filter { mask & (1 << $0) != 0 }
    }

    /// True when every row, column and box holds 1...n exactly once.
    func isSolved(_ grid: [Int]) -> Bool {
        guard grid.count == count else { return false }
        for unit in units {
            var seen = 0
            for i in unit.cells {
                let v = grid[i]
                guard v >= 1, v <= n, seen & (1 << v) == 0 else { return false }
                seen |= 1 << v
            }
        }
        return true
    }
}
