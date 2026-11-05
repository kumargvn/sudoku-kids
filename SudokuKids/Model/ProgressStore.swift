import Foundation

/// A game in progress, saved so kids can pick up where they left off.
struct SavedGame: Codable, Equatable {
    var config: GameConfig
    var puzzle: Puzzle
    var values: [Int]
    var notes: [Set<Int>]
    var mistakes: Int
    var hintsUsed: Int
    var elapsed: Int
}

struct PlayerStats: Codable, Equatable {
    var wins: [String: Int] = [:]
    var bestTimes: [String: Int] = [:]
    var totalStars = 0
    var dailyDaysCompleted: [String] = []
    var hasSeenTutorial = false

    var totalWins: Int { wins.values.reduce(0, +) }
}

/// Stores progress on the device only. No accounts, no tracking, nothing leaves the phone.
@MainActor
final class ProgressStore: ObservableObject {
    @Published private(set) var stats: PlayerStats
    @Published private(set) var savedGame: SavedGame?

    private let defaults: UserDefaults
    private let statsKey = "sudokukids.stats.v1"
    private let savedGameKey = "sudokukids.savedGame.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        stats = Self.decode(PlayerStats.self, from: defaults.data(forKey: statsKey)) ?? PlayerStats()
        savedGame = Self.decode(SavedGame.self, from: defaults.data(forKey: savedGameKey))
    }

    // MARK: Results

    func recordWin(config: GameConfig, seconds: Int, stars: Int) {
        let key = config.mode == .classic ? config.difficulty.rawValue : config.mode.rawValue
        stats.wins[key, default: 0] += 1
        if let best = stats.bestTimes[key] {
            stats.bestTimes[key] = min(best, seconds)
        } else {
            stats.bestTimes[key] = seconds
        }
        stats.totalStars += stars
        if config.mode == .daily, let day = config.dayKey, !stats.dailyDaysCompleted.contains(day) {
            stats.dailyDaysCompleted.append(day)
        }
        persistStats()
        clearSavedGame()
    }

    func wins(for difficulty: Difficulty) -> Int { stats.wins[difficulty.rawValue] ?? 0 }
    func bestTime(for difficulty: Difficulty) -> Int? { stats.bestTimes[difficulty.rawValue] }

    func isDailyDone(on date: Date = Date()) -> Bool {
        stats.dailyDaysCompleted.contains(DayKey.string(for: date))
    }

    /// Days in a row the Daily Challenge was finished, counting today or yesterday.
    func dailyStreak(today: Date = Date(), calendar: Calendar = .current) -> Int {
        let done = Set(stats.dailyDaysCompleted)
        var day = today
        if !done.contains(DayKey.string(for: day, calendar: calendar)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var streak = 0
        while done.contains(DayKey.string(for: day, calendar: calendar)) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    func markTutorialSeen() {
        stats.hasSeenTutorial = true
        persistStats()
    }

    // MARK: Saved game

    func save(_ game: SavedGame) {
        savedGame = game
        defaults.set(try? JSONEncoder().encode(game), forKey: savedGameKey)
    }

    func clearSavedGame() {
        savedGame = nil
        defaults.removeObject(forKey: savedGameKey)
    }

    // MARK: Helpers

    private func persistStats() {
        defaults.set(try? JSONEncoder().encode(stats), forKey: statsKey)
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
