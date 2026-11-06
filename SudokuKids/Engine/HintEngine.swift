import Foundation

struct Hint: Equatable {
    enum Kind: Equatable {
        case technique(Technique)
        /// The player placed a wrong number here.
        case mistake
        /// No technique applies, so we peek at the answer.
        case peek
    }

    let cell: Int
    /// The correct digit for `cell`.
    let value: Int
    let kind: Kind
    let title: String
    let message: String
    /// The same explanation with symbols turned into words, for reading aloud.
    let spoken: String
    /// Cells softly highlighted so the child can follow the reasoning.
    let focusCells: [Int]
    /// Cells highlighted strongly (the pointing squares or the twins).
    let keyCells: [Int]

    var isMistake: Bool { kind == .mistake }

    var technique: Technique? {
        if case .technique(let t) = kind { return t }
        return nil
    }
}

enum HintEngine {
    /// Builds a kid-friendly hint for the current board.
    static func hint(values: [Int], puzzle: Puzzle, symbols: SymbolSet) -> Hint? {
        let geo = puzzle.size.geometry

        // Wrong numbers come first: everything else depends on them.
        if let wrong = (0..<geo.count).first(where: {
            puzzle.givens[$0] == 0 && values[$0] != 0 && values[$0] != puzzle.solution[$0]
        }) {
            let text = { (name: (Int) -> String) in
                "The \(name(values[wrong])) here doesn't fit. Erase it and try something else."
            }
            return Hint(cell: wrong, value: puzzle.solution[wrong], kind: .mistake,
                        title: "Oops, let's fix this one!",
                        message: text(symbols.display), spoken: text(symbols.spoken),
                        focusCells: [wrong], keyCells: [])
        }

        if !values.contains(0) { return nil }

        var candidates = geo.candidates(values)
        if let p = LogicSolver.findPlacement(values, candidates, geo: geo) {
            return describe(p, after: nil, geo: geo, symbols: symbols)
        }

        // Cross numbers off with harder techniques until a square can be filled.
        var first: Elimination?
        for _ in 0..<12 {
            guard let e = LogicSolver.findElimination(values, candidates, geo: geo) else { break }
            if first == nil { first = e }
            LogicSolver.apply(e, to: &candidates)
            if let p = LogicSolver.findPlacement(values, candidates, geo: geo), p.value == puzzle.solution[p.cell] {
                return describe(p, after: first, geo: geo, symbols: symbols)
            }
        }

        guard let cell = SudokuSolver.bestEmptyCell(values, geo: geo)?.0 ?? values.firstIndex(of: 0) else { return nil }
        let text = { (name: (Int) -> String) in
            "There's no easy step right now, so here's a peek: this square is \(name(puzzle.solution[cell])). Filling it in will open up new clues!"
        }
        return Hint(cell: cell, value: puzzle.solution[cell], kind: .peek, title: "This one's tricky!",
                    message: text(symbols.display), spoken: text(symbols.spoken),
                    focusCells: [cell], keyCells: [])
    }

    /// Explains a placement, optionally with the elimination that made it possible.
    static func describe(_ p: Placement, after elimination: Elimination?, geo: Geometry, symbols: SymbolSet) -> Hint {
        let title: String
        let kind: Technique
        let focus: [Int]
        let key: [Int]
        let build: ((Int) -> String) -> String
        let row = geo.row(p.cell) + 1
        let col = geo.col(p.cell) + 1

        if let e = elimination, e.technique == .pointing, let line = e.lineKind {
            kind = .pointing
            title = "Pointing line!"
            focus = e.focus
            key = e.key
            let lineName = "\(line.rawValue) \(e.lineIndex + 1)"
            build = { name in
                "The blue squares are the only places for \(name(e.digit)) in their box, and they're all in \(lineName). So no other square in \(lineName) can be \(name(e.digit)). Now the glowing square has to be \(name(p.value))!"
            }
        } else if let e = elimination, e.technique == .twins, e.digits.count == 2 {
            kind = .twins
            title = "Twin squares!"
            focus = e.focus
            key = e.key
            let place = unitName(e.unit, cell: e.key.first ?? p.cell, geo: geo)
            build = { name in
                "The two blue squares in \(place) can only be \(name(e.digits[0])) or \(name(e.digits[1])). They're twins! So nothing else in \(place) can be \(name(e.digits[0])) or \(name(e.digits[1])). Now the glowing square has to be \(name(p.value))!"
            }
        } else if p.technique == .lastNumber {
            kind = .lastNumber
            title = "Only one fits!"
            focus = p.focus
            key = []
            build = { name in
                "Look at row \(row), column \(col) and its box. Everything except \(name(p.value)) is already used there, so this square must be \(name(p.value))!"
            }
        } else {
            kind = .onlySpot
            title = "Find the only spot!"
            focus = p.focus
            key = []
            let place = unitName(p.unit, cell: p.cell, geo: geo)
            let capitalized = place.prefix(1).uppercased() + place.dropFirst()
            build = { name in
                "\(capitalized) still needs \(name(p.value)). Check its empty squares: \(name(p.value)) is blocked everywhere except the glowing one!"
            }
        }

        let message = build(symbols.display)
        return Hint(cell: p.cell, value: p.value, kind: .technique(kind), title: title,
                    message: message, spoken: "\(title) \(build(symbols.spoken))",
                    focusCells: focus, keyCells: key)
    }

    private static func unitName(_ unit: GridUnit?, cell: Int, geo: Geometry) -> String {
        switch unit?.kind {
        case .row: return "row \(geo.row(cell) + 1)"
        case .column: return "column \(geo.col(cell) + 1)"
        default: return "this box"
        }
    }
}
