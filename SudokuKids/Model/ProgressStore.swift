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
    /// Wins by key: "total", "size-9", "level-hard", "mode-daily", "9-easy".
    var wins: [String: Int] = [:]
    /// Best time in seconds, keyed like "9-easy".
    var bestTimes: [String: Int] = [:]
    var totalStars = 0
    var perfectGames = 0
    var noHintHardWins = 0
    var dailyDaysCompleted: [String] = []
    var maxStreak = 0
    var trophies: Set<String> = []
    var techniquesSeen: Set<String> = []
    var techniquesLearned: Set<String> = []
    /// Best stars for each finished adventure level.
    var adventureStars: [String: Int] = [:]
    /// Seconds played, by day ("2026-11-05").
    var playSeconds: [String: Int] = [:]
    var hasSeenTutorial = false

    static func key(_ size: GridSize, _ difficulty: Difficulty) -> String { "\(size.n)-\(difficulty.rawValue)" }

    var totalWins: Int { wins["total"] ?? 0 }
    func winCount(size: GridSize) -> Int { wins["size-\(size.n)"] ?? 0 }
    func winCount(difficulty: Difficulty) -> Int { wins["level-\(difficulty.rawValue)"] ?? 0 }
    func winCount(size: GridSize, difficulty: Difficulty) -> Int { wins[Self.key(size, difficulty)] ?? 0 }

    init() {}

    // Missing keys fall back to defaults, so adding fields later never wipes progress.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        wins = try c.decodeIfPresent([String: Int].self, forKey: .wins) ?? [:]
        bestTimes = try c.decodeIfPresent([String: Int].self, forKey: .bestTimes) ?? [:]
        totalStars = try c.decodeIfPresent(Int.self, forKey: .totalStars) ?? 0
        perfectGames = try c.decodeIfPresent(Int.self, forKey: .perfectGames) ?? 0
        noHintHardWins = try c.decodeIfPresent(Int.self, forKey: .noHintHardWins) ?? 0
        dailyDaysCompleted = try c.decodeIfPresent([String].self, forKey: .dailyDaysCompleted) ?? []
        maxStreak = try c.decodeIfPresent(Int.self, forKey: .maxStreak) ?? 0
        trophies = try c.decodeIfPresent(Set<String>.self, forKey: .trophies) ?? []
        techniquesSeen = try c.decodeIfPresent(Set<String>.self, forKey: .techniquesSeen) ?? []
        techniquesLearned = try c.decodeIfPresent(Set<String>.self, forKey: .techniquesLearned) ?? []
        adventureStars = try c.decodeIfPresent([String: Int].self, forKey: .adventureStars) ?? [:]
        playSeconds = try c.decodeIfPresent([String: Int].self, forKey: .playSeconds) ?? [:]
        hasSeenTutorial = try c.decodeIfPresent(Bool.self, forKey: .hasSeenTutorial) ?? false
    }
}

/// Choices each child makes for themselves.
struct PlayerPrefs: Codable, Equatable {
    var symbols: SymbolSet = .numbers
    var showMistakes = true
    /// Play mode only: three mistakes ends the game.
    var threeStrikes = false
    var readHintsAloud = false
    var classicSize: GridSize = .nine

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        symbols = try c.decodeIfPresent(SymbolSet.self, forKey: .symbols) ?? .numbers
        showMistakes = try c.decodeIfPresent(Bool.self, forKey: .showMistakes) ?? true
        threeStrikes = try c.decodeIfPresent(Bool.self, forKey: .threeStrikes) ?? false
        readHintsAloud = try c.decodeIfPresent(Bool.self, forKey: .readHintsAloud) ?? false
        classicSize = try c.decodeIfPresent(GridSize.self, forKey: .classicSize) ?? .nine
    }
}

/// Settings for the whole device.
struct DeviceSettings: Codable, Equatable {
    var sound = true
    var haptics = true
    /// 0 = off.
    var breakReminderMinutes = 0

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sound = try c.decodeIfPresent(Bool.self, forKey: .sound) ?? true
        haptics = try c.decodeIfPresent(Bool.self, forKey: .haptics) ?? true
        breakReminderMinutes = try c.decodeIfPresent(Int.self, forKey: .breakReminderMinutes) ?? 0
    }
}

struct Profile: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var avatar: String
    var stats: PlayerStats
    var prefs: PlayerPrefs
    var savedGame: SavedGame?

    static func new(name: String, avatar: String) -> Profile {
        Profile(id: UUID(), name: name, avatar: avatar, stats: PlayerStats(), prefs: PlayerPrefs(), savedGame: nil)
    }

    static let avatars = ["🦉", "🐼", "🦊", "🐯", "🐸", "🐰", "🦄", "🐙", "🐶", "🐱", "🦁", "🐨"]
    static let maxCount = 6
}

