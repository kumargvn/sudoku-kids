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
        case none, related, sameNumber, hintFocus
    }
}

@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var config: GameConfig
    @Published private(set) var puzzle: Puzzle?
    @Published private(set) var values = [Int](repeating: 0, count: Sudoku.cellCount)
    @Published private(set) var notes = [Set<Int>](repeating: [], count: Sudoku.cellCount)
    @Published private(set) var mistakes = 0
    @Published private(set) var hintsUsed = 0
    @Published private(set) var elapsed = 0
    @Published private(set) var isComplete = false
    @Published var selected: Int?
    @Published var notesMode = false
    @Published var activeHint: Hint?

    private let store: ProgressStore
    private var undoStack: [(values: [Int], notes: [Set<Int>])] = []

    init(config: GameConfig, resume saved: SavedGame? = nil, store: ProgressStore) {
        self.config = config
        self.store = store
        if let saved, saved.config == config {
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

    func newGame() {
        puzzle = nil
        values = [Int](repeating: 0, count: Sudoku.cellCount)
        notes = [Set<Int>](repeating: [], count: Sudoku.cellCount)
        mistakes = 0
        hintsUsed = 0
        elapsed = 0
        isComplete = false
        selected = nil
        notesMode = false
        activeHint = nil
        undoStack = []

        let difficulty = config.difficulty
        let seed = config.seed
        Task {
            let made = await Task.detached(priority: .userInitiated) {
                PuzzleGenerator.generate(difficulty: difficulty, seed: seed)
            }.value
            self.start(with: made)
        }
    }

    private func start(with puzzle: Puzzle) {
        self.puzzle = puzzle
        values = puzzle.givens
        saveProgress()
    }

    // MARK: Questions the views ask

    var hintsLeft: Int? {
        config.maxHints.map { max(0, $0 - hintsUsed) }
    }

    var canUseHint: Bool {
        !isComplete && !isLoading && (hintsLeft ?? 1) > 0
    }

    var stars: Int {
        if hintsUsed == 0 && mistakes <= 1 { return 3 }
        if hintsUsed <= 2 && mistakes <= 4 { return 2 }
        return 1
    }

    var showsCandidateHelp: Bool { config.mode == .learn }

    func isGiven(_ i: Int) -> Bool { (puzzle?.givens[i] ?? 0) != 0 }

    func isWrong(_ i: Int) -> Bool {
        guard let puzzle, values[i] != 0 else { return false }
        return values[i] != puzzle.solution[i]
    }

    /// How many more times each digit still needs to be placed.
    func remaining(_ digit: Int) -> Int {
        guard let puzzle else { return 9 }
        let placed = (0..<Sudoku.cellCount).filter { values[$0] == digit && puzzle.solution[$0] == digit }.count
        return 9 - placed
    }

    /// Digits that don't clash with anything for the selected cell (Learn mode helper).
    var allowedForSelection: Set<Int>? {
        guard let i = selected, !isGiven(i) else { return nil }
        var grid = values
        grid[i] = 0
        // Ignore wrong numbers so they don't block the right answer.
        if let puzzle {
            for j in 0..<Sudoku.cellCount where grid[j] != 0 && grid[j] != puzzle.solution[j] { grid[j] = 0 }
        }
        return Set(Sudoku.digits(in: Sudoku.candidateMask(grid, i)))
    }

    func cellState(_ i: Int) -> CellState {
        let value = values[i]
        var highlight = CellState.Highlight.none
        if let hint = activeHint, hint.focusCells.contains(i) {
            highlight = .hintFocus
        } else if let s = selected {
            let selectedValue = values[s]
            if selectedValue != 0 && value == selectedValue {
                highlight = .sameNumber
            } else if Sudoku.areRelated(s, i) {
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
        guard !isComplete else { return }
        selected = i
        Haptics.tap()
    }

    func enter(_ digit: Int) {
        guard let i = selected, let puzzle, !isComplete, !isGiven(i) else { return }

        if notesMode {
            guard values[i] == 0 else { return }
            pushUndo()
            if notes[i].contains(digit) { notes[i].remove(digit) } else { notes[i].insert(digit) }
            Haptics.tap()
            saveProgress()
            return
        }

        guard values[i] != digit else { return }
        pushUndo()
        values[i] = digit
        notes[i] = []

        if digit == puzzle.solution[i] {
            clearNotes(of: digit, around: i)
            Haptics.tap()
        } else {
            mistakes += 1
            Haptics.oops()
        }

        if activeHint?.cell == i { activeHint = nil }
        checkForWin()
        saveProgress()
    }

    func erase() {
        guard let i = selected, !isComplete, !isGiven(i) else { return }
        guard values[i] != 0 || !notes[i].isEmpty else { return }
        pushUndo()
        values[i] = 0
        notes[i] = []
        if activeHint?.isMistake == true && activeHint?.cell == i { activeHint = nil }
        Haptics.tap()
        saveProgress()
    }

    func undo() {
        guard !isComplete, let last = undoStack.popLast() else { return }
        values = last.values
        notes = last.notes
        activeHint = nil
        Haptics.tap()
        saveProgress()
    }

    func toggleNotes() {
        notesMode.toggle()
        Haptics.tap()
    }

    func requestHint() {
        guard canUseHint, let puzzle else { return }
        guard let hint = HintEngine.hint(values: values, puzzle: puzzle) else { return }
        if !hint.isMistake { hintsUsed += 1 }
        activeHint = hint
        selected = hint.cell
        Haptics.tap()
        saveProgress()
    }

    /// Does what the hint suggests: fills in the answer, or erases a wrong number.
    func applyHint() {
        guard let hint = activeHint, let puzzle, !isComplete else { return }
        pushUndo()
        if hint.isMistake {
            values[hint.cell] = 0
        } else {
            values[hint.cell] = puzzle.solution[hint.cell]
            clearNotes(of: hint.value, around: hint.cell)
        }
        notes[hint.cell] = []
        activeHint = nil
        selected = hint.cell
        checkForWin()
        saveProgress()
    }

    func dismissHint() {
        activeHint = nil
    }

    func tick() {
        guard !isLoading, !isComplete else { return }
        elapsed += 1
        if elapsed % 5 == 0 { saveProgress() }
    }

    // MARK: Internals

    private func pushUndo() {
        undoStack.append((values, notes))
        if undoStack.count > 200 { undoStack.removeFirst() }
    }

    private func clearNotes(of digit: Int, around i: Int) {
        for p in Sudoku.peers[i] { notes[p].remove(digit) }
    }

    private func checkForWin() {
        guard let puzzle, values == puzzle.solution else { return }
        isComplete = true
        selected = nil
        activeHint = nil
        Haptics.success()
        store.recordWin(config: config, seconds: elapsed, stars: stars)
    }

    private func saveProgress() {
        guard let puzzle, !isComplete else { return }
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
