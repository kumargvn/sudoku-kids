import SwiftUI

struct GameView: View {
    @StateObject private var vm: GameViewModel
    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var showTutorial = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(config: GameConfig, resume: SavedGame?, store: ProgressStore) {
        _vm = StateObject(wrappedValue: GameViewModel(config: config, resume: resume, store: store))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if vm.isLoading {
                LoadingView()
            } else {
                VStack(spacing: 14) {
                    StatusBar(vm: vm)
                    BoardView(vm: vm)
                    Spacer(minLength: 0)
                    if let hint = vm.activeHint {
                        HintCard(
                            hint: hint,
                            onApply: { vm.applyHint() },
                            onDismiss: { vm.dismissHint() }
                        )
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        ControlsView(vm: vm)
                    }
                    NumberPadView(vm: vm)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
                .frame(maxWidth: 620)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.activeHint)
            }

            if vm.isComplete {
                WinView(
                    config: vm.config,
                    stars: vm.stars,
                    seconds: vm.elapsed,
                    mistakes: vm.mistakes,
                    hintsUsed: vm.hintsUsed,
                    onNewPuzzle: newPuzzleAction,
                    onHome: { dismiss() }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: vm.isComplete)
        .navigationTitle(vm.config.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showTutorial = true
                } label: {
                    Image(systemName: "questionmark.circle")
                }
                .accessibilityLabel("How to play")
            }
        }
        .onReceive(timer) { _ in
            if scenePhase == .active && !showTutorial { vm.tick() }
        }
        .onAppear {
            if vm.config.mode == .learn && !progress.stats.hasSeenTutorial {
                showTutorial = true
                progress.markTutorialSeen()
            }
        }
        .sheet(isPresented: $showTutorial) {
            HowToPlayView()
        }
    }

    /// The Daily Challenge has one puzzle per day, so there is no "new puzzle" button for it.
    private var newPuzzleAction: (() -> Void)? {
        if vm.config.mode == .daily { return nil }
        let model = vm
        return { model.newGame() }
    }
}

private struct LoadingView: View {
    @State private var spin = false

    var body: some View {
        VStack(spacing: 16) {
            Text("🧩")
                .font(.system(size: 64))
                .rotationEffect(.degrees(spin ? 360 : 0))
                .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: spin)
            Text("Making your puzzle…")
                .font(Theme.font(20, .semibold))
                .foregroundStyle(Theme.ink)
        }
        .onAppear { spin = true }
    }
}

private struct StatusBar: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        HStack {
            Pill(icon: "stopwatch.fill", text: formatTime(vm.elapsed), color: Theme.entry)
            Spacer()
            Pill(icon: "xmark.circle.fill", text: "\(vm.mistakes)", color: Theme.mistake)
                .accessibilityLabel("\(vm.mistakes) mistakes")
            Spacer()
            Pill(icon: "lightbulb.fill", text: vm.hintsLeft.map { "\($0)" } ?? "∞", color: Theme.star)
                .accessibilityLabel(vm.hintsLeft.map { "\($0) hints left" } ?? "Unlimited hints")
        }
        .padding(.top, 6)
    }
}

private struct Pill: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(color)
            Text(text)
                .font(Theme.font(17, .bold))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Theme.card, in: Capsule())
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}
