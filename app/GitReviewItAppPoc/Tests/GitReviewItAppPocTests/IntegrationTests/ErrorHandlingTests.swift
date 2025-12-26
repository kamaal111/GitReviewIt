import Foundation
import Testing

@testable import GitReviewItAppPoc

/// Integration tests for error handling scenarios across the app.
@MainActor
struct ErrorHandlingTests {

    // MARK: - Test Helpers

    private func makeAuthContainer(
        mockAPI: MockGitHubAPI = MockGitHubAPI(),
        mockStorage: MockCredentialStorage = MockCredentialStorage()
    ) -> (AuthenticationContainer, MockGitHubAPI) {
        let container = AuthenticationContainer(
            githubAPI: mockAPI,
            credentialStorage: mockStorage
        )
        return (container, mockAPI)
    }

    private func makePRContainer(
        mockAPI: MockGitHubAPI = MockGitHubAPI(),
        mockStorage: MockCredentialStorage = MockCredentialStorage()
    ) -> (PullRequestListContainer, MockGitHubAPI, MockCredentialStorage) {
        let container = PullRequestListContainer(
            githubAPI: mockAPI,
            credentialStorage: mockStorage
        )
        return (container, mockAPI, mockStorage)
    }

    // MARK: - T082: Network Failure Error Display

    @Test
    func `Network failure shows network unreachable error`() async throws {
        // Arrange
        let (container, mockAPI) = makeAuthContainer()

        // Mock GitHubAPI to throw networkUnreachable directly or map it
        // We simulate what GitHubAPIClient would return
        mockAPI.fetchUserErrorToThrow = APIError.networkUnreachable

        // Act
        await container.validateAndSaveCredentials(token: "ghp_test")

        // Assert
        #expect(container.error == .networkUnreachable, "Should display network unreachable error")
    }

    // MARK: - T083: Rate Limit Error

    @Test
    func `Rate limit error displays reset time`() async throws {
        // Arrange
        let (container, mockAPI) = makeAuthContainer()

        let resetDate = Date().addingTimeInterval(3600)  // 1 hour later
        mockAPI.fetchUserErrorToThrow = APIError.rateLimitExceeded(resetAt: resetDate)

        // Act
        await container.validateAndSaveCredentials(token: "ghp_test")

        // Assert
        #expect(container.error == .rateLimitExceeded(resetAt: resetDate))

        // Check description (indirectly testing localizedDescription)
        let errorDescription = container.error?.localizedDescription ?? ""
        #expect(errorDescription.contains("rate limit"), "Description should mention rate limit")
    }

    // MARK: - T084: Invalid Response Error Handling

    @Test
    func `Invalid response handling displays correct error`() async throws {
        // Arrange
        let (container, mockAPI) = makeAuthContainer()

        mockAPI.fetchUserErrorToThrow = APIError.invalidResponse

        // Act
        await container.validateAndSaveCredentials(token: "ghp_test")

        // Assert
        #expect(container.error == .invalidResponse)
        #expect(container.error?.localizedDescription.contains("invalid response") == true)
    }

    // MARK: - T085: Retry Functionality

    @Test
    func `Retry functionality succeeds after transient error`() async throws {
        // Arrange
        let (container, mockAPI, mockStorage) = makePRContainer()

        // Pre-store valid token
        try await mockStorage.store(
            GitHubCredentials(token: "ghp_test", baseURL: "https://api.github.com"))

        // Setup success response
        let pr = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 1,
            title: "Test PR",
            authorLogin: "user",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/1")!
        )
        mockAPI.pullRequestsToReturn = [pr]

        // First attempt fails with server error (transient)
        mockAPI.fetchReviewRequestsErrorToThrow = APIError.serverError(statusCode: 500)

        // Act 1: Load fails
        await container.loadPullRequests()

