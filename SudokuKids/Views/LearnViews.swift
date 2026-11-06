import SwiftUI

struct LearnHubView: View {
    @EnvironmentObject private var progress: ProgressStore

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(spacing: 4) {
                    Text("🦉 Learn")
                        .font(Theme.font(30, .heavy))
                        .foregroundStyle(Theme.ink)
                    Text("Learn a trick, then practise it with unlimited hints.")
                        .font(Theme.font(15, .medium))
                        .foregroundStyle(Theme.softInk)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 6)

                SectionTitle(text: "Lessons")
                ForEach(Technique.allCases) { technique in
                    NavigationLink(value: Route.lesson(technique)) {
                        LessonRow(
                            technique: technique,
                            learned: progress.stats.techniquesLearned.contains(technique.rawValue),
                            seen: progress.stats.techniquesSeen.contains(technique.rawValue)
                        )
                    }
                    .buttonStyle(BouncyButtonStyle())
                }

                SectionTitle(text: "Practice")
                Text("Unlimited hints, and numbers that can't fit fade out.")
                    .font(Theme.font(14, .medium))
                    .foregroundStyle(Theme.softInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 10) {
                    ForEach(GridSize.allCases) { size in
                        NavigationLink(value: Route.game(.learn(size: size))) {
                            VStack(spacing: 2) {
                                Text(size.emoji).font(.system(size: 30))
                                Text(size.label).font(Theme.font(18, .heavy)).foregroundStyle(Theme.ink)
                                Text(size.nickname).font(Theme.font(12, .semibold)).foregroundStyle(Theme.softInk)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .card(radius: 18)
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .kidsBackground()
        .navigationTitle("Learn")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LessonRow: View {
    let technique: Technique
    let learned: Bool
    let seen: Bool

    var body: some View {
        HStack(spacing: 14) {
            Text(technique.emoji)
                .font(.system(size: 32))
                .frame(width: 56, height: 56)
                .background(Difficulty.easy.color.opacity(0.18), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(technique.title).font(Theme.font(19, .heavy)).foregroundStyle(Theme.ink)
                Text(technique.levelNote).font(Theme.font(13, .semibold)).foregroundStyle(Theme.softInk)
            }
            Spacer(minLength: 0)
            if learned {
                Label("Learned", systemImage: "checkmark.seal.fill")
                    .font(Theme.font(13, .heavy))
                    .foregroundStyle(Difficulty.easy.color)
            } else if seen {
                Text("Seen in a hint")
                    .font(Theme.font(12, .bold))
                    .foregroundStyle(Theme.softInk)
            }
        }
        .padding(14)
        .card(radius: 20)
    }
}

struct LessonView: View {
    let technique: Technique
    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss
    @State private var example: LessonExample? = nil
    @State private var failed = false
    @State private var picked: Int? = nil
    @State private var newTrophies: [Trophy] = []

    init(technique: Technique) {
        self.technique = technique
    }

    private var solved: Bool { picked == example?.hint.value }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    Text(technique.emoji).font(.system(size: 40))
                    VStack(alignment: .leading, spacing: 6) {
                        Text(technique.title).font(Theme.font(24, .heavy)).foregroundStyle(Theme.ink)
                        Text(technique.summary).font(Theme.font(16, .medium)).foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Button {
                        Speaker.shared.say("\(technique.title). \(technique.summary)")
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Theme.entry)
                            .frame(width: 40, height: 40)
                            .card(radius: 20)
                    }
                    .accessibilityLabel("Read it to me")
                }
                .padding(16)
                .card()

                if let example {
                    let hint = example.hint
                    BoardView(size: .nine, cells: cells(for: example), symbols: .numbers)
                        .frame(maxWidth: 420)

                    Text("Here's a real puzzle. \(solved ? hint.message : "Which number goes in the glowing square?")")
                        .font(Theme.font(17, .bold))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 12) {
                        ForEach(example.choices, id: \.self) { choice in
                            let isPicked = picked == choice
                            let isRight = choice == hint.value
                            Button {
                                choose(choice)
                            } label: {
                                Text("\(choice)")
                                    .font(Theme.font(32, .heavy))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .foregroundStyle(isPicked ? .white : Theme.entry)
                                    .background(isPicked ? (isRight ? Difficulty.easy.color : Theme.mistake) : Theme.card,
                                                in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                            }
                            .buttonStyle(BouncyButtonStyle())
                            .disabled(solved)
                        }
                    }

                    if let picked, picked != hint.value {
                        Text("Not quite! Look at the highlighted squares and try again.")
                            .font(Theme.font(15, .semibold))
                            .foregroundStyle(Theme.mistake)
                            .multilineTextAlignment(.center)
                    }

                    if solved {
                        VStack(spacing: 10) {
                            Text("🎓 You learned \(technique.title)!")
                                .font(Theme.font(20, .heavy))
                                .foregroundStyle(Theme.ink)
                            ForEach(newTrophies) { trophy in
                                Text("\(trophy.emoji) New trophy: \(trophy.title)")
                                    .font(Theme.font(16, .bold))
                                    .foregroundStyle(Theme.ink)
                            }
                            BigButton(title: "Another example", color: Difficulty.easy.color) { load() }
                            SoftButton(title: "Back to lessons") { dismiss() }
                        }
                        .padding(16)
                        .card()
                    }
                } else if failed {
                    Text("Couldn't find an example this time. Tap to try again.")
                        .font(Theme.font(16, .semibold))
                        .foregroundStyle(Theme.softInk)
                    BigButton(title: "Try again", color: Theme.entry) { load() }
                } else {
                    ProgressView("Finding a good example…")
                        .font(Theme.font(16, .semibold))
                        .padding(.top, 30)
                }
            }
            .padding(20)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .kidsBackground()
        .navigationTitle("Lesson")
        .navigationBarTitleDisplayMode(.inline)
        .task { if example == nil { load() } }
        .onDisappear { Speaker.shared.stop() }
    }

    private func load() {
        example = nil
        failed = false
        picked = nil
        let technique = technique
        Task {
            let found = await Task.detached(priority: .userInitiated) {
                LessonBuilder.example(for: technique)
            }.value
            example = found
            failed = found == nil
        }
    }

    private func choose(_ choice: Int) {
        guard let example, !solved else { return }
        picked = choice
        if choice == example.hint.value {
            Feedback.win()
            newTrophies = progress.markLessonLearned(technique)
            if !newTrophies.isEmpty { Feedback.trophy() }
        } else {
            Feedback.oops()
        }
    }

    private func cells(for example: LessonExample) -> [CellState] {
        let hint = example.hint
        return (0..<81).map { i in
            var highlight = CellState.Highlight.none
            if hint.keyCells.contains(i) { highlight = .key } else if hint.focusCells.contains(i) { highlight = .hintFocus }
            let showAnswer = solved && i == hint.cell
            return CellState(
                value: showAnswer ? hint.value : example.values[i],
                notes: [],
                isGiven: example.values[i] != 0,
                isWrong: false,
                isSelected: false,
                isHintTarget: i == hint.cell,
                highlight: highlight
            )
        }
    }
}
