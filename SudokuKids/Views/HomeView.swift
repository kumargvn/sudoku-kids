import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var progress: ProgressStore
    @State private var path: [Route] = []
    @State private var showHowTo = false
    @State private var showSettings = false
    @State private var showProfiles = false
    @State private var showGate = false
    @State private var gatePassed = false
    @State private var showParents = false
    @State private var appliedInitialPath = false
    private let initialPath: [Route]

    init(initialPath: [Route] = []) {
        self.initialPath = initialPath
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 16) {
                    topBar
                    header
                    statsRow

                    if let saved = progress.savedGame {
                        continueCard(saved)
                    }

                    ModeCard(emoji: "🗺️", title: "Adventure", subtitle: adventureSubtitle, color: AdventureWorldColor.forest) {
                        path.append(.adventure)
                    }
                    ModeCard(emoji: "🎮", title: "Play", subtitle: "Pick a size and level: 4×4 to 9×9", color: Difficulty.medium.color) {
                        path.append(.levels)
                    }
                    ModeCard(emoji: progress.isDailyDone() ? "✅" : "📅", title: "Daily Challenge",
                             subtitle: progress.isDailyDone() ? "Done for today! Come back tomorrow" : "A new 9×9 puzzle every day",
                             color: Difficulty.hard.color) {
                        openDaily()
                    }
                    ModeCard(emoji: "🦉", title: "Learn", subtitle: "Lessons and practice with unlimited hints", color: Difficulty.easy.color) {
                        path.append(.learn)
                    }

                    HStack(spacing: 12) {
                        SmallTile(emoji: "🏆", title: "Trophies", detail: "\(progress.stats.trophies.count)/\(Trophies.all.count)") {
                            path.append(.trophies)
                        }
                        SmallTile(emoji: "❓", title: "How to play", detail: "The rules") {
                            showHowTo = true
                        }
                    }

                    Button {
                        showGate = true
                    } label: {
                        Label("Grown-ups", systemImage: "lock.fill")
                            .font(Theme.font(15, .semibold))
                            .foregroundStyle(Theme.softInk)
                            .padding(.vertical, 8)
                    }
                }
                .padding(20)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .kidsBackground()
            .navigationDestination(for: Route.self) { route in
                destination(for: route)
            }
            .sheet(isPresented: $showHowTo) { HowToPlayView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showProfiles) { ProfilesView() }
            .sheet(isPresented: $showGate, onDismiss: {
                if gatePassed {
                    gatePassed = false
                    showParents = true
                }
            }) {
                ParentGateView { gatePassed = true }
            }
            .sheet(isPresented: $showParents) { ParentAreaView() }
        }
        .onAppear {
            if !appliedInitialPath {
                appliedInitialPath = true
                path = initialPath
            }
        }
    }

    // MARK: Pieces

    private var topBar: some View {
        HStack {
            Button {
                showProfiles = true
            } label: {
                HStack(spacing: 8) {
                    Text(progress.profile.avatar).font(.system(size: 26))
                    Text(progress.profile.name)
                        .font(Theme.font(17, .heavy))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.softInk)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .card(radius: 20)
            }
            .buttonStyle(BouncyButtonStyle())
            .accessibilityLabel("Player: \(progress.profile.name). Change player")

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 44, height: 44)
                    .card(radius: 22)
            }
            .buttonStyle(BouncyButtonStyle())
            .accessibilityLabel("Settings")
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .shadow(color: Theme.ink.opacity(0.25), radius: 10, y: 6)
                .accessibilityHidden(true)
            Text("Sudoku Kids")
                .font(Theme.font(38, .heavy))
                .foregroundStyle(Theme.ink)
            Text("Train your brain, one square at a time!")
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

    private var adventureSubtitle: String {
        let done = progress.completedLevels.count
        return done == 0 ? "Travel through 5 worlds of puzzles" : "\(done) of \(Adventure.allLevels.count) levels done"
    }

    private func continueCard(_ saved: SavedGame) -> some View {
        Button {
            path.append(.resume(saved.config))
        } label: {
            HStack {
                Image(systemName: "play.circle.fill").font(.system(size: 34))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Continue").font(Theme.font(20, .heavy))
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
        .accessibilityIdentifier("continueCard")
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
            GameView(config: config, resume: progress.savedGame?.config == config ? progress.savedGame : nil, store: progress)
        case .adventure:
            AdventureView()
        case .learn:
            LearnHubView()
        case .lesson(let technique):
            LessonView(technique: technique)
        case .trophies:
            TrophiesView()
        }
    }
}

enum AdventureWorldColor {
    static let forest = Color(red: 0.30, green: 0.72, blue: 0.42)
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
                .monospacedDigit()
            Text(label)
                .font(Theme.font(12, .medium))
                .foregroundStyle(Theme.softInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .card(radius: 18)
        .accessibilityElement(children: .combine)
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
                    .font(.system(size: 38))
                    .frame(width: 62, height: 62)
                    .background(color.opacity(0.18), in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Theme.font(21, .heavy))
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
            .padding(14)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(color.opacity(0.5), lineWidth: 2))
            .shadow(color: color.opacity(0.2), radius: 8, y: 4)
        }
        .buttonStyle(BouncyButtonStyle())
    }
}

struct SmallTile: View {
    let emoji: String
    let title: String
    let detail: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(emoji).font(.system(size: 28))
                VStack(alignment: .leading, spacing: 0) {
                    Text(title).font(Theme.font(16, .heavy)).foregroundStyle(Theme.ink)
                    Text(detail).font(Theme.font(13, .semibold)).foregroundStyle(Theme.softInk)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .card(radius: 20)
        }
        .buttonStyle(BouncyButtonStyle())
    }
}
