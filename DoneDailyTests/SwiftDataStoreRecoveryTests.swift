import XCTest
@testable import DoneDaily

final class SwiftDataStoreRecoveryTests: XCTestCase {
    func testIdentifiesKnownStoreArtifacts() {
        XCTAssertTrue(SwiftDataStoreRecovery.isLikelyStoreArtifact("default.store"))
        XCTAssertTrue(SwiftDataStoreRecovery.isLikelyStoreArtifact("default.store-shm"))
        XCTAssertTrue(SwiftDataStoreRecovery.isLikelyStoreArtifact("default.sqlite"))
        XCTAssertTrue(SwiftDataStoreRecovery.isLikelyStoreArtifact("default.sqlite-wal"))
        XCTAssertFalse(SwiftDataStoreRecovery.isLikelyStoreArtifact("notes.txt"))
    }
}
