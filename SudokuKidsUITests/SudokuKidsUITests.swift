import XCTest
@testable import SudokuKids

/// Drives the real app through its typical flow — launch, resume a saved puzzle,
/// use a hint, finish the puzzle, see the win screen — so a simulator screen
/// recording can be captured for an App Store review request. Not part of the
/// normal test suite; run by hand (or by the "App Store listing" workflow) while
/// `xcrun simctl io <udid> recordVideo` is capturing the simulator's screen.
final class SudokuKidsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testRecordAppReviewDemo() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-screenshot", "record"]
        app.launch()

        // Home screen: let it sit on camera for a moment before moving on.
        let continueCard = app.buttons["continueCard"]
        XCTAssertTrue(continueCard.waitForExistence(timeout: 15))
        Thread.sleep(forTimeInterval: 2.5)
        continueCard.tap()

        // Game screen: the saved puzzle is one move from done; a cell is already
        // selected. Show the hint flow.
        let hintButton = app.buttons["tool_hint"]
        XCTAssertTrue(hintButton.waitForExistence(timeout: 15))
        Thread.sleep(forTimeInterval: 1.5)
        hintButton.tap()

        let showMe = app.buttons["Show me"]
        XCTAssertTrue(showMe.waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 2)
        showMe.tap()

        // One square now remains empty. Find it from its accessibility label
        // ("Row R, column C, empty"), work out its solution digit from the same
        // seeded puzzle the app generated, and tap it in.
        Thread.sleep(forTimeInterval: 1.5)
        let emptyCellPredicate = NSPredicate(format: "label CONTAINS[c] 'empty'")
        let emptyCell = app.buttons.matching(emptyCellPredicate).firstMatch
        XCTAssertTrue(emptyCell.waitForExistence(timeout: 10))

        let label = emptyCell.label
        let numbers = label.split(separator: ",").compactMap { part -> Int? in
            Int(part.filter(\.isNumber))
        }
        XCTAssertEqual(numbers.count, 2, "Expected 'Row R, column C, empty', got: \(label)")
        let row = numbers[0] - 1
        let col = numbers[1] - 1
        let index = row * 9 + col

        let config = DemoMode.recordConfig
        let puzzle = PuzzleGenerator.generate(size: config.size, difficulty: config.difficulty, seed: config.seed)
        let digit = puzzle.solution[index]

        emptyCell.tap()
        Thread.sleep(forTimeInterval: 1)
        let digitButton = app.buttons["numpad_\(digit)"]
        XCTAssertTrue(digitButton.waitForExistence(timeout: 5))
        digitButton.tap()

        // Win screen with confetti — hold here so the recording captures it.
        Thread.sleep(forTimeInterval: 4)
    }
}
