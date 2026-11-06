import Foundation

/// What kids see in place of the numbers 1...9.
enum SymbolSet: String, Codable, CaseIterable, Identifiable, Hashable {
    case numbers, animals, fruit, ocean, colors

    var id: String { rawValue }

    var title: String {
        switch self {
        case .numbers: return "Numbers"
        case .animals: return "Animals"
        case .fruit: return "Fruit"
        case .ocean: return "Sea life"
        case .colors: return "Colours"
        }
    }

    private var glyphs: [String] {
        switch self {
        case .numbers: return (1...9).map(String.init)
        case .animals: return ["🐶", "🐱", "🐰", "🦊", "🐻", "🐼", "🐸", "🐯", "🐷"]
        case .fruit: return ["🍎", "🍌", "🍇", "🍓", "🍊", "🍉", "🍒", "🍑", "🍍"]
        case .ocean: return ["🐠", "🐙", "🦀", "🐬", "🐳", "🦈", "🐢", "🦑", "🐚"]
        case .colors: return ["🔴", "🟧", "🟡", "🟩", "🔵", "🟪", "🟤", "⬛", "⚪"]
        }
    }

    private var names: [String] {
        switch self {
        case .numbers: return (1...9).map(String.init)
        case .animals: return ["dog", "cat", "bunny", "fox", "bear", "panda", "frog", "tiger", "pig"]
        case .fruit: return ["apple", "banana", "grapes", "strawberry", "orange", "watermelon", "cherries", "peach", "pineapple"]
        case .ocean: return ["fish", "octopus", "crab", "dolphin", "whale", "shark", "turtle", "squid", "shell"]
        case .colors: return ["red", "orange", "yellow", "green", "blue", "purple", "brown", "black", "white"]
        }
    }

    var isNumbers: Bool { self == .numbers }

    /// What to draw for digit `d` (1-based).
    func display(_ d: Int) -> String {
        guard d >= 1, d <= 9 else { return "" }
        return glyphs[d - 1]
    }

    /// What to say out loud for digit `d`.
    func spoken(_ d: Int) -> String {
        guard d >= 1, d <= 9 else { return "" }
        return names[d - 1]
    }

    /// A short sample for pickers, e.g. "🐶🐱🐰".
    var preview: String { glyphs.prefix(3).joined() }
}
