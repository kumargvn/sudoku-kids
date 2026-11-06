import Foundation

/// The solving techniques the app teaches, from easiest to hardest.
enum Technique: String, Codable, CaseIterable, Identifiable, Hashable {
    case lastNumber
    case onlySpot
    case pointing
    case twins

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lastNumber: return "Last Number Left"
        case .onlySpot: return "Only Spot Left"
        case .pointing: return "Pointing Line"
        case .twins: return "Twin Squares"
        }
    }

    var emoji: String {
        switch self {
        case .lastNumber: return "🎯"
        case .onlySpot: return "🔍"
        case .pointing: return "👉"
        case .twins: return "👯"
        }
    }

    var summary: String {
        switch self {
        case .lastNumber:
            return "Look at a square's row, column and box. If every number but one is already used, that last number goes in the square."
        case .onlySpot:
            return "Pick a number a box still needs. If it's blocked in every empty square but one, it must go in that last spot."
        case .pointing:
            return "If a number can only go in one row (or column) inside a box, it can't go anywhere else in that row outside the box."
        case .twins:
            return "If two squares in a group can only be the same two numbers, those numbers belong to them. Cross them off everywhere else in that group."
        }
    }

    var levelNote: String {
        switch self {
        case .lastNumber, .onlySpot: return "Used in Easy and Medium"
        case .pointing, .twins: return "Used in Hard and Expert"
        }
    }
}

/// A square that can be filled in with a known number.
struct Placement: Equatable {
    let technique: Technique
    let cell: Int
    let value: Int
    let unit: GridUnit?
    let focus: [Int]
}

struct Removal: Equatable {
    let cell: Int
    let digit: Int
}

/// A step that crosses numbers off without filling a square yet.
struct Elimination: Equatable {
    let technique: Technique
    let removals: [Removal]
    /// Pointing: the digit, the line kind and index.
    let digit: Int
    let lineKind: UnitKind?
    let lineIndex: Int
    /// Twins: the two digits and their group.
    let digits: [Int]
    let unit: GridUnit?
    let focus: [Int]
    /// Squares to highlight strongly (the pointing squares, or the twins).
    let key: [Int]
}

/// Solves like a person would, one technique at a time.
enum LogicSolver {
    // MARK: Placements

    static func nakedSingle(_ v: [Int], _ c: [Int], geo: Geometry) -> Placement? {
        for i in 0..<geo.count where v[i] == 0 && c[i].nonzeroBitCount == 1 {
            return Placement(technique: .lastNumber, cell: i, value: geo.digits(in: c[i])[0], unit: nil, focus: geo.peers[i])
        }
        return nil
    }

    static func hiddenSingle(_ v: [Int], _ c: [Int], geo: Geometry) -> Placement? {
        for unit in geo.units {
            var present = 0
            for i in unit.cells where v[i] != 0 { present |= 1 << v[i] }
            for digit in 1...geo.n where present & (1 << digit) == 0 {
                var spot = -1
                var count = 0
                for i in unit.cells where v[i] == 0 && c[i] & (1 << digit) != 0 {
                    spot = i
                    count += 1
                    if count > 1 { break }
                }
                if count == 1 {
                    return Placement(technique: .onlySpot, cell: spot, value: digit, unit: unit, focus: unit.cells)
                }
            }
        }
        return nil
    }

    static func findPlacement(_ v: [Int], _ c: [Int], geo: Geometry) -> Placement? {
        nakedSingle(v, c, geo: geo) ?? hiddenSingle(v, c, geo: geo)
    }

    // MARK: Eliminations

    static func pointing(_ v: [Int], _ c: [Int], geo: Geometry) -> Elimination? {
        for boxCells in geo.boxes {
            for digit in 1...geo.n {
                let spots = boxCells.filter { v[$0] == 0 && c[$0] & (1 << digit) != 0 }
                if spots.count < 2 { continue }
                for kind in [UnitKind.row, UnitKind.column] {
                    let index = kind == .row ? geo.row(spots[0]) : geo.col(spots[0])
                    let allInLine = spots.allSatisfy { (kind == .row ? geo.row($0) : geo.col($0)) == index }
                    if !allInLine { continue }
                    let lineCells = kind == .row ? geo.rows[index] : geo.cols[index]
                    let removals = lineCells
                        .filter { !boxCells.contains($0) && v[$0] == 0 && c[$0] & (1 << digit) != 0 }
                        .map { Removal(cell: $0, digit: digit) }
                    if !removals.isEmpty {
                        let focus = Array(Set(boxCells + lineCells)).sorted()
                        return Elimination(technique: .pointing, removals: removals, digit: digit, lineKind: kind,
                                           lineIndex: index, digits: [], unit: nil, focus: focus, key: spots)
                    }
                }
            }
        }
        return nil
    }

    static func twins(_ v: [Int], _ c: [Int], geo: Geometry) -> Elimination? {
        for unit in geo.units {
            let pairs = unit.cells.filter { v[$0] == 0 && c[$0].nonzeroBitCount == 2 }
            guard pairs.count >= 2 else { continue }
            for a in 0..<(pairs.count - 1) {
                for b in (a + 1)..<pairs.count where c[pairs[a]] == c[pairs[b]] {
                    let mask = c[pairs[a]]
                    var removals: [Removal] = []
                    for i in unit.cells where i != pairs[a] && i != pairs[b] && v[i] == 0 {
                        for digit in geo.digits(in: c[i] & mask) {
                            removals.append(Removal(cell: i, digit: digit))
                        }
                    }
                    if !removals.isEmpty {
                        return Elimination(technique: .twins, removals: removals, digit: 0, lineKind: nil, lineIndex: 0,
                                           digits: geo.digits(in: mask), unit: unit, focus: unit.cells,
                                           key: [pairs[a], pairs[b]])
                    }
                }
            }
        }
        return nil
    }

    static func findElimination(_ v: [Int], _ c: [Int], geo: Geometry) -> Elimination? {
        pointing(v, c, geo: geo) ?? twins(v, c, geo: geo)
    }

    static func apply(_ e: Elimination, to c: inout [Int]) {
        for r in e.removals { c[r.cell] &= ~(1 << r.digit) }
    }

    // MARK: Whole-puzzle check

    /// True if the puzzle can be finished with placements only, or also with eliminations.
    static func isSolvable(_ grid: [Int], geo: Geometry, allowEliminations: Bool) -> Bool {
        var v = grid
        var c = geo.candidates(v)
        for _ in 0..<1000 {
            if !v.contains(0) { return true }
            if let p = findPlacement(v, c, geo: geo) {
                v[p.cell] = p.value
                c[p.cell] = 0
                for q in geo.peers[p.cell] { c[q] &= ~(1 << p.value) }
                continue
            }
            guard allowEliminations, let e = findElimination(v, c, geo: geo) else { return false }
            apply(e, to: &c)
        }
        return false
    }
}
