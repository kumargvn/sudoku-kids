import SwiftUI

@main
struct SudokuKidsApp: App {
    @StateObject private var progress = ProgressStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(progress)
                .preferredColorScheme(.light)
                .tint(Theme.entry)
        }
    }
}

enum Route: Hashable {
    case levels
    case game(GameConfig)
    /// Continue the saved game that has this config.
    case resume(GameConfig)
}
