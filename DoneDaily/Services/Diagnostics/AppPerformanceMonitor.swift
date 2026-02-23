import Foundation
import OSLog

enum AppPerformanceMonitor {
    private static let logger = Logger(subsystem: "com.haakon.DoneDaily", category: "performance")
    private static var launchStart = Date()
    private static var firstRenderReported = false

    static func markLaunchStart() {
        launchStart = Date()
    }

    static func markFirstRender() {
        guard !firstRenderReported else { return }
        firstRenderReported = true
        let millis = Date().timeIntervalSince(launchStart) * 1000
        logger.info("App first render in \(millis, format: .fixed(precision: 0)) ms")
    }

    static func measure<T>(_ name: String, _ block: () -> T) -> T {
        let start = Date()
        let result = block()
        let millis = Date().timeIntervalSince(start) * 1000
        logger.info("\(name, privacy: .public) finished in \(millis, format: .fixed(precision: 0)) ms")
        return result
    }
}
