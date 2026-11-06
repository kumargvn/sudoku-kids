import SwiftUI

struct CellState: Equatable {
    var value: Int
    var notes: Set<Int>
    var isGiven: Bool
    var isWrong: Bool
    var isSelected: Bool
    var isHintTarget: Bool
    var highlight: Highlight

    enum Highlight: Equatable {
        case none, related, sameNumber, hintFocus, key
    }
}

@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var config: GameConfig
    @Published private(set) var puzzle: Puzzle? = nil
    @Published private(set) var values: [Int]
    @Published private(set) var notes: [Set<Int>]
    @Published private(set) var mistakes = 0
    @Published private(set) var hintsUsed = 0
    @Published private(set) var elapsed = 0
    @Published private(set) var isComplete = false
    @Published private(set) var isGameOver = false
    /// With "show mistakes" off, wrong squares turn red only once the board is full.
    @Published private(set) var revealMistakes = false
    @Published private(set) var newTrophies: [Trophy] = []
    @Published var selected: Int? = nil
    @Published var notesMode = false
    @Published var activeHint: Hint? = nil
    @Published var toast: String? = nil

    @Published private(set) var symbols: SymbolSet
    let showMistakes: Bool
    /// Three mistakes ends a Play-mode game when the challenge is on.
    let strikeLimit: Int?
    let readHintsAloud: Bool

    private let store: ProgressStore
    private var undoStack: [(values: [Int], notes: [Set<Int>])] = []
    /// Ignores puzzles that finish generating after the player already moved on.
    private var generation = 0

    var geo: Geometry { config.size.geometry }
    var size: GridSize { config.size }

    init(config: GameConfig, resume saved: SavedGame? = nil, store: ProgressStore) {
        self.config = config
        self.store = store
        let prefs = store.prefs
        let limit: Int? = (prefs.threeStrikes && config.mode == .classic) ? 3 : nil
        if config.mode == .adventure, let id = config.levelID, let found = Adventure.find(id) {
            symbols = found.world.symbols
        } else if config.mode == .daily {
            symbols = .numbers
        } else {
            symbols = prefs.symbols
        }
        strikeLimit = limit
        showMistakes = prefs.showMistakes || limit != nil || config.mode == .learn
        readHintsAloud = prefs.readHintsAloud

        let count = config.size.cellCount
        values = [Int](repeating: 0, count: count)
        notes = [Set<Int>](repeating: [], count: count)

        if let saved, saved.config == config, saved.puzzle.size == config.size {
            puzzle = saved.puzzle
            values = saved.values
            notes = saved.notes
            mistakes = saved.mistakes
            hintsUsed = saved.hintsUsed
            elapsed = saved.elapsed
        } else {
            newGame()
        }
    }

    // MARK: Setup

    var isLoading: Bool { puzzle == nil }
    var isPlaying: Bool { !isLoading && !isComplete && !isGameOver }

    func newGame() {
        puzzle = nil
        resetBoardState()
        let size = config.size
        let difficulty = config.difficulty
        let seed = config.seed
        generation += 1
        let ticket = generation
        Task {
            let made = await Task.detached(priority: .userInitiated) {
                PuzzleGenerator.generate(size: size, difficulty: difficulty, seed: seed)
            }.value
            guard ticket == self.generation else { return }
            self.puzzle = made
            self.values = made.givens
            self.saveProgress()
        }
    }

    /// Same puzzle, fresh start (after running out of tries).
    func retry() {
        guard let puzzle else { return }
        resetBoardState()
        values = puzzle.givens
        saveProgress()
    }

    /// Moves to a new config (e.g. the next adventure level) in place.
    func start(_ newConfig: GameConfig) {
        config = newConfig
        if newConfig.mode == .adventure, let id = newConfig.levelID, let found = Adventure.find(id) {
            symbols = found.world.symbols
        }
        newGame()
    }

    private func resetBoardState() {
        let count = config.size.cellCount
        values = [Int](repeating: 0, count: count)
        notes = [Set<Int>](repeating: [], count: count)
        mistakes = 0
        hintsUsed = 0
        elapsed = 0
        isComplete = false
        isGameOver = false
        revealMistakes = false
        newTrophies = []
        selected = nil
        notesMode = false
        activeHint = nil
        toast = nil
        undoStack = []
    }

    // MARK: Questions the views ask

    var hintsLeft: Int? {
        config.maxHints.map { max(0, $0 - hintsUsed) }
    }

    var canUseHint: Bool { isPlaying && (hintsLeft ?? 1) > 0 }

    var triesLeft: Int? { strikeLimit.map { max(0, $0 - mistakes) } }

    var stars: Int {
        if hintsUsed == 0 && mistakes <= 1 { return 3 }
        if hintsUsed <= 2 && mistakes <= 4 { return 2 }
        return 1
    }

    var showsCandidateHelp: Bool { config.mode == .learn }

    var nextAdventureLevel: AdventureLevel? {
        guard config.mode == .adventure, let id = config.levelID else { return nil }
        return Adventure.next(after: id)
    }

    func isGiven(_ i: Int) -> Bool { (puzzle?.givens[i] ?? 0) != 0 }

    private func isActuallyWrong(_ i: Int) -> Bool {
        guard let puzzle, values[i] != 0 else { return false }
        return values[i] != puzzle.solution[i]
    }

    func isWrong(_ i: Int) -> Bool {
        (showMistakes || revealMistakes) && isActuallyWrong(i)
    }

    /// How many more times each digit still needs to be placed.
    func remaining(_ digit: Int) -> Int {
        guard let puzzle else { return size.n }
        let placed = (0..<geo.count).filter { values[$0] == digit && puzzle.solution[$0] == digit }.count
        return size.n - placed
    }

    /// The board without wrong numbers, so they don't block the right answers.
    private var correctValues: [Int] {
        guard let puzzle else { return values }
        return (0..<geo.count).map { values[$0] != 0 && values[$0] != puzzle.solution[$0] ? 0 : values[$0] }
    }

    /// Digits that don't clash with anything for the selected cell (Learn mode helper).
    var allowedForSelection: Set<Int>? {
        guard let i = selected, !isGiven(i) else { return nil }
        var grid = correctValues
        grid[i] = 0
        return Set(geo.digits(in: geo.candidateMask(grid, i)))
    }

    func cellState(_ i: Int) -> CellState {
        let value = values[i]
        var highlight = CellState.Highlight.none
        if let hint = activeHint, hint.keyCells.contains(i) {
            highlight = .key
        } else if let hint = activeHint, hint.focusCells.contains(i) {
            highlight = .hintFocus
        } else if let s = selected {
            let selectedValue = values[s]
            if selectedValue != 0 && value == selectedValue {
                highlight = .sameNumber
            } else if geo.areRelated(s, i) {
                highlight = .related
            }
        }
        return CellState(
            value: value,
            notes: notes[i],
            isGiven: isGiven(i),
            isWrong: isWrong(i),
            isSelected: selected == i,
            isHintTarget: activeHint?.cell == i,
            highlight: highlight
        )
    }

    // MARK: Actions

    func select(_ i: Int) {
        guard isPlaying else { return }
        selected = i
        Feedback.tap()
    }

    func enter(_ digit: Int) {
        guard let i = selected, let puzzle, isPlaying, !isGiven(i) else { return }

        if notesMode {
            guard values[i] == 0 else { return }
            pushUndo()
            if notes[i].contains(digit) { notes[i].remove(digit) } else { notes[i].insert(digit) }
            Feedback.tap()
            saveProgress()
            return
        }

        guard values[i] != digit else { return }
        pushUndo()
        values[i] = digit
        notes[i] = []

        if digit == puzzle.solution[i] {
            clearNotes(of: digit, around: i)
            Feedback.place()
        } else {
            mistakes += 1
            Feedback.oops()
            if let limit = strikeLimit, mistakes >= limit {
                isGameOver = true
                selected = nil
                activeHint = nil
                store.clearSavedGame()
                return
            }
        }

        if activeHint?.cell == i { activeHint = nil }
        afterBoardChange()
    }

    func erase() {
        guard let i = selected, isPlaying, !isGiven(i) else { return }
        guard values[i] != 0 || !notes[i].isEmpty else { return }
        pushUndo()
        values[i] = 0
        notes[i] = []
        if activeHint?.isMistake == true && activeHint?.cell == i { activeHint = nil }
        Feedback.tap()
        saveProgress()
    }

    func undo() {
        guard isPlaying, let last = undoStack.popLast() else { return }
        values = last.values
        notes = last.notes
        activeHint = nil
        Feedback.tap()
        saveProgress()
    }

    func toggleNotes() {
        guard isPlaying else { return }
        notesMode.toggle()
        Feedback.tap()
    }

    /// Fills every empty square's notes with the numbers that could go there.
    func autoNotes() {
        guard isPlaying else { return }
        pushUndo()
        let grid = correctValues
        for i in 0..<geo.count where values[i] == 0 {
            notes[i] = Set(geo.digits(in: geo.candidateMask(grid, i)))
        }
        toast = "Notes filled in! ✏️"
        Feedback.hint()
        saveProgress()
    }

    func requestHint() {
        guard canUseHint, let puzzle else { return }
        guard let hint = HintEngine.hint(values: values, puzzle: puzzle, symbols: symbols) else { return }
        if !hint.isMistake { hintsUsed += 1 }
        if let technique = hint.technique { store.markTechniqueSeen(technique) }
        activeHint = hint
        selected = hint.cell
        Feedback.hint()
        if readHintsAloud { Speaker.shared.say(hint.spoken) }
        saveProgress()
    }

    func speakHint() {
        guard let hint = activeHint else { return }
        Speaker.shared.say(hint.spoken)
    }

    /// Does what the hint suggests: fills in the answer, or erases a wrong number.
    func applyHint() {
        guard let hint = activeHint, let puzzle, isPlaying else { return }
        pushUndo()
        if hint.isMistake {
            values[hint.cell] = 0
        } else {
            values[hint.cell] = puzzle.solution[hint.cell]
            clearNotes(of: hint.value, around: hint.cell)
            Feedback.place()
        }
        notes[hint.cell] = []
        activeHint = nil
        selected = hint.cell
        Speaker.shared.stop()
        afterBoardChange()
    }

    func dismissHint() {
        activeHint = nil
        Speaker.shared.stop()
    }

    func tick() {
        guard isPlaying else { return }
        elapsed += 1
        store.addPlaySecond()
        if elapsed % 5 == 0 { saveProgress() }
    }

    // MARK: Internals

    private func pushUndo() {
        undoStack.append((values, notes))
        if undoStack.count > 200 { undoStack.removeFirst() }
    }

    private func clearNotes(of digit: Int, around i: Int) {
        for p in geo.peers[i] { notes[p].remove(digit) }
    }

    private func afterBoardChange() {
        defer { saveProgress() }
        guard let puzzle else { return }
        if values == puzzle.solution {
            isComplete = true
            selected = nil
            activeHint = nil
            Feedback.win()
            newTrophies = store.recordWin(config: config, seconds: elapsed, stars: stars,
                                          mistakes: mistakes, hintsUsed: hintsUsed)
        } else if !values.contains(0) && !showMistakes {
            revealMistakes = true
            toast = "Almost! Fix the red squares."
        }
    }

    private func saveProgress() {
        guard let puzzle, isPlaying else { return }
        store.save(SavedGame(
            config: config,
            puzzle: puzzle,
            values: values,
            notes: notes,
            mistakes: mistakes,
            hintsUsed: hintsUsed,
            elapsed: elapsed
        ))
    }
}
