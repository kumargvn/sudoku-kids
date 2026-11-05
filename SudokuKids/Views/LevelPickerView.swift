import SwiftUI

struct LevelPickerView: View {
    @EnvironmentObject private var progress: ProgressStore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Choose your level")
                    .font(Theme.font(28, .heavy))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 8)

                ForEach(Difficulty.allCases) { level in
                    NavigationLink(value: Route.game(.classic(level))) {
                        LevelRow(
                            level: level,
                            wins: progress.wins(for: level),
                            bestTime: progress.bestTime(for: level)
                        )
                    }
                    .buttonStyle(BouncyButtonStyle())
                }
            }
            .padding(20)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Levels")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LevelRow: View {
    let level: Difficulty
    let wins: Int
    let bestTime: Int?

    var body: some View {
        HStack(spacing: 16) {
            Text(level.emoji)
                .font(.system(size: 42))
                .frame(width: 70, height: 70)
                .background(.white.opacity(0.3), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(level.title)
                    .font(Theme.font(26, .heavy))
                Text(level.tagline)
                    .font(Theme.font(15, .medium))
                    .opacity(0.95)
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
            Image(systemName: "play.fill")
                .font(.system(size: 22))
        }
        .foregroundStyle(.white)
        .padding(18)
        .background(level.color.gradient, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: level.color.opacity(0.35), radius: 8, y: 4)
    }
}
