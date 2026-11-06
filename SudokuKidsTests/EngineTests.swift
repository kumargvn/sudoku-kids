import XCTest
@testable import SudokuKids

final class EngineTests: XCTestCase {

    func testGeometryForEverySize() {
        for size in GridSize.allCases {
            let geo = size.geometry
            XCTAssertEqual(geo.count, size.n * size.n)
            XCTAssertEqual(geo.units.count, size.n * 3)
            for unit in geo.units { XCTAssertEqual(Set(unit.cells).count, size.n) }
            // Every cell is in exactly one box.
            XCTAssertEqual(Set(geo.boxes.flatMap { $0 }).count, geo.count)
            for i in 0..<geo.count { XCTAssertTrue(geo.boxes[geo.box(i)].contains(i)) }
        }
        XCTAssertEqual(Geometry.six.boxes[0], [0, 1, 2, 6, 7, 8])
    }

    func testEverySizeAndLevelMakesAPuzzleWithOneAnswer() {
        for size in GridSize.allCases {
            let geo = size.geometry
            for level in Difficulty.allCases {
                let puzzle = PuzzleGenerator.generate(size: size, difficulty: level, seed: 42)
                XCTAssertTrue(geo.isSolved(puzzle.solution), "\(size) \(level) solution is not valid")
                XCTAssertEqual(SudokuSolver.countSolutions(puzzle.givens, geo: geo, limit: 2), 1, "\(size) \(level) has more than one answer")
                XCTAssertLessThanOrEqual(puzzle.clueCount, level.targetClues(for: size) + 2)
                for i in 0..<geo.count where puzzle.givens[i] != 0 {
                    XCTAssertEqual(puzzle.givens[i], puzzle.solution[i])
                }
            }
        }
    }

    func testLevelsMatchTheTechniquesTheHintsTeach() {
        for seed in UInt64(1)...4 {
            let easy = PuzzleGenerator.generate(size: .nine, difficulty: .medium, seed: seed)
            XCTAssertTrue(LogicSolver.isSolvable(easy.givens, geo: .nine, allowEliminations: false))
            let hard = PuzzleGenerator.generate(size: .nine, difficulty: .hard, seed: seed)
            XCTAssertTrue(LogicSolver.isSolvable(hard.givens, geo: .nine, allowEliminations: true))
        }
    }

    func testSameSeedGivesSamePuzzle() {
        let a = PuzzleGenerator.generate(size: .six, difficulty: .medium, seed: 20261105)
        let b = PuzzleGenerator.generate(size: .six, difficulty: .medium, seed: 20261105)
        XCTAssertEqual(a, b)
    }

    func testEveryHintIsCorrectAllTheWayThrough() {
        for size in GridSize.allCases {
            let puzzle = PuzzleGenerator.generate(size: size, difficulty: .hard, seed: 11)
            var values = puzzle.givens
            var steps = 0
            while values.contains(0), let hint = HintEngine.hint(values: values, puzzle: puzzle, symbols: .animals) {
                XCTAssertEqual(hint.value, puzzle.solution[hint.cell])
                XCTAssertFalse(hint.message.isEmpty)
                values[hint.cell] = hint.value
                steps += 1
                if steps > 100 { break }
            }
            XCTAssertEqual(values, puzzle.solution)
        }
    }

    func testHintPointsOutMistakesFirst() {
        let puzzle = PuzzleGenerator.generate(size: .nine, difficulty: .easy, seed: 9)
        var values = puzzle.givens
        let empty = values.firstIndex(of: 0)!
        values[empty] = puzzle.solution[empty] % 9 + 1 // always wrong
        let hint = HintEngine.hint(values: values, puzzle: puzzle, symbols: .numbers)
        XCTAssertEqual(hint?.cell, empty)
        XCTAssertEqual(hint?.kind, Hint.Kind.mistake)
    }

    func testHintsSpeakPictureNames() {
        let puzzle = PuzzleGenerator.generate(size: .four, difficulty: .easy, seed: 3)
        var values = puzzle.solution
        values[5] = 0
        let hint = HintEngine.hint(values: values, puzzle: puzzle, symbols: .animals)!
        XCTAssertTrue(hint.message.contains(SymbolSet.animals.display(puzzle.solution[5])))
        XCTAssertTrue(hint.spoken.contains(SymbolSet.animals.spoken(puzzle.solution[5])))
    }

    func testLessonsFindExamplesForEveryTechnique() {
        for technique in Technique.allCases {
            let example = LessonBuilder.example(for: technique, seed: 12345)
            XCTAssertNotNil(example, "No example for \(technique)")
            if let example {
                XCTAssertEqual(example.hint.technique, technique)
                XCTAssertEqual(example.hint.value, example.puzzle.solution[example.hint.cell])
                XCTAssertTrue(example.choices.contains(example.hint.value))
                XCTAssertEqual(example.choices.count, 3)
            }
        }
    }

    func testAdventureUnlocksInOrder() {
        let levels = Adventure.allLevels
        XCTAssertEqual(levels.count, 30)
        XCTAssertTrue(Adventure.isUnlocked(levels[0], completed: []))
        XCTAssertFalse(Adventure.isUnlocked(levels[1], completed: []))
        XCTAssertTrue(Adventure.isUnlocked(levels[1], completed: [levels[0].id]))
        XCTAssertEqual(levels[0].seed, levels[0].seed)
        XCTAssertNotEqual(levels[0].seed, levels[1].seed)
    }

    @MainActor
    func testWinsAwardTrophiesOnce() {
        let store = ProgressStore(defaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)
        let first = store.recordWin(config: .classic(.easy, size: .four), seconds: 60, stars: 3, mistakes: 0, hintsUsed: 0)
        XCTAssertTrue(first.contains { $0.id == "first" })
        XCTAssertTrue(first.contains { $0.id == "tiny" })
        XCTAssertTrue(first.contains { $0.id == "perfect" })
        let second = store.recordWin(config: .classic(.easy, size: .four), seconds: 50, stars: 3, mistakes: 0, hintsUsed: 0)
        XCTAssertFalse(second.contains { $0.id == "first" })
        XCTAssertEqual(store.stats.bestTimes[PlayerStats.key(.four, .easy)], 50)
    }

    @MainActor
    func testProfilesKeepSeparateProgress() {
        let store = ProgressStore(defaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)
        _ = store.recordWin(config: .classic(.easy, size: .nine), seconds: 100, stars: 2, mistakes: 1, hintsUsed: 1)
        let firstID = store.activeID
        store.addProfile(name: "Maya", avatar: "🐼")
        XCTAssertEqual(store.profile.name, "Maya")
        XCTAssertEqual(store.stats.totalStars, 0)
        store.switchTo(firstID)
        XCTAssertEqual(store.stats.totalStars, 2)
    }

    @MainActor
    func testDailyStreakCountsConsecutiveDays() {
        let store = ProgressStore(defaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)
        let today = Date()
        for back in 0..<3 {
            let day = Calendar.current.date(byAdding: .day, value: -back, to: today)!
            _ = store.recordWin(config: .daily(on: day), seconds: 100, stars: 3, mistakes: 0, hintsUsed: 0)
        }
        XCTAssertEqual(store.dailyStreak(today: today), 3)
        XCTAssertTrue(store.stats.trophies.contains("streak3"))
    }
}
