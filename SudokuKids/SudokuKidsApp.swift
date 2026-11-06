import SwiftUI

@main
struct SudokuKidsApp: App {
    @StateObject private var progress: ProgressStore
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Screenshot mode uses its own sample data; normal launches use the real store.
        if let demo = DemoMode.current {
            _progress = StateObject(wrappedValue: demo.makeStore())
        } else {
            _progress = StateObject(wrappedValue: ProgressStore())
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView(initialPath: DemoMode.current?.initialPath ?? [])
                .environmentObject(progress)
                .preferredColorScheme(.light)
                .tint(Theme.entry)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { progress.flushPlayTime() }
        }
    }
}

enum Route: Hashable {
    case levels
    case game(GameConfig)
    /// Continue the saved game that has this config.
    case resume(GameConfig)
    case adventure
    case learn
    case lesson(Technique)
    case trophies
}
