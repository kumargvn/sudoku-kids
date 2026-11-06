import SwiftUI

struct GameView: View {
    @StateObject private var vm: GameViewModel
    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var showTutorial = false
    @State private var showBreak = false

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
                VStack(spacing: 12) {
                    StatusBar(vm: vm)
                    Spacer(minLength: 0)
                    BoardView(size: vm.size, cells: (0..<vm.geo.count).map { vm.cellState($0) }, symbols: vm.symbols) { index in
                        vm.select(index)
                    }
                    Spacer(minLength: 0)
                    // Fixed-height area: the hint card swaps in for the tools and number pad,
                    // so the board never moves or resizes when a hint opens.
                    VStack(spacing: 12) {
                        if let hint = vm.activeHint {
                            HintCard(
                                hint: hint,
                                onSpeak: { vm.speakHint() },
                                onApply: { vm.applyHint() },
                                onDismiss: { vm.dismissHint() }
                            )
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        } else {
                            ControlsView(vm: vm)
                            NumberPadView(vm: vm)
                        }
                    }
                    .frame(minHeight: 190, alignment: .bottom)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
                .frame(maxWidth: 620)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.activeHint)
            }

            if let toast = vm.toast {
                ToastView(text: toast)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task(id: toast) {
                        try? await Task.sleep(nanoseconds: 2_200_000_000)
                        if vm.toast == toast { vm.toast = nil }
                    }
            }

            if vm.isComplete {
                WinView(
                    config: vm.config,
                    stars: vm.stars,
                    seconds: vm.elapsed,
                    mistakes: vm.mistakes,
                    hintsUsed: vm.hintsUsed,
                    newTrophies: vm.newTrophies,
                    primary: primaryWinAction,
                    onHome: { dismiss() }
                )
                .transition(.opacity)
            }

            if vm.isGameOver {
                GameOverView(onRetry: { vm.retry() }, onNew: { vm.newGame() }, onHome: { dismiss() })
                    .transition(.opacity)
            }

            if showBreak {
                BreakView {
                    progress.acknowledgeBreak()
                    showBreak = false
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: vm.isComplete)
        .animation(.easeInOut, value: vm.isGameOver)
        .animation(.easeInOut, value: vm.toast)
        .animation(.easeInOut, value: showBreak)
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
            guard scenePhase == .active, !showTutorial, !showBreak else { return }
            vm.tick()
            if vm.isPlaying && progress.isBreakDue { showBreak = true }
        }
        .onAppear {
            if vm.config.mode == .learn && !progress.stats.hasSeenTutorial {
                showTutorial = true
                progress.markTutorialSeen()
            }
        }
        .onDisappear {
            Speaker.shared.stop()
            progress.flushPlayTime()
        }
        .sheet(isPresented: $showTutorial) {
            HowToPlayView()
        }
    }

    /// The big button on the win screen.
    private var primaryWinAction: WinView.Action? {
        let model = vm
        switch vm.config.mode {
        case .daily:
            return nil
        case .adventure:
            guard let next = vm.nextAdventureLevel else { return nil }
            return WinView.Action(title: "Next level ▶︎") { model.start(.adventure(next)) }
        case .classic, .learn:
            return WinView.Action(title: "New puzzle") { model.newGame() }
        }
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
            if let tries = vm.triesLeft, let limit = vm.strikeLimit {
                HStack(spacing: 3) {
                    ForEach(0..<limit, id: \.self) { k in
                        Image(systemName: k < tries ? "heart.fill" : "heart")
                            .foregroundStyle(Theme.mistake)
                    }
                }
                .font(.system(size: 17, weight: .bold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Theme.card, in: Capsule())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(tries) tries left")
            } else {
                Pill(icon: "xmark.circle.fill", text: vm.showMistakes ? "\(vm.mistakes)" : "–", color: Theme.mistake)
                    .accessibilityLabel(vm.showMistakes ? "\(vm.mistakes) mistakes" : "Mistakes hidden")
            }
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

struct ToastView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Theme.font(16, .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Theme.ink.opacity(0.92), in: Capsule())
            .shadow(radius: 8)
    }
}

private struct GameOverView: View {
    let onRetry: () -> Void
    let onNew: () -> Void
    let onHome: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 14) {
                Text("💔").font(.system(size: 60))
                Text("Out of tries!")
                    .font(Theme.font(30, .heavy))
                    .foregroundStyle(Theme.ink)
                Text("That was 3 mistakes. Every mistake teaches your brain something. Want another go?")
                    .font(Theme.font(16, .medium))
                    .foregroundStyle(Theme.softInk)
                    .multilineTextAlignment(.center)
                VStack(spacing: 10) {
                    BigButton(title: "Try this puzzle again", color: Theme.entry, action: onRetry)
                    BigButton(title: "New puzzle", color: Difficulty.easy.color, action: onNew)
                    SoftButton(title: "Home", action: onHome)
                }
            }
            .padding(24)
            .frame(maxWidth: 380)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .padding(24)
        }
    }
}

private struct BreakView: View {
    let onOK: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 14) {
                Text("🧘").font(.system(size: 60))
                Text("Time for a break!")
                    .font(Theme.font(28, .heavy))
                    .foregroundStyle(Theme.ink)
                Text("You've been puzzling for a while. Stretch, get some water, and rest your eyes. Your game is saved.")
                    .font(Theme.font(16, .medium))
                    .foregroundStyle(Theme.softInk)
                    .multilineTextAlignment(.center)
                BigButton(title: "OK!", color: Difficulty.easy.color, action: onOK)
            }
            .padding(24)
            .frame(maxWidth: 380)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .padding(24)
        }
    }
}

struct BigButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.font(19, .heavy))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(.white)
                .background(color, in: Capsule())
        }
        .buttonStyle(BouncyButtonStyle())
    }
}

struct SoftButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.font(17, .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(Theme.entry)
                .background(Theme.entry.opacity(0.12), in: Capsule())
        }
        .buttonStyle(BouncyButtonStyle())
    }
}
