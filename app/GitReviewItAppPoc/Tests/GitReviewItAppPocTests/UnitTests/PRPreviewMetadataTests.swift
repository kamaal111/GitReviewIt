import Foundation
import Testing

@testable import GitReviewItAppPoc

/// Unit tests for PRPreviewMetadata model validation and behavior
struct PRPreviewMetadataTests {

    // MARK: - Initialization Tests

    @Test
    func `PRPreviewMetadata initializes with valid values`() throws {
        let reviewer = Reviewer(login: "octocat", avatarURL: nil)
        let metadata = PRPreviewMetadata(
            additions: 145,
            deletions: 23,
            changedFiles: 7,
            requestedReviewers: [reviewer]
        )

        #expect(metadata.additions == 145)
        #expect(metadata.deletions == 23)
        #expect(metadata.changedFiles == 7)
        #expect(metadata.requestedReviewers.count == 1)
        #expect(metadata.requestedReviewers[0].login == "octocat")
    }

    @Test
    func `PRPreviewMetadata initializes with zero values`() {
        let metadata = PRPreviewMetadata(
            additions: 0,
            deletions: 0,
            changedFiles: 0,
            requestedReviewers: []
        )

        #expect(metadata.additions == 0)
        #expect(metadata.deletions == 0)
        #expect(metadata.changedFiles == 0)
        #expect(metadata.requestedReviewers.isEmpty)
    }

    @Test
    func `PRPreviewMetadata initializes with empty reviewers list`() {
        let metadata = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 2,
            requestedReviewers: []
        )

        #expect(metadata.requestedReviewers.isEmpty)
    }

    @Test
    func `PRPreviewMetadata initializes with multiple reviewers`() {
        let reviewer1 = Reviewer(login: "alice", avatarURL: nil)
        let reviewer2 = Reviewer(login: "bob", avatarURL: nil)
        let reviewer3 = Reviewer(login: "charlie", avatarURL: nil)

        let metadata = PRPreviewMetadata(
            additions: 100,
            deletions: 50,
            changedFiles: 10,
            requestedReviewers: [reviewer1, reviewer2, reviewer3]
        )

        #expect(metadata.requestedReviewers.count == 3)
        #expect(metadata.requestedReviewers[0].login == "alice")
        #expect(metadata.requestedReviewers[1].login == "bob")
        #expect(metadata.requestedReviewers[2].login == "charlie")
    }

    // MARK: - Validation Tests
    // Note: Precondition validation tests are omitted because preconditions cause
    // fatal errors that crash the test runner. In production, invalid inputs should
    // be prevented at the API boundary through proper input validation.

    // MARK: - Computed Properties Tests

    @Test
    func `totalChanges calculates sum of additions and deletions`() {
        let metadata = PRPreviewMetadata(
            additions: 145,
            deletions: 23,
            changedFiles: 7,
            requestedReviewers: []
        )

        #expect(metadata.totalChanges == 168)
    }

    @Test
    func `totalChanges returns zero when no changes`() {
        let metadata = PRPreviewMetadata(
            additions: 0,
            deletions: 0,
            changedFiles: 0,
            requestedReviewers: []
        )

        #expect(metadata.totalChanges == 0)
    }

    @Test
    func `totalChanges handles large values`() {
        let metadata = PRPreviewMetadata(
            additions: 5000,
            deletions: 3000,
            changedFiles: 100,
            requestedReviewers: []
        )

        #expect(metadata.totalChanges == 8000)
    }

    @Test
    func `hasRequestedReviewers returns false when empty`() {
        let metadata = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 2,
            requestedReviewers: []
        )

        #expect(metadata.hasRequestedReviewers == false)
    }

    @Test
    func `hasRequestedReviewers returns true when reviewers present`() {
        let reviewer = Reviewer(login: "octocat", avatarURL: nil)
        let metadata = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 2,
            requestedReviewers: [reviewer]
        )

        #expect(metadata.hasRequestedReviewers == true)
    }

    // MARK: - Equatable Tests

    @Test
    func `PRPreviewMetadata equality compares all fields`() {
        let reviewer1 = Reviewer(login: "alice", avatarURL: nil)
        let reviewer2 = Reviewer(login: "bob", avatarURL: nil)

        let metadata1 = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 2,
            requestedReviewers: [reviewer1]
        )

        let metadata2 = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 2,
            requestedReviewers: [reviewer1]
        )

        let metadata3 = PRPreviewMetadata(
            additions: 20,  // Different additions
            deletions: 5,
            changedFiles: 2,
            requestedReviewers: [reviewer1]
        )

        let metadata4 = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 2,
            requestedReviewers: [reviewer2]  // Different reviewer
        )

        #expect(metadata1 == metadata2)
        #expect(metadata1 != metadata3)
        #expect(metadata1 != metadata4)
    }

    @Test
    func `PRPreviewMetadata equality handles empty reviewers`() {
        let metadata1 = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 2,
            requestedReviewers: []
        )

        let metadata2 = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 2,
            requestedReviewers: []
        )

        #expect(metadata1 == metadata2)
    }

    // MARK: - Semantic State Tests

    @Test
    func `PRPreviewMetadata handles deletion-only PR`() {
        let metadata = PRPreviewMetadata(
            additions: 0,
            deletions: 100,
            changedFiles: 5,
            requestedReviewers: []
        )

        #expect(metadata.additions == 0)
        #expect(metadata.deletions == 100)
        #expect(metadata.totalChanges == 100)
    }

    @Test
    func `PRPreviewMetadata handles addition-only PR`() {
        let metadata = PRPreviewMetadata(
            additions: 100,
            deletions: 0,
            changedFiles: 5,
            requestedReviewers: []
        )

        #expect(metadata.additions == 100)
        #expect(metadata.deletions == 0)
        #expect(metadata.totalChanges == 100)
    }

    @Test
    func `PRPreviewMetadata handles single file change`() {
        let metadata = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 1,
            requestedReviewers: []
        )

        #expect(metadata.changedFiles == 1)
    }

    @Test
    func `PRPreviewMetadata handles large PR`() {
        let metadata = PRPreviewMetadata(
            additions: 10000,
            deletions: 5000,
            changedFiles: 250,
            requestedReviewers: []
        )

        #expect(metadata.additions == 10000)
        #expect(metadata.deletions == 5000)
        #expect(metadata.changedFiles == 250)
        #expect(metadata.totalChanges == 15000)
    }

    // MARK: - Sendable Tests

    @Test
    func `PRPreviewMetadata is Sendable and thread-safe`() {
        let reviewer = Reviewer(login: "octocat", avatarURL: nil)
        let metadata = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 2,
            requestedReviewers: [reviewer]
        )

        // This test verifies that PRPreviewMetadata conforms to Sendable
        // If this compiles, it proves thread-safety guarantees
        let _: any Sendable = metadata

        #expect(metadata.additions == 10)
    }
}
