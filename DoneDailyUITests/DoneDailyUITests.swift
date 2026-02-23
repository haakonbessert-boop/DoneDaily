import XCTest

final class DoneDailyUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCreateAndToggleHabitFlow() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Habits"].tap()
        app.navigationBars.buttons["Neuer Habit"].tap()

        let nameField = app.textFields["Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("UI Test Habit")

        app.navigationBars.buttons["Speichern"].tap()

        app.tabBars.buttons["Heute"].tap()
        XCTAssertTrue(app.staticTexts["UI Test Habit"].waitForExistence(timeout: 2))
    }
}
