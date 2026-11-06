import Foundation

struct Trophy: Identifiable, Hashable {
    let id: String
    let emoji: String
    let title: String
    /// What to do to earn it.
    let goal: String
}

enum Trophies {
    static let all: [Trophy] = [
        Trophy(id: "first", emoji: "🎈", title: "First Puzzle", goal: "Solve any puzzle"),
        Trophy(id: "tiny", emoji: "🐣", title: "Tiny Champ", goal: "Solve a 4×4 puzzle"),
        Trophy(id: "junior", emoji: "🐥", title: "Junior Star", goal: "Solve a 6×6 puzzle"),
        Trophy(id: "classic", emoji: "🦉", title: "Big Grid Hero", goal: "Solve a 9×9 puzzle"),
        Trophy(id: "hard", emoji: "🦊", title: "Fox Brain", goal: "Solve a Hard puzzle"),
        Trophy(id: "expert", emoji: "🦁", title: "Lion Heart", goal: "Solve an Expert puzzle"),
        Trophy(id: "perfect", emoji: "💎", title: "Perfect!", goal: "Solve a puzzle with no hints and no mistakes"),
        Trophy(id: "solo", emoji: "🧗", title: "No Help Needed", goal: "Solve a Hard or Expert puzzle without hints"),
        Trophy(id: "speedy", emoji: "⚡", title: "Speedy", goal: "Solve a 9×9 Easy puzzle in under 5 minutes"),
        Trophy(id: "streak3", emoji: "🔥", title: "On Fire", goal: "Do the Daily Challenge 3 days in a row"),
        Trophy(id: "streak7", emoji: "🌈", title: "Rainbow Week", goal: "Do the Daily Challenge 7 days in a row"),
        Trophy(id: "wins10", emoji: "🏅", title: "Ten Solved", goal: "Solve 10 puzzles"),
        Trophy(id: "wins50", emoji: "🏆", title: "Fifty Solved", goal: "Solve 50 puzzles"),
        Trophy(id: "stars100", emoji: "⭐", title: "Star Collector", goal: "Collect 100 stars"),
        Trophy(id: "scholar", emoji: "🎓", title: "Sudoku Scholar", goal: "Finish all four lessons"),
        Trophy(id: "explorer", emoji: "🗺️", title: "Explorer", goal: "Finish every level in one adventure world"),
        Trophy(id: "hero", emoji: "👑", title: "Adventure Hero", goal: "Finish every adventure world"),
    ]

    static func byID(_ id: String) -> Trophy? { all.first { $0.id == id } }

    /// Every trophy these stats deserve.
    static func earned(by stats: PlayerStats) -> Set<String> {
        var got = Set<String>()
        func add(_ id: String, _ condition: Bool) { if condition { got.insert(id) } }

        add("first", stats.totalWins >= 1)
        add("tiny", stats.winCount(size: .four) >= 1)
        add("junior", stats.winCount(size: .six) >= 1)
        add("classic", stats.winCount(size: .nine) >= 1)
        add("hard", stats.winCount(difficulty: .hard) >= 1)
        add("expert", stats.winCount(difficulty: .expert) >= 1)
        add("perfect", stats.perfectGames >= 1)
        add("solo", stats.noHintHardWins >= 1)
        add("speedy", (stats.bestTimes[PlayerStats.key(.nine, .easy)] ?? Int.max) <= 300)
        add("streak3", stats.maxStreak >= 3)
        add("streak7", stats.maxStreak >= 7)
        add("wins10", stats.totalWins >= 10)
        add("wins50", stats.totalWins >= 50)
        add("stars100", stats.totalStars >= 100)
        add("scholar", Technique.allCases.allSatisfy { stats.techniquesLearned.contains($0.rawValue) })

        let finishedWorlds = Adventure.worlds.filter { world in
            world.levels.allSatisfy { stats.adventureStars[$0.id] != nil }
        }
        add("explorer", !finishedWorlds.isEmpty)
        add("hero", finishedWorlds.count == Adventure.worlds.count)
        return got
    }
}
