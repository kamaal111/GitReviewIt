import Foundation
import Testing
@testable import GitReviewItApp

/// Integration tests for pull request preview metadata, specifically comment counts from Search API
@MainActor
struct PRPreviewMetadataIntegrationTests {
    private let mockGitHubAPI = MockGitHubAPI()
    private let mockCredentialStorage = MockCredentialStorage()
    private let container: PullRequestListContainer

    init() {
        self.container = PullRequestListContainer(
            githubAPI: mockGitHubAPI,
            credentialStorage: mockCredentialStorage,
            openURL: { _ in }
        )
    }

    // MARK: - Comment Count Tests

    @Test
    func `Search API returns comment counts for PRs with discussions`() async throws {
        // Given
        let credentials = GitHubCredentials(token: "token", baseURL: "https://api.github.com")
        mockCredentialStorage.preloadCredentials(credentials)

        let prWithComments = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 1,
            title: "PR with comments",
            authorLogin: "author",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/1")!,
            commentCount: 12
        )
        mockGitHubAPI.pullRequestsToReturn = [prWithComments]

        // When
        await container.loadPullRequests()

        // Then
        guard case .loaded(let prs) = container.loadingState else {
            Issue.record("Expected loaded state")
            return
        }
        #expect(prs.count == 1)
        #expect(prs[0].commentCount == 12)
    }

    @Test
    func `Search API returns zero for PRs with no comments`() async throws {
        // Given
        let credentials = GitHubCredentials(token: "token", baseURL: "https://api.github.com")
        mockCredentialStorage.preloadCredentials(credentials)

        let prWithoutComments = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 2,
            title: "PR without comments",
            authorLogin: "author",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/2")!,
            commentCount: 0
        )
        mockGitHubAPI.pullRequestsToReturn = [prWithoutComments]

        // When
        await container.loadPullRequests()

        // Then
        guard case .loaded(let prs) = container.loadingState else {
            Issue.record("Expected loaded state")
            return
        }
        #expect(prs.count == 1)
        #expect(prs[0].commentCount == 0)
    }

    @Test
    func `Search API handles mixed comment counts correctly`() async throws {
        // Given
        let credentials = GitHubCredentials(token: "token", baseURL: "https://api.github.com")
        mockCredentialStorage.preloadCredentials(credentials)

        let prNoComments = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 1,
            title: "PR 1",
            authorLogin: "author1",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/1")!,
            commentCount: 0
        )

        let prFewComments = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 2,
            title: "PR 2",
            authorLogin: "author2",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/2")!,
            commentCount: 5
        )

        let prManyComments = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 3,
            title: "PR 3",
            authorLogin: "author3",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/3")!,
            commentCount: 42
        )

        mockGitHubAPI.pullRequestsToReturn = [prNoComments, prFewComments, prManyComments]

        // When
        await container.loadPullRequests()

        // Then
        guard case .loaded(let prs) = container.loadingState else {
            Issue.record("Expected loaded state")
            return
        }
        #expect(prs.count == 3)
        #expect(prs[0].commentCount == 0)
        #expect(prs[1].commentCount == 5)
        #expect(prs[2].commentCount == 42)
    }

    @Test
    func `comment counts persist through reload`() async throws {
        // Given
        let credentials = GitHubCredentials(token: "token", baseURL: "https://api.github.com")
        mockCredentialStorage.preloadCredentials(credentials)

        let pr = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 1,
            title: "PR",
            authorLogin: "author",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/1")!,
            commentCount: 7
        )
        mockGitHubAPI.pullRequestsToReturn = [pr]

        // When - First load
        await container.loadPullRequests()

        guard case .loaded(let firstPrs) = container.loadingState else {
            Issue.record("Expected loaded state")
            return
        }
        #expect(firstPrs[0].commentCount == 7)

        // Update comment count in mock
        let updatedPr = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 1,
            title: "PR",
            authorLogin: "author",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/1")!,
            commentCount: 9
        )
        mockGitHubAPI.pullRequestsToReturn = [updatedPr]

        // When - Reload
        await container.loadPullRequests()

        // Then - Comment count updated
        guard case .loaded(let reloadedPrs) = container.loadingState else {
            Issue.record("Expected loaded state")
            return
        }
        #expect(reloadedPrs[0].commentCount == 9)
    }

    @Test
    func `comment counts available immediately from Search API response`() async throws {
        // Given
        let credentials = GitHubCredentials(token: "token", baseURL: "https://api.github.com")
        mockCredentialStorage.preloadCredentials(credentials)

        let pr = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 1,
            title: "PR",
            authorLogin: "author",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/1")!,
            commentCount: 15
        )
        mockGitHubAPI.pullRequestsToReturn = [pr]

        // When
        await container.loadPullRequests()

        // Then - Comment count is immediately available (no async enrichment needed)
        guard case .loaded(let prs) = container.loadingState else {
            Issue.record("Expected loaded state")
            return
        }
        #expect(prs[0].commentCount == 15)
        // Verify no additional API calls were made for comment counts
        #expect(mockGitHubAPI.fetchReviewRequestsCallCount == 1)
    }
}
