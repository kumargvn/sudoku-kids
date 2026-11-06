import SwiftUI

struct LevelPickerView: View {
    @EnvironmentObject private var progress: ProgressStore

    private var size: GridSize { progress.prefs.classicSize }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Choose your puzzle")
                    .font(Theme.font(28, .heavy))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 8)

                SizePicker(selection: size) { newSize in
                    progress.updatePrefs { $0.classicSize = newSize }
                }

                ForEach(Difficulty.allCases) { level in
                    NavigationLink(value: Route.game(.classic(level, size: size))) {
                        LevelRow(
                            level: level,
                            wins: progress.stats.winCount(size: size, difficulty: level),
                            bestTime: progress.stats.bestTimes[PlayerStats.key(size, level)]
                        )
                    }
                    .buttonStyle(BouncyButtonStyle())
                }

                if progress.prefs.threeStrikes {
                    Label("3-mistake challenge is on", systemImage: "heart.fill")
                        .font(Theme.font(15, .semibold))
                        .foregroundStyle(Theme.mistake)
                }
            }
            .padding(20)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .kidsBackground()
        .navigationTitle("Play")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SizePicker: View {
    let selection: GridSize
    let onSelect: (GridSize) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(GridSize.allCases) { size in
                let isOn = size == selection
                Button {
                    Feedback.tap()
                    onSelect(size)
                } label: {
                    VStack(spacing: 2) {
                        Text(size.emoji).font(.system(size: 26))
                        Text(size.label).font(Theme.font(18, .heavy))
                        Text(size.nickname).font(Theme.font(12, .semibold)).opacity(0.8)
                    }
                    .foregroundStyle(isOn ? .white : Theme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isOn ? Theme.entry : Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
    }
}

private struct LevelRow: View {
    let level: Difficulty
    let wins: Int
    let bestTime: Int?

    var body: some View {
        HStack(spacing: 16) {
            Text(level.emoji)
                .font(.system(size: 40))
                .frame(width: 66, height: 66)
                .background(.white.opacity(0.3), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(level.title).font(Theme.font(25, .heavy))
                Text(level.tagline).font(Theme.font(15, .medium)).opacity(0.95)
                HStack(spacing: 12) {
                    Label("\(wins) solved", systemImage: "trophy.fill")
                    if let bestTime {
                        Label(formatTime(bestTime), systemImage: "stopwatch.fill")
                    }
                }
                .font(Theme.font(13, .semibold))
                .opacity(0.9)
            }
            Spacer(minLength: 0)
            Image(systemName: "play.fill").font(.system(size: 22))
        }
        .foregroundStyle(.white)
        .padding(16)
        .background(level.color.gradient, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: level.color.opacity(0.35), radius: 8, y: 4)
    }
}
