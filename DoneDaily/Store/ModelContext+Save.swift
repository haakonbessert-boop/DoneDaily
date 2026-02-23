import SwiftData

extension ModelContext {
    func saveIfNeeded() {
        guard hasChanges else { return }
        do {
            try save()
        } catch {
            assertionFailure("SwiftData save failed: \(error)")
        }
    }
}
