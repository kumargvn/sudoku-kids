import SwiftUI

/// Draws any board size. Used by games and lessons.
struct BoardView: View {
    let size: GridSize
    let cells: [CellState]
    let symbols: SymbolSet
    var onTap: ((Int) -> Void)?

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cellSize = side / CGFloat(size.n)

            ZStack {
                VStack(spacing: 0) {
                    ForEach(0..<size.n, id: \.self) { r in
                        HStack(spacing: 0) {
                            ForEach(0..<size.n, id: \.self) { c in
                                let index = r * size.n + c
                                CellView(state: cells[index], size: cellSize, gridSize: size, symbols: symbols, row: r, col: c)
                                    .onTapGesture { onTap?(index) }
                            }
                        }
                    }
                }

                GridLines(n: size.n, everyRow: 1, everyCol: 1)
                    .stroke(Theme.ink.opacity(0.18), lineWidth: 1)
                    .allowsHitTesting(false)
                GridLines(n: size.n, everyRow: size.boxRows, everyCol: size.boxCols)
                    .stroke(Theme.ink, lineWidth: size == .nine ? 2.5 : 3)
                    .allowsHitTesting(false)
            }
            .frame(width: side, height: side)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.ink, lineWidth: 3))
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// Internal lines: every cell, or the box borders.
struct GridLines: Shape {
    let n: Int
    let everyRow: Int
    let everyCol: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step = rect.width / CGFloat(n)
        for k in stride(from: everyCol, to: n, by: everyCol) {
            let x = CGFloat(k) * step
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }
        for k in stride(from: everyRow, to: n, by: everyRow) {
            let y = CGFloat(k) * step
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }
        return path
    }
}

struct CellView: View {
    let state: CellState
    let size: CGFloat
    let gridSize: GridSize
    let symbols: SymbolSet
    let row: Int
    let col: Int

    var body: some View {
        ZStack {
            Rectangle().fill(background)

            if state.value != 0 {
                Text(symbols.display(state.value))
                    .font(Theme.font(size * (symbols.isNumbers ? 0.58 : 0.62), state.isGiven ? .heavy : .bold))
                    .foregroundStyle(textColor)
                    .opacity(!symbols.isNumbers && !state.isGiven && !state.isWrong ? 0.9 : 1)
                    .overlay(alignment: .bottomTrailing) {
                        // With pictures, a small dot marks squares the child filled in.
                        if !symbols.isNumbers && !state.isGiven {
                            Circle()
                                .fill(state.isWrong ? Theme.mistake : Theme.entry)
                                .frame(width: size * 0.14, height: size * 0.14)
                                .offset(x: size * 0.08, y: size * 0.04)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
            } else if !state.notes.isEmpty {
                NotesGrid(notes: state.notes, size: size, gridSize: gridSize, symbols: symbols)
            }

            if state.isHintTarget {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Theme.hintTarget, lineWidth: 3)
                    .padding(2)
            }
            if state.isWrong && !symbols.isNumbers {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Theme.mistake, lineWidth: 2.5)
                    .padding(3)
            }
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: state.value)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(.isButton)
    }

    private var background: Color {
        if state.isHintTarget { return Theme.hintTarget.opacity(0.55) }
        if state.isSelected { return Theme.selected }
        switch state.highlight {
        case .key: return Theme.keyCell
        case .hintFocus: return Theme.hintFocus
        case .sameNumber: return Theme.sameNumber
        case .related: return Theme.related
        case .none: return .clear
        }
    }

    private var textColor: Color {
        if state.isWrong { return Theme.mistake }
        return state.isGiven ? Theme.ink : Theme.entry
    }

    private var accessibilityText: String {
        let place = "Row \(row + 1), column \(col + 1)"
        if state.value == 0 { return "\(place), empty" }
        return "\(place), \(symbols.spoken(state.value))\(state.isWrong ? ", not correct" : "")"
    }
}

private struct NotesGrid: View {
    let notes: Set<Int>
    let size: CGFloat
    let gridSize: GridSize
    let symbols: SymbolSet

    var body: some View {
        // Notes use the same layout as the boxes: 2×2, 2×3 or 3×3.
        let rows = gridSize.boxRows
        let cols = gridSize.boxCols
        VStack(spacing: 0) {
            ForEach(0..<rows, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<cols, id: \.self) { c in
                        let digit = r * cols + c + 1
                        Text(notes.contains(digit) ? symbols.display(digit) : " ")
                            .font(Theme.font(size * (gridSize == .nine ? 0.22 : 0.24), .semibold))
                            .foregroundStyle(Theme.softInk)
                            .frame(width: size * 0.92 / CGFloat(cols), height: size * 0.92 / CGFloat(rows))
                            .minimumScaleFactor(0.5)
                    }
                }
            }
        }
    }
}
