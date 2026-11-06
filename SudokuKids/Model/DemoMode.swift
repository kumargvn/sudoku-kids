import Foundation

/// Sample screens for App Store screenshots. Only active when the app is launched
/// with `-screenshot <name>`, which the screenshot workflow does in the simulator.
/// Normal launches never touch this, and it uses its own throwaway storage.
enum DemoMode: String {
    case home, game, hint, kids, adventure, learn

    static let current: DemoMode? = {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-screenshot"), i + 1 < args.count else { return nil }
        return DemoMode(rawValue: args[i + 1])
    }()

    static let gameConfig = GameConfig(mode: .classic, size: .nine, difficulty: .medium, seed: 20_261_106, dayKey: nil, levelID: nil)

    /// The screen to open on launch.
    var initialPath: [Route] {
        switch self {
        case .home: return []
        case .game, .hint: return [.resume(Self.gameConfig)]
        case .kids: return [.resume(.adventure(Adventure.allLevels[2]))]
        case .adventure: return [.adventure]
        case .learn: return [.lesson(.onlySpot)]
        }
    }

    @MainActor
    func makeStore() -> ProgressStore {
        let name = "sudokukids.demo"
        UserDefaults().removePersistentDomain(forName: name)
        let store = ProgressStore(defaults: UserDefaults(suiteName: name) ?? .standard)
        store.settings.sound = false
        store.rename(store.activeID, to: "Maya", avatar: "🦊")

        // A believable history: a few days of puzzles, some adventure levels, two lessons.
        for back in 0..<4 {
            let day = Calendar.current.date(byAdding: .day, value: -back, to: Date()) ?? Date()
            _ = store.recordWin(config: .daily(on: day), seconds: 420, stars: 3, mistakes: 0, hintsUsed: 0)
        }
        for (index, level) in Adventure.allLevels.prefix(8).enumerated() {
            _ = store.recordWin(config: .adventure(level), seconds: 120, stars: index % 3 == 2 ? 2 : 3, mistakes: 1, hintsUsed: 0)
        }
        for size in GridSize.allCases {
            _ = store.recordWin(config: .classic(.easy, size: size), seconds: 200, stars: 3, mistakes: 0, hintsUsed: 1)
        }
        _ = store.markLessonLearned(.lastNumber)
        _ = store.markLessonLearned(.onlySpot)

        switch self {
        case .game, .hint:
            store.save(Self.partlySolved(Self.gameConfig, symbols: .numbers, filled: 16, notes: 5))
        case .kids:
            let level = Adventure.allLevels[2]
            store.save(Self.partlySolved(.adventure(level), symbols: .animals, filled: 3, notes: 0))
        default:
            break
        }
        return store
    }

    private static func partlySolved(_ config: GameConfig, symbols: SymbolSet, filled: Int, notes: Int) -> SavedGame {
        let puzzle = PuzzleGenerator.generate(size: config.size, difficulty: config.difficulty, seed: config.seed)
        let geo = config.size.geometry
        var values = puzzle.givens
        let empty = (0..<geo.count).filter { values[$0] == 0 }
        for i in empty.prefix(filled) { values[i] = puzzle.solution[i] }
        var noteSets = [Set<Int>](repeating: [], count: geo.count)
        for i in empty.dropFirst(filled).prefix(notes) {
            noteSets[i] = Set(geo.digits(in: geo.candidateMask(values, i)))
        }
        return SavedGame(config: config, puzzle: puzzle, values: values, notes: noteSets,
                         mistakes: 0, hintsUsed: 0, elapsed: 154)
    }
}
