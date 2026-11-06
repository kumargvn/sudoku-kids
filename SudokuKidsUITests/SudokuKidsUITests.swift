import XCTest

/// Drives the real app through its typical flow — launch, resume a saved puzzle,
/// use a hint, finish the puzzle, see the win screen — so a simulator screen
/// recording can be captured for an App Store review request. Not part of the
/// normal test suite; run by hand (or by the "App Store listing" workflow) while
/// `xcrun simctl io <udid> recordVideo` is capturing the simulator's screen.
///
/// A UI test bundle runs as its own process and talks to the app only through the
/// accessibility tree, so this intentionally avoids depending on any app-internal
/// types: it only taps elements by their accessibility identifier/label, and uses
/// the app's own "Show me" hint action (applied twice) to finish the puzzle rather
/// than computing the solution itself.
final class SudokuKidsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testRecordAppReviewDemo() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-screenshot", "record"]
        app.launch()

        // Home screen: let it sit on camera for a moment before moving on.
        let continueCard = app.buttons["continueCard"]
        XCTAssertTrue(continueCard.waitForExistence(timeout: 15))
        Thread.sleep(forTimeInterval: 2.5)
        continueCard.tap()

        // Game screen: the saved puzzle is two moves from done. Use the hint
        // flow to fill them in, one at a time.
        for _ in 0..<2 {
            let hintButton = app.buttons["tool_hint"]
            XCTAssertTrue(hintButton.waitForExistence(timeout: 15))
            Thread.sleep(forTimeInterval: 1.5)
            hintButton.tap()

            let showMe = app.buttons["Show me"]
            XCTAssertTrue(showMe.waitForExistence(timeout: 10))
            Thread.sleep(forTimeInterval: 2)
            showMe.tap()
            Thread.sleep(forTimeInterval: 1)
        }

        // Win screen with confetti — hold here so the recording captures it.
        Thread.sleep(forTimeInterval: 4)
    }
}