/// Stores everything on the device only. No accounts, no tracking, nothing leaves the phone.
@MainActor
final class ProgressStore: ObservableObject {
    @Published private(set) var profiles: [Profile]
    @Published private(set) var activeID: UUID
    @Published var settings: DeviceSettings {
        didSet {
            Feedback.soundOn = settings.sound
            Feedback.hapticsOn = settings.haptics
            persist()
        }
    }

    private let defaults: UserDefaults
    private let key = "sudokukids.store.v2"
    private var unsavedPlaySeconds = 0
    /// Today's play time when the last break reminder was closed.
    private var breakAcknowledgedAt: Int?

    private struct File: Codable {
        var profiles: [Profile]
        var activeID: UUID
        var settings: DeviceSettings
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let file = try? JSONDecoder().decode(File.self, from: data),
           !file.profiles.isEmpty {
            profiles = file.profiles
            activeID = file.profiles.contains(where: { $0.id == file.activeID }) ? file.activeID : file.profiles[0].id
            settings = file.settings
        } else {
            let first = Profile.new(name: "Player 1", avatar: "🦉")
            profiles = [first]
            activeID = first.id
            settings = DeviceSettings()
        }
        Feedback.soundOn = settings.sound
        Feedback.hapticsOn = settings.haptics
    }

    // MARK: Active profile

    var profile: Profile { profiles.first { $0.id == activeID } ?? profiles[0] }
    var stats: PlayerStats { profile.stats }
    var prefs: PlayerPrefs { profile.prefs }
    var savedGame: SavedGame? { profile.savedGame }

    private func updateActive(_ change: (inout Profile) -> Void) {
        guard let index = profiles.firstIndex(where: { $0.id == activeID }) else { return }
        change(&profiles[index])
        persist()
    }

    func updatePrefs(_ change: (inout PlayerPrefs) -> Void) {
        updateActive { change(&$0.prefs) }
    }

    // MARK: Profiles

    var canAddProfile: Bool { profiles.count < Profile.maxCount }

    func switchTo(_ id: UUID) {
        guard profiles.contains(where: { $0.id == id }) else { return }
        flushPlayTime()
        activeID = id
        breakAcknowledgedAt = nil
        persist()
    }

    @discardableResult
    func addProfile(name: String, avatar: String) -> Profile? {
        guard canAddProfile else { return nil }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let profile = Profile.new(name: trimmed.isEmpty ? "Player \(profiles.count + 1)" : trimmed, avatar: avatar)
        profiles.append(profile)
        switchTo(profile.id)
        return profile
    }

    func rename(_ id: UUID, to name: String, avatar: String? = nil) {
        guard let index = profiles.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { profiles[index].name = trimmed }
        if let avatar { profiles[index].avatar = avatar }
        persist()
    }

    func deleteProfile(_ id: UUID) {
        guard profiles.count > 1 else { return }
        profiles.removeAll { $0.id == id }
        if activeID == id { activeID = profiles[0].id }
        persist()
    }

    func resetProgress(_ id: UUID) {
        guard let index = profiles.firstIndex(where: { $0.id == id }) else { return }
        profiles[index].stats = PlayerStats()
        profiles[index].savedGame = nil
        persist()
    }

    // MARK: Results

    /// Records a finished puzzle. Returns any trophies earned for the first time.
    func recordWin(config: GameConfig, seconds: Int, stars: Int, mistakes: Int, hintsUsed: Int) -> [Trophy] {
        var newTrophies: [Trophy] = []
        updateActive { p in
            var s = p.stats
            for k in ["total", "size-\(config.size.n)", "level-\(config.difficulty.rawValue)", "mode-\(config.mode.rawValue)"] {
                s.wins[k, default: 0] += 1
            }
            if config.mode == .classic {
                let k = PlayerStats.key(config.size, config.difficulty)
                s.wins[k, default: 0] += 1
                s.bestTimes[k] = min(s.bestTimes[k] ?? Int.max, seconds)
            }
            // Replaying today's Daily Challenge or a finished adventure level adds no extra stars.
            let replayingDaily = config.mode == .daily && config.dayKey.map { s.dailyDaysCompleted.contains($0) } == true
            if replayingDaily {
                // no stars
            } else if config.mode == .adventure, let id = config.levelID {
                s.totalStars += max(0, stars - (s.adventureStars[id] ?? 0))
            } else {
                s.totalStars += stars
            }
            if mistakes == 0 && hintsUsed == 0 { s.perfectGames += 1 }
            if hintsUsed == 0 && (config.difficulty == .hard || config.difficulty == .expert) { s.noHintHardWins += 1 }
            if config.mode == .daily, let day = config.dayKey, !s.dailyDaysCompleted.contains(day) {
                s.dailyDaysCompleted.append(day)
                s.maxStreak = max(s.maxStreak, Self.streak(days: s.dailyDaysCompleted))
            }
            if config.mode == .adventure, let id = config.levelID {
                s.adventureStars[id] = max(s.adventureStars[id] ?? 0, stars)
            }
            newTrophies = Self.awardTrophies(&s)
            p.stats = s
            p.savedGame = nil
        }
        return newTrophies
    }

