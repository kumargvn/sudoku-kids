import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var progress: ProgressStore
    @State private var path: [Route] = []
    @State private var showHowTo = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 18) {
                    header
                    statsRow

                    if let saved = progress.savedGame {
                        continueCard(saved)
                    }

                    ModeCard(
                        emoji: "🎮",
                        title: "Play",
                        subtitle: "Pick your level: Easy to Expert",
                        color: Difficulty.medium.color
                    ) { path.append(.levels) }

                    ModeCard(
                        emoji: progress.isDailyDone() ? "✅" : "📅",
                        title: "Daily Challenge",
                        subtitle: dailySubtitle,
                        color: Difficulty.hard.color
                    ) { openDaily() }

                    ModeCard(
                        emoji: "🦉",
                        title: "Learn to Play",
                        subtitle: "Unlimited hints that explain every step",
                        color: Difficulty.easy.color
                    ) { path.append(.game(.learn())) }

                    Button {
                        showHowTo = true
                    } label: {
                        Label("How to play", systemImage: "questionmark.circle.fill")
                            .font(Theme.font(17, .semibold))
                            .foregroundStyle(Theme.ink)
                            .padding(.vertical, 10)
                    }
                }
                .padding(20)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationDestination(for: Route.self) { route in
                destination(for: route)
            }
            .sheet(isPresented: $showHowTo) {
                HowToPlayView()
            }
        }
    }

    // MARK: Pieces

    private var header: some View {
        VStack(spacing: 6) {
            Text("🦉")
                .font(.system(size: 72))
                .padding(.top, 12)
            Text("Sudoku Kids")
                .font(Theme.font(40, .heavy))
                .foregroundStyle(Theme.ink)
            Text("Train your brain, one number at a time!")
                .font(Theme.font(16, .medium))
                .foregroundStyle(Theme.softInk)
                .multilineTextAlignment(.center)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatBubble(emoji: "⭐", value: "\(progress.stats.totalStars)", label: "Stars")
            StatBubble(emoji: "🏆", value: "\(progress.stats.totalWins)", label: "Solved")
            StatBubble(emoji: "🔥", value: "\(progress.dailyStreak())", label: "Day streak")
        }
    }

    private func continueCard(_ saved: SavedGame) -> some View {
        Button {
            path.append(.resume(saved.config))
        } label: {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 34))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Continue")
                        .font(Theme.font(20, .heavy))
                    Text("\(saved.config.title) · \(formatTime(saved.elapsed))")
                        .font(Theme.font(15, .medium))
                        .opacity(0.9)
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(.white)
            .padding(18)
            .background(Theme.entry, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Theme.entry.opacity(0.35), radius: 8, y: 4)
        }
        .buttonStyle(BouncyButtonStyle())
    }

    private var dailySubtitle: String {
        progress.isDailyDone()
            ? "Done for today! Come back tomorrow"
            : "A new puzzle every day"
    }

    private func openDaily() {
        let config = GameConfig.daily()
        if progress.savedGame?.config == config {
            path.append(.resume(config))
        } else {
            path.append(.game(config))
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .levels:
            LevelPickerView()
        case .game(let config):
            GameView(config: config, resume: nil, store: progress)
        case .resume(let config):
            // The saved game is only read the first time this screen is built.
            GameView(
                config: config,
                resume: progress.savedGame?.config == config ? progress.savedGame : nil,
                store: progress
            )
        }
    }
}

struct StatBubble: View {
    let emoji: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(emoji).font(.system(size: 24))
            Text(value)
                .font(Theme.font(22, .heavy))
                .foregroundStyle(Theme.ink)
            Text(label)
                .font(Theme.font(12, .medium))
                .foregroundStyle(Theme.softInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
    }
}

struct ModeCard: View {
    let emoji: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(emoji)
                    .font(.system(size: 40))
                    .frame(width: 64, height: 64)
                    .background(color.opacity(0.18), in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Theme.font(22, .heavy))
                        .foregroundStyle(Theme.ink)
                    Text(subtitle)
                        .font(Theme.font(15, .medium))
                        .foregroundStyle(Theme.softInk)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(color)
            }
            .padding(16)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(color.opacity(0.5), lineWidth: 2)
            )
            .shadow(color: color.opacity(0.2), radius: 8, y: 4)
        }
        .buttonStyle(BouncyButtonStyle())
    }
}
