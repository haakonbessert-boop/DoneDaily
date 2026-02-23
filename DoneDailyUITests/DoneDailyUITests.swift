import XCTest

final class DoneDailyUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCreateAndToggleHabitFlow() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-uitest_skip_onboarding")
        app.launch()

        app.tabBars.buttons["Habits"].tap()
        app.buttons["add_habit_fab"].tap()

        let nameField = app.textFields["habit_name_field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("UI Test Habit")

        app.buttons["save_habit_button"].tap()

        app.tabBars.buttons["Heute"].tap()
        XCTAssertTrue(app.staticTexts["UI Test Habit"].waitForExistence(timeout: 2))
    }

    func testOnboardingSeedsStarterHabits() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-uitest_reset_defaults")
        app.launch()

        XCTAssertTrue(app.buttons["Loslegen"].waitForExistence(timeout: 2))
        app.buttons["Loslegen"].tap()

        app.tabBars.buttons["Heute"].tap()
        XCTAssertTrue(app.staticTexts["10 Minuten Lesen"].waitForExistence(timeout: 3))
    }

    func testArchivedHabitMovesOutOfDefaultList() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-uitest_skip_onboarding")
        app.launch()

        app.tabBars.buttons["Habits"].tap()
        app.buttons["add_habit_fab"].tap()
        let nameField = app.textFields["habit_name_field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Archiv Test")
        app.buttons["save_habit_button"].tap()

        app.staticTexts["Archiv Test"].tap()
        let archiveSwitch = app.switches["Archiviert"]
        XCTAssertTrue(archiveSwitch.waitForExistence(timeout: 2))
        archiveSwitch.tap()
        app.navigationBars.buttons["Speichern"].tap()

        XCTAssertFalse(app.staticTexts["Archiv Test"].exists)
    }
}
