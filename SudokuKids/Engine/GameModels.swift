import Foundation

enum Difficulty: String, CaseIterable, Codable, Identifiable, Hashable {
    case easy, medium, hard, expert

    var id: String { rawValue }

    var title: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .expert: return "Expert"
        }
    }

    var emoji: String {
        switch self {
        case .easy: return "🐣"
        case .medium: return "🐥"
        case .hard: return "🦊"
        case .expert: return "🦁"
        }
    }

    var tagline: String {
        switch self {
        case .easy: return "Lots of numbers to help you"
        case .medium: return "A little more thinking"
        case .hard: return "For puzzle pros"
        case .expert: return "The ultimate brain workout"
        }
    }

    /// How many numbers the puzzle starts with (fewer = harder).
    var targetClues: Int {
        switch self {
        case .easy: return 40
        case .medium: return 32
        case .hard: return 28
        case .expert: return 24
        }
    }

    /// Easy and Medium puzzles can always be finished with the two
    /// beginner techniques the hints teach, so kids never get stuck.
    var requiresBeginnerLogic: Bool {
        self == .easy || self == .medium
    }

    var hintsAllowed: Int {
        switch self {
        case .easy: return 5
        case .medium: return 4
        case .hard: return 3
        case .expert: return 3
        }
    }
}

enum GameMode: String, Codable, CaseIterable, Hashable {
    /// Pick any level, limited hints.
    case classic
    /// One puzzle per day, the same for everyone.
    case daily
    /// Unlimited hints that explain each step, plus number helpers.
    case learn
}

struct GameConfig: Codable, Hashable {
    var mode: GameMode
    var difficulty: Difficulty
    /// Fixed seed for reproducible puzzles (Daily Challenge). nil = random.
    var seed: UInt64?
    /// The calendar day for a Daily Challenge, e.g. "2026-11-05".
    var dayKey: String?

    static func classic(_ difficulty: Difficulty) -> GameConfig {
        GameConfig(mode: .classic, difficulty: difficulty, seed: nil, dayKey: nil)
    }

    static func learn() -> GameConfig {
        GameConfig(mode: .learn, difficulty: .easy, seed: nil, dayKey: nil)
    }

    static func daily(on date: Date = Date()) -> GameConfig {
        let key = DayKey.string(for: date)
        let seed = UInt64(key.replacingOccurrences(of: "-", with: "")) ?? 1
        return GameConfig(mode: .daily, difficulty: .medium, seed: seed &* 2_654_435_761, dayKey: key)
    }

    /// nil means unlimited.
    var maxHints: Int? {
        switch mode {
        case .learn: return nil
        case .daily: return 3
        case .classic: return difficulty.hintsAllowed
        }
    }

    var title: String {
        switch mode {
        case .classic: return "\(difficulty.emoji) \(difficulty.title)"
        case .daily: return "📅 Daily Challenge"
        case .learn: return "🦉 Learn to Play"
        }
    }
}

struct Puzzle: Codable, Equatable {
    let givens: [Int]
    let solution: [Int]
    let difficulty: Difficulty

    var clueCount: Int { givens.filter { $0 != 0 }.count }
}

enum DayKey {
    static func string(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 2000, c.month ?? 1, c.day ?? 1)
    }
}
