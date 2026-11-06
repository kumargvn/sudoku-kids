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
        Rule(emoji: "➡️", title: "Rows", text: "Each row going across needs every number once. No repeats!"),
        Rule(emoji: "⬇️", title: "Columns", text: "Each column going down needs every number once too."),
        Rule(emoji: "🟦", title: "Boxes", text: "Each box with a thick border needs every number once."),
    ]

    private let tips = [
        Tip(emoji: "🐣", text: "New to Sudoku? Start with a tiny 4×4 puzzle. It uses just 1 to 4."),
        Tip(emoji: "🐶", text: "Like pictures better? Pick animals, fruit or colours in Settings."),
        Tip(emoji: "👆", text: "Tap a square, then tap a number to fill it in."),
        Tip(emoji: "✏️", text: "Not sure yet? Turn on Notes to jot down tiny guesses, or tap Auto to fill them all in."),
        Tip(emoji: "💡", text: "Stuck? Tap Hint. It shows you HOW to find the answer, and can read it out loud."),
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
                        .card(radius: 18)
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
            .kidsBackground()
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
