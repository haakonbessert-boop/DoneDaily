import SwiftData

extension ModelContext {
    @discardableResult
    func saveIfNeeded() -> Bool {
        guard hasChanges else { return true }
        do {
            try save()
            return true
        } catch {
            AppErrorReporter.report("SwiftData save failed: \(error)")
            return false
        }
    }
}
