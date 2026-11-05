import SwiftUI

struct ControlsView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        HStack(spacing: 10) {
            ToolButton(icon: "arrow.uturn.backward", label: "Undo", color: Theme.softInk) {
                vm.undo()
            }
            ToolButton(icon: "eraser.fill", label: "Erase", color: Theme.mistake) {
                vm.erase()
            }
            ToolButton(
                icon: vm.notesMode ? "pencil.circle.fill" : "pencil",
                label: vm.notesMode ? "Notes ON" : "Notes",
                color: Difficulty.expert.color,
                isOn: vm.notesMode
            ) {
                vm.toggleNotes()
            }
            ToolButton(
                icon: "lightbulb.fill",
                label: "Hint",
                color: Theme.star,
                badge: vm.hintsLeft.map { "\($0)" }
            ) {
                vm.requestHint()
            }
            .disabled(!vm.canUseHint)
            .opacity(vm.canUseHint ? 1 : 0.4)
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
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                Text(label)
                    .font(Theme.font(13, .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(isOn ? .white : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
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
        HStack(spacing: 6) {
            ForEach(1...9, id: \.self) { digit in
                let left = vm.remaining(digit)
                let done = left == 0 && !vm.notesMode
                let dimmed = allowed.map { !$0.contains(digit) } ?? false
                Button {
                    vm.enter(digit)
                } label: {
                    VStack(spacing: 0) {
                        Text("\(digit)")
                            .font(Theme.font(30, .heavy))
                        Text(done ? "✓" : "\(left)")
                            .font(Theme.font(11, .bold))
                            .opacity(0.7)
                    }
                    .foregroundStyle(vm.notesMode ? Difficulty.expert.color : Theme.entry)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .black.opacity(0.06), radius: 3, y: 2)
                    .opacity(done ? 0.3 : (dimmed ? 0.35 : 1))
                }
                .buttonStyle(BouncyButtonStyle())
                .disabled(done)
                .accessibilityLabel("\(digit), \(left) left")
            }
        }
    }
}