    func markTechniqueSeen(_ technique: Technique) {
        guard !stats.techniquesSeen.contains(technique.rawValue) else { return }
        updateActive { $0.stats.techniquesSeen.insert(technique.rawValue) }
    }

    /// Returns any trophies earned for the first time.
    func markLessonLearned(_ technique: Technique) -> [Trophy] {
        var newTrophies: [Trophy] = []
        updateActive { p in
            p.stats.techniquesSeen.insert(technique.rawValue)
            p.stats.techniquesLearned.insert(technique.rawValue)
            newTrophies = Self.awardTrophies(&p.stats)
        }
        return newTrophies
    }

    func markTutorialSeen() {
        updateActive { $0.stats.hasSeenTutorial = true }
    }

    private static func awardTrophies(_ stats: inout PlayerStats) -> [Trophy] {
        let earned = Trophies.earned(by: stats)
        let fresh = earned.subtracting(stats.trophies)
        stats.trophies.formUnion(earned)
        return Trophies.all.filter { fresh.contains($0.id) }
    }

    // MARK: Daily challenge

    func isDailyDone(on date: Date = Date()) -> Bool {
        stats.dailyDaysCompleted.contains(DayKey.string(for: date))
    }

    func dailyStreak(today: Date = Date()) -> Int {
        Self.streak(days: stats.dailyDaysCompleted, today: today)
    }

    /// Days in a row finished, counting back from today (or yesterday if today isn't done yet).
    static func streak(days: [String], today: Date = Date(), calendar: Calendar = .current) -> Int {
        let done = Set(days)
        var day = today
        if !done.contains(DayKey.string(for: day, calendar: calendar)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var count = 0
        while done.contains(DayKey.string(for: day, calendar: calendar)) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    // MARK: Adventure

    var completedLevels: Set<String> { Set(stats.adventureStars.keys) }

    func stars(for level: AdventureLevel) -> Int? { stats.adventureStars[level.id] }

    func isUnlocked(_ level: AdventureLevel) -> Bool {
        Adventure.isUnlocked(level, completed: completedLevels)
    }

    // MARK: Play time and breaks

    func addPlaySecond() {
        let day = DayKey.string(for: Date())
        guard let index = profiles.firstIndex(where: { $0.id == activeID }) else { return }
        profiles[index].stats.playSeconds[day, default: 0] += 1
        unsavedPlaySeconds += 1
        if unsavedPlaySeconds >= 15 { flushPlayTime() }
    }

    func flushPlayTime() {
        guard unsavedPlaySeconds > 0 else { return }
        unsavedPlaySeconds = 0
        persist()
    }

    func playedToday(for profile: Profile? = nil) -> Int {
        (profile ?? self.profile).stats.playSeconds[DayKey.string(for: Date())] ?? 0
    }

    /// Seconds played in the last 7 days.
    func playedThisWeek(for profile: Profile) -> Int {
        let calendar = Calendar.current
        return (0..<7).reduce(0) { total, back in
            guard let day = calendar.date(byAdding: .day, value: -back, to: Date()) else { return total }
            return total + (profile.stats.playSeconds[DayKey.string(for: day)] ?? 0)
        }
    }

    var isBreakDue: Bool {
        let limit = settings.breakReminderMinutes * 60
        guard limit > 0 else { return false }
        let played = playedToday()
        return played - (breakAcknowledgedAt ?? 0) >= limit
    }

    func acknowledgeBreak() {
        breakAcknowledgedAt = playedToday()
    }

    // MARK: Saved game

    func save(_ game: SavedGame) {
        updateActive { $0.savedGame = game }
    }

    func clearSavedGame() {
        updateActive { $0.savedGame = nil }
    }

    // MARK: Storage

    private func persist() {
        let file = File(profiles: profiles, activeID: activeID, settings: settings)
        if let data = try? JSONEncoder().encode(file) {
            defaults.set(data, forKey: key)
        }
    }
}
