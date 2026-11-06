import Foundation

struct AdventureLevel: Identifiable, Hashable {
    let id: String
    let worldID: String
    let number: Int
    let size: GridSize
    let difficulty: Difficulty

    /// Every child gets the same puzzle for the same level.
    var seed: UInt64 { StableHash.of("sudokukids-adventure-\(id)") }
}

struct AdventureWorld: Identifiable, Hashable {
    let id: String
    let title: String
    let emoji: String
    let blurb: String
    let symbols: SymbolSet
    let levels: [AdventureLevel]
}

enum Adventure {
    static let worlds: [AdventureWorld] = [
        world("forest", "Forest Friends", "🌳", "Tiny 4×4 puzzles with animal friends", .animals,
              [(.four, .easy), (.four, .easy), (.four, .medium), (.four, .medium), (.four, .hard), (.six, .easy)]),
        world("ocean", "Ocean Wonders", "🌊", "Dive into 6×6 puzzles", .ocean,
              [(.six, .easy), (.six, .medium), (.six, .medium), (.six, .hard), (.six, .hard), (.six, .expert)]),
        world("garden", "Fruit Garden", "🍓", "Your first big 9×9 puzzles", .fruit,
              [(.nine, .easy), (.nine, .easy), (.nine, .easy), (.nine, .medium), (.nine, .medium), (.nine, .medium)]),
        world("space", "Starry Space", "🚀", "Bigger thinking among the stars", .numbers,
              [(.nine, .medium), (.nine, .medium), (.nine, .hard), (.nine, .hard), (.nine, .hard), (.nine, .expert)]),
        world("dino", "Dino Valley", "🦖", "Only the bravest solvers get here", .colors,
              [(.nine, .hard), (.nine, .hard), (.nine, .expert), (.nine, .expert), (.nine, .expert), (.nine, .expert)]),
    ]

    /// All levels in play order.
    static let allLevels: [AdventureLevel] = worlds.flatMap(\.levels)

    static func find(_ levelID: String) -> (world: AdventureWorld, level: AdventureLevel)? {
        for w in worlds {
            if let l = w.levels.first(where: { $0.id == levelID }) { return (w, l) }
        }
        return nil
    }

    /// A level opens once the level before it is finished.
    static func isUnlocked(_ level: AdventureLevel, completed: Set<String>) -> Bool {
        guard let index = allLevels.firstIndex(of: level) else { return false }
        return index == 0 || completed.contains(allLevels[index - 1].id)
    }

    static func next(after levelID: String) -> AdventureLevel? {
        guard let index = allLevels.firstIndex(where: { $0.id == levelID }), index + 1 < allLevels.count else { return nil }
        return allLevels[index + 1]
    }

    private static func world(_ id: String, _ title: String, _ emoji: String, _ blurb: String, _ symbols: SymbolSet,
                              _ specs: [(GridSize, Difficulty)]) -> AdventureWorld {
        let levels = specs.enumerated().map { offset, spec in
            AdventureLevel(id: "\(id)-\(offset + 1)", worldID: id, number: offset + 1, size: spec.0, difficulty: spec.1)
        }
        return AdventureWorld(id: id, title: title, emoji: emoji, blurb: blurb, symbols: symbols, levels: levels)
    }
}
