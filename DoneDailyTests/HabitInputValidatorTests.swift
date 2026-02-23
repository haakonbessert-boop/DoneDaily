import XCTest
@testable import DoneDaily

final class HabitInputValidatorTests: XCTestCase {
    func testCanSaveWithTrimmedNameAndNoReminder() {
        XCTAssertTrue(HabitInputValidator.canSave(name: "  Lesen  ", reminderEnabled: false, reminderWeekdays: []))
    }

    func testCannotSaveWithoutName() {
        XCTAssertFalse(HabitInputValidator.canSave(name: "   ", reminderEnabled: false, reminderWeekdays: []))
    }

    func testCannotSaveWhenReminderEnabledWithoutWeekdays() {
        XCTAssertFalse(HabitInputValidator.canSave(name: "Workout", reminderEnabled: true, reminderWeekdays: []))
    }

    func testNormalizedNameTrimsWhitespace() {
        XCTAssertEqual(HabitInputValidator.normalizedName("  Fokus  "), "Fokus")
    }
}
