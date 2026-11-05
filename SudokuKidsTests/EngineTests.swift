import XCTest
@testable import SudokuKids

final class EngineTests: XCTestCase {

    func testEveryLevelMakesAValidPuzzleWithOneSolution() {
        for level in Difficulty.allCases {
            let puzzle = PuzzleGenerator.generate(difficulty: level, seed: 42)
            XCTAssertTrue(Sudoku.isSolved(puzzle.solution), "\(level) solution is not a valid grid")
            XCTAssertEqual(SudokuSolver.countSolutions(puzzle.givens, limit: 2), 1, "\(level) has more than one answer")
            XCTAssertLessThanOrEqual(puzzle.clueCount, level.targetClues + 2, "\(level) has too many clues")
            for i in 0..<81 where puzzle.givens[i] != 0 {
                XCTAssertEqual(puzzle.givens[i], puzzle.solution[i])
            }
        }
    }

    func testEasyAndMediumCanBeSolvedWithBeginnerSteps() {
        for level in [Difficulty.easy, .medium] {
            for seed in UInt64(1)...5 {
                let puzzle = PuzzleGenerator.generate(difficulty: level, seed: seed)
                XCTAssertTrue(LogicSolver.solvableWithSingles(puzzle.givens), "\(level) seed \(seed)")
            }
        }
    }

    func testSameSeedGivesSamePuzzle() {
        let a = PuzzleGenerator.generate(difficulty: .medium, seed: 20261105)
        let b = PuzzleGenerator.generate(difficulty: .medium, seed: 20261105)
        XCTAssertEqual(a, b)
    }

    func testDailyConfigIsStableForADay() {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        XCTAssertEqual(GameConfig.daily(on: date), GameConfig.daily(on: date))
        XCTAssertEqual(GameConfig.daily(on: date).mode, .daily)
    }

    func testSolverSolvesPuzzle() {
        let puzzle = PuzzleGenerator.generate(difficulty: .hard, seed: 7)
        XCTAssertEqual(SudokuSolver.solve(puzzle.givens), puzzle.solution)
    }

    func testHintFillsTheLastEmptyCell() {
        let puzzle = PuzzleGenerator.generate(difficulty: .easy, seed: 3)
        var values = puzzle.solution
        values[40] = 0
        let hint = HintEngine.hint(values: values, puzzle: puzzle)
        XCTAssertEqual(hint?.cell, 40)
        XCTAssertEqual(hint?.value, puzzle.solution[40])
        XCTAssertEqual(hint?.kind, Hint.Kind.onlyNumberLeft)
    }

    func testHintPointsOutMistakesFirst() {
        let puzzle = PuzzleGenerator.generate(difficulty: .easy, seed: 9)
        var values = puzzle.givens
        let empty = values.firstIndex(of: 0)!
        values[empty] = puzzle.solution[empty] % 9 + 1 // always wrong
        let hint = HintEngine.hint(values: values, puzzle: puzzle)
        XCTAssertEqual(hint?.cell, empty)
        XCTAssertEqual(hint?.kind, Hint.Kind.mistake)
    }

    func testHintIsAlwaysCorrect() {
        let puzzle = PuzzleGenerator.generate(difficulty: .medium, seed: 11)
        var values = puzzle.givens
        var steps = 0
        while values.contains(0), let hint = HintEngine.hint(values: values, puzzle: puzzle) {
            XCTAssertEqual(hint.value, puzzle.solution[hint.cell])
            values[hint.cell] = hint.value
            steps += 1
        }
        XCTAssertEqual(values, puzzle.solution)
        XCTAssertGreaterThan(steps, 0)
    }

    @MainActor
    func testDailyStreakCountsConsecutiveDays() {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let store = ProgressStore(defaults: defaults)
        let calendar = Calendar.current
        let today = Date()
        for back in 0..<3 {
            let day = calendar.date(byAdding: .day, value: -back, to: today)!
            store.recordWin(config: .daily(on: day), seconds: 100, stars: 3)
        }
        XCTAssertEqual(store.dailyStreak(today: today), 3)
        XCTAssertEqual(store.stats.totalStars, 9)
    }
}
