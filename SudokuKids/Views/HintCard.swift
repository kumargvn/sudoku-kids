import SwiftUI

struct HintCard: View {
    let hint: Hint
    let onSpeak: () -> Void
    let onApply: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(hint.isMistake ? "🙈" : (hint.technique?.emoji ?? "💡"))
                    .font(.system(size: 28))
                Text(hint.title)
                    .font(Theme.font(19, .heavy))
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 0)
                Button(action: onSpeak) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Theme.entry)
                        .frame(width: 38, height: 38)
                        .background(Theme.card, in: Circle())
                }
                .accessibilityLabel("Read it to me")
            }

            Text(hint.message)
                .font(Theme.font(16, .medium))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button(action: onDismiss) {
                    Text("I'll try!")
                        .font(Theme.font(16, .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(Theme.entry)
                        .background(Theme.entry.opacity(0.12), in: Capsule())
                }
                Button(action: onApply) {
                    Text(hint.isMistake ? "Erase it" : "Show me")
                        .font(Theme.font(16, .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(.white)
                        .background(Theme.entry, in: Capsule())
                }
            }
            .buttonStyle(BouncyButtonStyle())
        }
        .padding(16)
        .background(Theme.hintFocus, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.star, lineWidth: 2))
    }
}
