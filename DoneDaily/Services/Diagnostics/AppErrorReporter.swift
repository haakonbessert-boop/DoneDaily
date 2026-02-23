import Foundation
import OSLog

enum AppErrorReporter {
    private static let logger = Logger(subsystem: "com.haakon.DoneDaily", category: "app")

    static func report(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
