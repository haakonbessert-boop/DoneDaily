import XCTest
@testable import DoneDaily

final class DataExportServiceTests: XCTestCase {
    func testCSVContainsHeaderAndEscapedName() {
        let record = HabitExportRecord(
            id: "id-1",
            name: "Lesen \"Deep Work\"",
            iconName: "book.fill",
            color: "blue",
            category: "Lernen",
            categoryRawValue: "learning",
            notes: "10 Minuten",
            groupName: "Fokus",
            targetPerWeek: 5,
            trackingType: "count",
            dailyTarget: 8,
            sortOrder: 1,
            streak: 2,
            archived: false,
            paused: false,
            reminderEnabled: true,
            reminderPattern: "daily",
            reminderMissedDaysThreshold: 2,
            reminderHour: 19,
            reminderMinute: 30,
            reminderWeekdays: [1, 2, 3]
        )

        let csv = DataExportService.makeCSV([record])
        XCTAssertTrue(csv.contains("id,name,group,category,target_per_week,daily_target,tracking,streak,archived,paused,reminder_enabled,color,pattern"))
        XCTAssertTrue(csv.contains("\"Lesen \"\"Deep Work\"\"\""))
        XCTAssertTrue(csv.contains("\"Fokus\""))
    }
}
