import Foundation
import Testing

@testable import GitReviewItAppPoc

@MainActor
struct PullRequestListTests {
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

    @Test
    func `loadPullRequests successfully fetches PRs`() async throws {
        // Given
        let credentials = GitHubCredentials(token: "token", baseURL: "https://api.github.com")
        mockCredentialStorage.preloadCredentials(credentials)

        let pr = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 1,
            title: "Title",
            authorLogin: "author",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/1")!
        )
        mockGitHubAPI.pullRequestsToReturn = [pr]

        // When
        await container.loadPullRequests()

        // Then
        guard case .loaded(let prs) = container.loadingState else {
            Issue.record("Expected loaded state")
            return
        }
        #expect(prs.count == 1)
        #expect(prs[0].repositoryOwner == "owner")
        #expect(prs[0].number == 1)
        #expect(mockGitHubAPI.fetchReviewRequestsCallCount == 1)
    }

    @Test
    func `loadPullRequests handles empty state`() async throws {
        // Given
        let credentials = GitHubCredentials(token: "token", baseURL: "https://api.github.com")
        mockCredentialStorage.preloadCredentials(credentials)
        mockGitHubAPI.pullRequestsToReturn = []

        // When
        await container.loadPullRequests()

        // Then
        #expect(container.loadingState == .loaded([]))
    }

    @Test
    func `loadPullRequests handles errors`() async throws {
        // Given
        let credentials = GitHubCredentials(token: "token", baseURL: "https://api.github.com")
        mockCredentialStorage.preloadCredentials(credentials)
        mockGitHubAPI.fetchReviewRequestsErrorToThrow = APIError.unauthorized

        // When
        await container.loadPullRequests()

        // Then
        #expect(container.loadingState == .failed(.unauthorized))
    }

    @Test
    func `retry calls loadPullRequests`() async throws {
        // Given
        let credentials = GitHubCredentials(token: "token", baseURL: "https://api.github.com")
        mockCredentialStorage.preloadCredentials(credentials)

        // First call fails
        let networkError = URLError(.notConnectedToInternet)
        mockGitHubAPI.fetchReviewRequestsErrorToThrow = APIError.networkError(networkError)
        await container.loadPullRequests()

        #expect(container.loadingState == .failed(.networkError(networkError)))

        // Second call succeeds
        mockGitHubAPI.fetchReviewRequestsErrorToThrow = nil
        mockGitHubAPI.pullRequestsToReturn = []

        // When
        await container.retry()

        // Then
        #expect(container.loadingState == .loaded([]))
        #expect(mockGitHubAPI.fetchReviewRequestsCallCount == 2)
    }

    @Test
    func `Draft PRs are correctly marked`() async throws {
        // Given
        let credentials = GitHubCredentials(token: "token", baseURL: "https://api.github.com")
        mockCredentialStorage.preloadCredentials(credentials)

        let draftPR = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 1,
            title: "WIP: Draft PR",
            authorLogin: "author",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/1")!,
            isDraft: true
        )

        let regularPR = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 2,
            title: "Regular PR",
            authorLogin: "author",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/2")!,
            isDraft: false
        )

        mockGitHubAPI.pullRequestsToReturn = [draftPR, regularPR]

        // When
        await container.loadPullRequests()

        // Then
        guard case .loaded(let prs) = container.loadingState else {
            Issue.record("Expected loaded state")
            return
        }

        #expect(prs.count == 2)
        #expect(prs[0].isDraft == true)
        #expect(prs[1].isDraft == false)
    }
}