        // Assert 1
        #expect(
            container.loadingState == .failed(.serverError(statusCode: 500)),
            "State should be failed with 500 error")

        // Setup success for retry (clear error)
        mockAPI.fetchReviewRequestsErrorToThrow = nil

        // Act 2: Retry
        await container.retry()

        // Assert 2
        guard case .loaded(let prs) = container.loadingState else {
            Issue.record("Expected loaded state after retry")
            return
        }
        #expect(prs.count == 1, "Should have 1 PR after retry")
        #expect(prs[0].repositoryOwner == "owner", "PR should match")
    }

    // MARK: - T052: Rate Limit Handling with Metadata Enrichment

    @Test
    func `Rate limit during metadata enrichment does not block PR list`() async throws {
        let (container, mockAPI, mockStorage) = makePRContainer()

        // Pre-store valid token
        try await mockStorage.store(
            GitHubCredentials(token: "ghp_test", baseURL: "https://api.github.com")
        )

        // Setup PR list to succeed
        let pr1 = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 1,
            title: "Test PR 1",
            authorLogin: "user",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/1")!,
            commentCount: 5,
            labels: []
        )
        let pr2 = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 2,
            title: "Test PR 2",
            authorLogin: "user",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/2")!,
            commentCount: 3,
            labels: []
        )
        mockAPI.pullRequestsToReturn = [pr1, pr2]

        // Setup metadata fetch to fail with rate limit
        let resetDate = Date().addingTimeInterval(3600)
        mockAPI.fetchPRDetailsErrorToThrow = APIError.rateLimitExceeded(resetAt: resetDate)

        // Act: Load PRs (metadata enrichment will fail)
        await container.loadPullRequests()

        // Assert: PR list should still be loaded despite metadata failures
        guard case .loaded(let prs) = container.loadingState else {
            Issue.record("Expected loaded state even with metadata failures")
            return
        }

        #expect(prs.count == 2, "Should have 2 PRs")
        #expect(prs[0].commentCount == 5, "Comment counts from Search API should be available")
        #expect(prs[1].commentCount == 3, "Comment counts from Search API should be available")

        // Metadata should be nil since enrichment failed
        #expect(prs[0].previewMetadata == nil, "Metadata should be nil when enrichment fails")
        #expect(prs[1].previewMetadata == nil, "Metadata should be nil when enrichment fails")
    }

    // MARK: - T053: Graceful Degradation when Individual PR Metadata Fails

    @Test
    func `PR list displays correctly when some metadata enrichment fails`() async throws {
        let (container, mockAPI, mockStorage) = makePRContainer()

        // Pre-store valid token
        try await mockStorage.store(
            GitHubCredentials(token: "ghp_test", baseURL: "https://api.github.com")
        )

        // Setup PR list
        let pr1 = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 1,
            title: "Test PR 1",
            authorLogin: "user",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/1")!,
            commentCount: 5,
            labels: []
        )
        let pr2 = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 2,
            title: "Test PR 2",
            authorLogin: "user",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/2")!,
            commentCount: 3,
            labels: []
        )
        mockAPI.pullRequestsToReturn = [pr1, pr2]

        // Setup metadata: first PR succeeds, second fails
        mockAPI.mockPRDetailsResponses = [
            "owner/repo#1": .success(
                PRPreviewMetadata(
                    additions: 100,
                    deletions: 50,
                    changedFiles: 5,
                    requestedReviewers: [],
                    completedReviewers: []
                )
            ),
            "owner/repo#2": .failure(APIError.notFound),
        ]

        // Act
        await container.loadPullRequests()

        // Assert
        guard case .loaded(let prs) = container.loadingState else {
            Issue.record("Expected loaded state")
            return
        }

        #expect(prs.count == 2)

        // First PR should have metadata
        #expect(prs[0].previewMetadata != nil, "First PR metadata should be loaded")
        #expect(prs[0].previewMetadata?.additions == 100)

        // Second PR should not have metadata but still be in the list
        #expect(prs[1].previewMetadata == nil, "Second PR metadata should be nil")
        #expect(prs[1].commentCount == 3, "Comment count should still be available")
    }
}
