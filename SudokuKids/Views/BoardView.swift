import SwiftUI

struct BoardView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cellSize = side / 9

            ZStack {
                VStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { r in
                        HStack(spacing: 0) {
                            ForEach(0..<9, id: \.self) { c in
                                let index = r * 9 + c
                                CellView(state: vm.cellState(index), size: cellSize, row: r, col: c)
                                    .onTapGesture { vm.select(index) }
                            }
                        }
                    }
                }

                GridLines(every: 1)
                    .stroke(Theme.ink.opacity(0.18), lineWidth: 1)
                    .allowsHitTesting(false)
                GridLines(every: 3)
                    .stroke(Theme.ink, lineWidth: 2.5)
                    .allowsHitTesting(false)
            }
            .frame(width: side, height: side)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Theme.ink, lineWidth: 3)
            )
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// Internal grid lines: every cell, or every third cell for the 3×3 boxes.
struct GridLines: Shape {
    let every: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step = rect.width / 9
        for k in stride(from: every, to: 9, by: every) {
            let offset = CGFloat(k) * step
            path.move(to: CGPoint(x: offset, y: 0))
            path.addLine(to: CGPoint(x: offset, y: rect.height))
            path.move(to: CGPoint(x: 0, y: offset))
            path.addLine(to: CGPoint(x: rect.width, y: offset))
        }
        return path
    }
}

struct CellView: View {
    let state: CellState
    let size: CGFloat
    let row: Int
    let col: Int

    var body: some View {
        ZStack {
            Rectangle().fill(background)

            if state.value != 0 {
                Text("\(state.value)")
                    .font(Theme.font(size * 0.58, state.isGiven ? .heavy : .bold))
                    .foregroundStyle(textColor)
                    .transition(.scale.combined(with: .opacity))
            } else if !state.notes.isEmpty {
                NotesGrid(notes: state.notes, size: size)
            }

            if state.isHintTarget {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Theme.hintTarget, lineWidth: 3)
                    .padding(2)
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
        return "\(place), \(state.value)\(state.isWrong ? ", not correct" : "")"
    }
}

private struct NotesGrid: View {
    let notes: Set<Int>
    let size: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(1...3, id: \.self) { c in
                        let digit = r * 3 + c
                        Text(notes.contains(digit) ? "\(digit)" : " ")
                            .font(Theme.font(size * 0.22, .semibold))
                            .foregroundStyle(Theme.softInk)
                            .frame(width: size / 3.2, height: size / 3.2)
                    }
                }
            }
        }
    }
}
