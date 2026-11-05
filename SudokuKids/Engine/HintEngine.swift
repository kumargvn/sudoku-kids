import Foundation

struct Hint: Equatable {
    enum Kind: Equatable {
        /// Every other digit is already used around this cell.
        case onlyNumberLeft
        /// In this row/column/box, the digit fits in only one spot.
        case onlySpotLeft(UnitKind)
        /// The player placed a wrong number here.
        case mistake
        /// No beginner step available, so we peek at the answer.
        case peek
    }

    let cell: Int
    /// The correct digit for `cell`.
    let value: Int
    let kind: Kind
    let title: String
    let message: String
    /// Cells to softly highlight so the child can see the reasoning.
    let focusCells: [Int]

    var isMistake: Bool { kind == .mistake }
}

enum HintEngine {
    struct SingleStep {
        let cell: Int
        let value: Int
        let kind: Hint.Kind
        let unitCells: [Int]
    }

    /// Finds the next easy step on a grid with no wrong numbers in it.
    static func findSingle(in grid: [Int]) -> SingleStep? {
        var masks = [Int](repeating: 0, count: Sudoku.cellCount)
        for i in 0..<Sudoku.cellCount where grid[i] == 0 {
            masks[i] = Sudoku.candidateMask(grid, i)
        }

        // 1. A cell where only one number is possible.
        for i in 0..<Sudoku.cellCount where grid[i] == 0 && masks[i].nonzeroBitCount == 1 {
            let value = Sudoku.digits(in: masks[i])[0]
            return SingleStep(cell: i, value: value, kind: .onlyNumberLeft, unitCells: Sudoku.peers[i])
        }

        // 2. A number that fits in only one spot of a box, row or column.
        //    Boxes first: they are the easiest for kids to scan.
        let ordered = Sudoku.units.filter { $0.kind == .box }
            + Sudoku.units.filter { $0.kind != .box }
        for unit in ordered {
            var present = 0
            for i in unit.cells where grid[i] != 0 { present |= 1 << grid[i] }
            for digit in 1...9 where present & (1 << digit) == 0 {
                var spot = -1
                var count = 0
                for i in unit.cells where grid[i] == 0 && masks[i] & (1 << digit) != 0 {
                    spot = i
                    count += 1
                    if count > 1 { break }
                }
                if count == 1 {
                    return SingleStep(cell: spot, value: digit, kind: .onlySpotLeft(unit.kind), unitCells: unit.cells)
                }
            }
        }
        return nil
    }

    /// Builds a kid-friendly hint for the current board.
    static func hint(values: [Int], puzzle: Puzzle) -> Hint? {
        // Wrong numbers come first: everything else depends on them.
        if let wrong = (0..<Sudoku.cellCount).first(where: {
            puzzle.givens[$0] == 0 && values[$0] != 0 && values[$0] != puzzle.solution[$0]
        }) {
            return Hint(
                cell: wrong,
                value: puzzle.solution[wrong],
                kind: .mistake,
                title: "Oops, let's fix this one!",
                message: "The \(values[wrong]) here doesn't fit. Erase it and try a different number.",
                focusCells: [wrong]
            )
        }

        if !values.contains(0) { return nil }

        if let step = findSingle(in: values) {
            let row = Sudoku.row(step.cell) + 1
            let col = Sudoku.col(step.cell) + 1
            switch step.kind {
            case .onlyNumberLeft:
                return Hint(
                    cell: step.cell,
                    value: step.value,
                    kind: step.kind,
                    title: "Only one number fits!",
                    message: "Look at row \(row), column \(col) and its box. Every number except \(step.value) is already used there, so this square must be \(step.value)! 🎯",
                    focusCells: step.unitCells
                )
            case .onlySpotLeft(let unitKind):
                let place: String
                switch unitKind {
                case .row: place = "Row \(row)"
                case .column: place = "Column \(col)"
                case .box: place = "This 3×3 box"
                }
                return Hint(
                    cell: step.cell,
                    value: step.value,
                    kind: step.kind,
                    title: "Find the only spot!",
                    message: "\(place) needs a \(step.value). Check its empty squares: the \(step.value) is blocked everywhere except the glowing one! 🔍",
                    focusCells: step.unitCells
                )
            default:
                break
            }
        }

        // Nothing simple left: reveal the cell with the fewest choices.
        guard let cell = SudokuSolver.bestEmptyCell(values)?.0 else { return nil }
        return Hint(
            cell: cell,
            value: puzzle.solution[cell],
            kind: .peek,
            title: "This one's tricky!",
            message: "There's no easy step right now, so here's a peek: this square is \(puzzle.solution[cell]). Filling it in will open up new clues!",
            focusCells: [cell]
        )
    }
}
