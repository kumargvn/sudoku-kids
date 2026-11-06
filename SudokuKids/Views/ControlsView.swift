import SwiftUI

struct ControlsView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        HStack(spacing: 8) {
            ToolButton(icon: "arrow.uturn.backward", label: "Undo", color: Theme.softInk) { vm.undo() }
            ToolButton(icon: "eraser.fill", label: "Erase", color: Theme.mistake) { vm.erase() }
            ToolButton(
                icon: vm.notesMode ? "pencil.circle.fill" : "pencil",
                label: vm.notesMode ? "Notes ON" : "Notes",
                color: Difficulty.expert.color,
                isOn: vm.notesMode
            ) { vm.toggleNotes() }
            ToolButton(icon: "wand.and.stars", label: "Auto", color: Difficulty.easy.color) { vm.autoNotes() }
                .accessibilityLabel("Fill in all notes")
            ToolButton(icon: "lightbulb.fill", label: "Hint", color: Theme.star, badge: vm.hintsLeft.map { "\($0)" }) {
                vm.requestHint()
            }
            .disabled(!vm.canUseHint)
            .opacity(vm.canUseHint ? 1 : 0.4)
            .accessibilityIdentifier("tool_hint")
        }
    }
}

private struct ToolButton: View {
    let icon: String
    let label: String
    let color: Color
    var isOn = false
    var badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 21, weight: .bold))
                Text(label)
                    .font(Theme.font(12, .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(isOn ? .white : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(isOn ? color : Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            .overlay(alignment: .topTrailing) {
                if let badge {
                    Text(badge)
                        .font(Theme.font(12, .heavy))
                        .foregroundStyle(.white)
                        .frame(minWidth: 20, minHeight: 20)
                        .background(Theme.mistake, in: Circle())
                        .offset(x: 4, y: -6)
                }
            }
        }
        .buttonStyle(BouncyButtonStyle())
    }
}

struct NumberPadView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        let allowed = vm.showsCandidateHelp ? vm.allowedForSelection : nil
        let n = vm.size.n
        HStack(spacing: n == 9 ? 6 : 10) {
            ForEach(1...n, id: \.self) { digit in
                let left = vm.remaining(digit)
                let done = left == 0 && !vm.notesMode
                let dimmed = allowed.map { !$0.contains(digit) } ?? false
                Button {
                    vm.enter(digit)
                } label: {
                    VStack(spacing: 0) {
                        Text(vm.symbols.display(digit))
                            .font(Theme.font(vm.symbols.isNumbers ? (n == 9 ? 30 : 34) : (n == 9 ? 26 : 32), .heavy))
                            .minimumScaleFactor(0.6)
                        Text(done ? "✓" : "\(left)")
                            .font(Theme.font(11, .bold))
                            .opacity(0.7)
                    }
                    .foregroundStyle(vm.notesMode ? Difficulty.expert.color : Theme.entry)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, n == 9 ? 8 : 12)
                    .background(vm.notesMode ? Difficulty.expert.color.opacity(0.08) : Theme.card,
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .black.opacity(0.06), radius: 3, y: 2)
                    .opacity(done ? 0.3 : (dimmed ? 0.35 : 1))
                }
                .buttonStyle(BouncyButtonStyle())
                .disabled(done)
                .accessibilityLabel("\(vm.symbols.spoken(digit)), \(left) left")
                .accessibilityIdentifier("numpad_\(digit)")
            }
        }
    }
}
