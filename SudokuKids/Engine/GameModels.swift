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
        case .easy: return "Lots of clues to help you"
        case .medium: return "A little more thinking"
        case .hard: return "Uses pointing lines and twins"
        case .expert: return "The ultimate brain workout"
        }
    }

    /// How many squares start filled in (fewer = harder).
    func targetClues(for size: GridSize) -> Int {
        let table: [Int]
        switch size {
        case .four: table = [10, 8, 7, 6]
        case .six: table = [22, 18, 15, 12]
        case .nine: table = [40, 32, 26, 24]
        }
        return table[Difficulty.allCases.firstIndex(of: self) ?? 0]
    }

    /// How a puzzle at this level must be solvable.
    /// Easy/Medium: only the two beginner techniques. Hard: all four techniques. Expert: just one answer.
    enum Rule { case placementsOnly, allTechniques, uniqueOnly }

    var rule: Rule {
        switch self {
        case .easy, .medium: return .placementsOnly
        case .hard: return .allTechniques
        case .expert: return .uniqueOnly
        }
    }

    var hintsAllowed: Int {
        switch self {
        case .easy: return 5
        case .medium: return 4
        case .hard, .expert: return 3
        }
    }
}

enum GameMode: String, Codable, CaseIterable, Hashable {
    /// Pick a size and level, limited hints.
    case classic
    /// One 9×9 puzzle per day, the same for everyone.
    case daily
    /// Practice with unlimited hints and number helpers.
    case learn
    /// Levels in the adventure map.
    case adventure
}

struct GameConfig: Codable, Hashable {
    var mode: GameMode
    var size: GridSize
    var difficulty: Difficulty
    /// Fixed seed for reproducible puzzles (Daily Challenge, Adventure). nil = random.
    var seed: UInt64?
    /// The calendar day of a Daily Challenge, e.g. "2026-11-05".
    var dayKey: String?
    /// The adventure level this game belongs to.
    var levelID: String?

    static func classic(_ difficulty: Difficulty, size: GridSize) -> GameConfig {
        GameConfig(mode: .classic, size: size, difficulty: difficulty, seed: nil, dayKey: nil, levelID: nil)
    }

    static func learn(size: GridSize) -> GameConfig {
        GameConfig(mode: .learn, size: size, difficulty: .easy, seed: nil, dayKey: nil, levelID: nil)
    }

    static func daily(on date: Date = Date()) -> GameConfig {
        let key = DayKey.string(for: date)
        let seed = (UInt64(key.replacingOccurrences(of: "-", with: "")) ?? 1) &* 2_654_435_761
        return GameConfig(mode: .daily, size: .nine, difficulty: .medium, seed: seed, dayKey: key, levelID: nil)
    }

    static func adventure(_ level: AdventureLevel) -> GameConfig {
        GameConfig(mode: .adventure, size: level.size, difficulty: level.difficulty, seed: level.seed, dayKey: nil, levelID: level.id)
    }

    /// nil means unlimited.
    var maxHints: Int? {
        switch mode {
        case .learn: return nil
        case .daily: return 3
        case .classic, .adventure: return difficulty.hintsAllowed
        }
    }

    var title: String {
        switch mode {
        case .classic: return "\(difficulty.emoji) \(difficulty.title) \(size.label)"
        case .daily: return "📅 Daily Challenge"
        case .learn: return "🦉 Practice \(size.label)"
        case .adventure:
            if let id = levelID, let found = Adventure.find(id) {
                return "\(found.world.emoji) Level \(found.level.number)"
            }
            return "🗺️ Adventure"
        }
    }
}

struct Puzzle: Codable, Equatable {
    let size: GridSize
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

/// Stable 64-bit hash (FNV-1a) so adventure levels always get the same puzzle.
enum StableHash {
    static func of(_ text: String) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01B3
        }
        return hash
    }
}
