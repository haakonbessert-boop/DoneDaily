import Foundation

enum SwiftDataStoreRecovery {
    static func deleteLikelyStoreFiles(in directory: URL) throws {
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        for url in contents where isLikelyStoreArtifact(url.lastPathComponent) {
            try? fileManager.removeItem(at: url)
        }
    }

    static func isLikelyStoreArtifact(_ fileName: String) -> Bool {
        let lowered = fileName.lowercased()
        let knownPrefixes = [
            "default.store",
            "default.sqlite"
        ]

        return knownPrefixes.contains(where: { lowered.hasPrefix($0) }) ||
            lowered.hasSuffix(".sqlite") ||
            lowered.hasSuffix(".sqlite-shm") ||
            lowered.hasSuffix(".sqlite-wal")
    }
}
