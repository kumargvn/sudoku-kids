import SwiftUI

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss

    private struct Rule: Identifiable {
        let emoji: String
        let title: String
        let text: String
        var id: String { title }
    }

    private struct Tip: Identifiable {
        let emoji: String
        let text: String
        var id: String { text }
    }

    private let rules = [
        Rule(emoji: "➡️", title: "Rows", text: "Each row going across needs the numbers 1 to 9. No repeats!"),
        Rule(emoji: "⬇️", title: "Columns", text: "Each column going down needs 1 to 9 too. No repeats!"),
        Rule(emoji: "🟦", title: "Boxes", text: "Each 3×3 box with a thick border needs 1 to 9. No repeats!"),
    ]

    private let tips = [
        Tip(emoji: "👆", text: "Tap a square, then tap a number to fill it in."),
        Tip(emoji: "✏️", text: "Not sure yet? Turn on Notes to jot down tiny guesses."),
        Tip(emoji: "💡", text: "Stuck? Tap Hint. It shows you HOW to find the answer, not just what it is."),
        Tip(emoji: "🔎", text: "Look for a box, row or column that is almost full. That's the easiest place to start!"),
        Tip(emoji: "⭐", text: "Finish with no hints and few mistakes to earn 3 stars."),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("The 3 golden rules")
                        .font(Theme.font(24, .heavy))
                        .foregroundStyle(Theme.ink)

                    ForEach(rules) { rule in
                        HStack(alignment: .top, spacing: 14) {
                            Text(rule.emoji).font(.system(size: 32))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(rule.title).font(Theme.font(19, .heavy))
                                Text(rule.text).font(Theme.font(16, .medium))
                            }
                            .foregroundStyle(Theme.ink)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }

                    Text("Tips")
                        .font(Theme.font(24, .heavy))
                        .foregroundStyle(Theme.ink)
                        .padding(.top, 6)

                    ForEach(tips) { tip in
                        HStack(alignment: .top, spacing: 12) {
                            Text(tip.emoji).font(.system(size: 24))
                            Text(tip.text)
                                .font(Theme.font(16, .medium))
                                .foregroundStyle(Theme.ink)
                        }
                    }
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("How to play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Let's go!") { dismiss() }
                        .font(Theme.font(17, .bold))
                }
            }
        }
    }
}
