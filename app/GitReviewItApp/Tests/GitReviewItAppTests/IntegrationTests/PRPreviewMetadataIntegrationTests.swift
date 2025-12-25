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

    // MARK: - Reviewer Data Tests

    @Test
    func `PR Details API returns reviewer data for PRs with requested reviewers`() async throws {
        // Given
        let credentials = GitHubCredentials(token: "token", baseURL: "https://api.github.com")
        mockCredentialStorage.preloadCredentials(credentials)

        let pr = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 1,
            title: "PR with reviewers",
            authorLogin: "author",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/1")!,
            commentCount: 0
        )
        mockGitHubAPI.pullRequestsToReturn = [pr]

        let reviewer1 = Reviewer(login: "reviewer1", avatarURL: URL(string: "https://avatars.github.com/u/1"))
        let reviewer2 = Reviewer(login: "reviewer2", avatarURL: URL(string: "https://avatars.github.com/u/2"))

        mockGitHubAPI.prDetailsToReturn["owner/repo#1"] = PRPreviewMetadata(
            additions: 50,
            deletions: 20,
            changedFiles: 5,
            requestedReviewers: [reviewer1, reviewer2]
        )

        // When
        await container.loadPullRequests()

        // Then
        guard case .loaded(let prs) = container.loadingState else {
            Issue.record("Expected loaded state")
            return
        }
        #expect(prs.count == 1)

        // Preview metadata should be enriched with reviewer information
        let metadata = try #require(prs[0].previewMetadata)
        #expect(metadata.requestedReviewers.count == 2)
        #expect(metadata.requestedReviewers[0].login == "reviewer1")
        #expect(metadata.requestedReviewers[1].login == "reviewer2")
    }

    @Test
    func `PR Details API returns empty array for PRs with no reviewers`() async throws {
        // Given
        let credentials = GitHubCredentials(token: "token", baseURL: "https://api.github.com")
        mockCredentialStorage.preloadCredentials(credentials)

        let pr = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 1,
            title: "PR without reviewers",
            authorLogin: "author",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/1")!,
            commentCount: 0
        )
        mockGitHubAPI.pullRequestsToReturn = [pr]

        mockGitHubAPI.prDetailsToReturn["owner/repo#1"] = PRPreviewMetadata(
            additions: 30,
            deletions: 10,
            changedFiles: 2,
            requestedReviewers: []
        )

        // When
        await container.loadPullRequests()

        // Then
        guard case .loaded(let prs) = container.loadingState else {
            Issue.record("Expected loaded state")
            return
        }
        #expect(prs.count == 1)

        let metadata = try #require(prs[0].previewMetadata)
        #expect(metadata.requestedReviewers.isEmpty)
    }

    @Test
    func `reviewer data includes avatar URLs when available`() async throws {
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
            commentCount: 0
        )
        mockGitHubAPI.pullRequestsToReturn = [pr]

        let reviewerWithAvatar = Reviewer(
            login: "octocat",
            avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1")
        )
        let reviewerWithoutAvatar = Reviewer(login: "noavatar", avatarURL: nil)

        mockGitHubAPI.prDetailsToReturn["owner/repo#1"] = PRPreviewMetadata(
            additions: 40,
            deletions: 15,
            changedFiles: 4,
            requestedReviewers: [reviewerWithAvatar, reviewerWithoutAvatar]
        )

        // When
        await container.loadPullRequests()

        // Then
        guard case .loaded(let prs) = container.loadingState else {
            Issue.record("Expected loaded state")
            return
        }

        let metadata = try #require(prs[0].previewMetadata)
        #expect(metadata.requestedReviewers.count == 2)
        #expect(metadata.requestedReviewers[0].avatarURL != nil)
        #expect(metadata.requestedReviewers[1].avatarURL == nil)
    }

    // MARK: - Label Data Tests

    @Test
    func `Search API returns label data for PRs with labels`() async throws {
        // Given
        let credentials = GitHubCredentials(token: "token", baseURL: "https://api.github.com")
        mockCredentialStorage.preloadCredentials(credentials)

        let labels = [
            PRLabel(name: "bug", color: "d73a4a"),
            PRLabel(name: "enhancement", color: "a2eeef"),
        ]

        let prWithLabels = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 1,
            title: "PR with labels",
            authorLogin: "author",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/1")!,
            commentCount: 0,
            labels: labels
        )
        mockGitHubAPI.pullRequestsToReturn = [prWithLabels]

        // When
        await container.loadPullRequests()

        // Then
        guard case .loaded(let prs) = container.loadingState else {
            Issue.record("Expected loaded state")
            return
        }
        #expect(prs.count == 1)
        #expect(prs[0].labels.count == 2)
        #expect(prs[0].labels[0].name == "bug")
        #expect(prs[0].labels[0].color == "d73a4a")
        #expect(prs[0].labels[1].name == "enhancement")
        #expect(prs[0].labels[1].color == "a2eeef")
    }

    @Test
    func `Search API returns empty array for PRs with no labels`() async throws {
        // Given
        let credentials = GitHubCredentials(token: "token", baseURL: "https://api.github.com")
        mockCredentialStorage.preloadCredentials(credentials)

        let prWithoutLabels = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 2,
            title: "PR without labels",
            authorLogin: "author",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/2")!,
            commentCount: 0,
            labels: []
        )
        mockGitHubAPI.pullRequestsToReturn = [prWithoutLabels]

        // When
        await container.loadPullRequests()

        // Then
        guard case .loaded(let prs) = container.loadingState else {
            Issue.record("Expected loaded state")
            return
        }
        #expect(prs.count == 1)
        #expect(prs[0].labels.isEmpty)
    }

    @Test
    func `Search API handles mixed label scenarios correctly`() async throws {
        // Given
        let credentials = GitHubCredentials(token: "token", baseURL: "https://api.github.com")
        mockCredentialStorage.preloadCredentials(credentials)

        let prNoLabels = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 1,
            title: "PR 1",
            authorLogin: "author1",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/1")!,
            commentCount: 0,
            labels: []
        )

        let prSingleLabel = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 2,
            title: "PR 2",
            authorLogin: "author2",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/2")!,
            commentCount: 0,
            labels: [PRLabel(name: "bug", color: "d73a4a")]
        )

        let prMultipleLabels = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 3,
            title: "PR 3",
            authorLogin: "author3",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/3")!,
            commentCount: 0,
            labels: [
                PRLabel(name: "bug", color: "d73a4a"),
                PRLabel(name: "urgent", color: "ff6b6b"),
                PRLabel(name: "backend", color: "0e8a16"),
            ]
        )

        mockGitHubAPI.pullRequestsToReturn = [prNoLabels, prSingleLabel, prMultipleLabels]

        // When
        await container.loadPullRequests()

        // Then
        guard case .loaded(let prs) = container.loadingState else {
            Issue.record("Expected loaded state")
            return
        }
        #expect(prs.count == 3)
        #expect(prs[0].labels.isEmpty)
        #expect(prs[1].labels.count == 1)
        #expect(prs[2].labels.count == 3)
    }

    @Test
    func `labels persist through reload`() async throws {
        // Given
        let credentials = GitHubCredentials(token: "token", baseURL: "https://api.github.com")
        mockCredentialStorage.preloadCredentials(credentials)

        let initialLabels = [PRLabel(name: "bug", color: "d73a4a")]
        let pr = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 1,
            title: "PR",
            authorLogin: "author",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/1")!,
            commentCount: 0,
            labels: initialLabels
        )
        mockGitHubAPI.pullRequestsToReturn = [pr]

        // When - First load
        await container.loadPullRequests()

        guard case .loaded(let firstPrs) = container.loadingState else {
            Issue.record("Expected loaded state")
            return
        }
        #expect(firstPrs[0].labels.count == 1)

        // Update labels in mock
        let updatedLabels = [
            PRLabel(name: "bug", color: "d73a4a"),
            PRLabel(name: "fixed", color: "0e8a16"),
        ]
        let updatedPr = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 1,
            title: "PR",
            authorLogin: "author",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/1")!,
            commentCount: 0,
            labels: updatedLabels
        )
        mockGitHubAPI.pullRequestsToReturn = [updatedPr]

        // When - Reload
        await container.loadPullRequests()

        // Then - Labels updated
        guard case .loaded(let reloadedPrs) = container.loadingState else {
            Issue.record("Expected loaded state")
            return
        }
        #expect(reloadedPrs[0].labels.count == 2)
    }

    @Test
    func `labels available immediately from Search API response`() async throws {
        // Given
        let credentials = GitHubCredentials(token: "token", baseURL: "https://api.github.com")
        mockCredentialStorage.preloadCredentials(credentials)

        let labels = [
            PRLabel(name: "documentation", color: "0075ca"),
            PRLabel(name: "good first issue", color: "7057ff"),
        ]
        let pr = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 1,
            title: "PR",
            authorLogin: "author",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/1")!,
            commentCount: 0,
            labels: labels
        )
        mockGitHubAPI.pullRequestsToReturn = [pr]

        // When
        await container.loadPullRequests()

        // Then - Labels are immediately available (no async enrichment needed)
        guard case .loaded(let prs) = container.loadingState else {
            Issue.record("Expected loaded state")
            return
        }
        #expect(prs[0].labels.count == 2)
        // Verify no additional API calls were made for labels
        #expect(mockGitHubAPI.fetchReviewRequestsCallCount == 1)
    }

    // MARK: - Check Status Tests

    @Test
    func `PR with passing checks shows passing status`() async throws {
        // Given
        let credentials = GitHubCredentials(token: "token", baseURL: "https://api.github.com")
        mockCredentialStorage.preloadCredentials(credentials)

        let pr = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 1,
            title: "PR with passing checks",
            authorLogin: "author",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/1")!,
            commentCount: 0
        )
        mockGitHubAPI.pullRequestsToReturn = [pr]

        // Configure PR details with head SHA
        let metadata = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 2,
            requestedReviewers: [],
            checkStatus: .passing
        )
        mockGitHubAPI.prDetailsToReturn["owner/repo#1"] = metadata

        // Configure check runs response
        let checkRuns = CheckRunsResponse(
            total_count: 2,
            check_runs: [
                CheckRunsResponse.CheckRun(status: "completed", conclusion: "success"),
                CheckRunsResponse.CheckRun(status: "completed", conclusion: "success"),
            ]
        )
        mockGitHubAPI.checkRunsToReturn["owner/repo@abc123"] = checkRuns

        // When
        await container.loadPullRequests()
        guard case .loaded(let prs) = container.loadingState else {
            Issue.record("Expected loaded state")
            return
        }
        guard let firstPR = prs.first else {
            Issue.record("Expected at least one PR")
            return
        }

        // Then
        guard let loadedMetadata = firstPR.previewMetadata else {
            Issue.record("Expected metadata to be loaded")
            return
        }
        #expect(loadedMetadata.checkStatus == .passing)
    }

    @Test
    func `PR with failing checks shows failing status`() async throws {
        // Given
        let credentials = GitHubCredentials(token: "token", baseURL: "https://api.github.com")
        mockCredentialStorage.preloadCredentials(credentials)

        let pr = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 2,
            title: "PR with failing checks",
            authorLogin: "author",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/2")!,
            commentCount: 0
        )
        mockGitHubAPI.pullRequestsToReturn = [pr]

        // Configure PR details with failing checks
        let metadata = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 2,
            requestedReviewers: [],
            checkStatus: .failing
        )
        mockGitHubAPI.prDetailsToReturn["owner/repo#2"] = metadata

        // Configure check runs response with failures
        let checkRuns = CheckRunsResponse(
            total_count: 3,
            check_runs: [
                CheckRunsResponse.CheckRun(status: "completed", conclusion: "success"),
                CheckRunsResponse.CheckRun(status: "completed", conclusion: "failure"),
                CheckRunsResponse.CheckRun(status: "completed", conclusion: "success"),
            ]
        )
        mockGitHubAPI.checkRunsToReturn["owner/repo@def456"] = checkRuns

        // When
        await container.loadPullRequests()
        guard case .loaded(let prs) = container.loadingState else {
            Issue.record("Expected loaded state")
            return
        }
        guard let firstPR = prs.first else {
            Issue.record("Expected at least one PR")
            return
        }

        // Then
        guard let loadedMetadata = firstPR.previewMetadata else {
            Issue.record("Expected metadata to be loaded")
            return
        }
        #expect(loadedMetadata.checkStatus == .failing)
    }

    @Test
    func `PR with pending checks shows pending status`() async throws {
        // Given
        let credentials = GitHubCredentials(token: "token", baseURL: "https://api.github.com")
        mockCredentialStorage.preloadCredentials(credentials)

        let pr = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 3,
            title: "PR with pending checks",
            authorLogin: "author",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/3")!,
            commentCount: 0
        )
        mockGitHubAPI.pullRequestsToReturn = [pr]

        // Configure PR details with pending checks
        let metadata = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 2,
            requestedReviewers: [],
            checkStatus: .pending
        )
        mockGitHubAPI.prDetailsToReturn["owner/repo#3"] = metadata

        // Configure check runs response with in-progress checks
        let checkRuns = CheckRunsResponse(
            total_count: 2,
            check_runs: [
                CheckRunsResponse.CheckRun(status: "completed", conclusion: "success"),
                CheckRunsResponse.CheckRun(status: "in_progress", conclusion: nil),
            ]
        )
        mockGitHubAPI.checkRunsToReturn["owner/repo@ghi789"] = checkRuns

        // When
        await container.loadPullRequests()
        guard case .loaded(let prs) = container.loadingState else {
            Issue.record("Expected loaded state")
            return
        }
        guard let firstPR = prs.first else {
            Issue.record("Expected at least one PR")
            return
        }

        // Then
        guard let loadedMetadata = firstPR.previewMetadata else {
            Issue.record("Expected metadata to be loaded")
            return
        }
        #expect(loadedMetadata.checkStatus == .pending)
    }

    @Test
    func `PR with no checks shows unknown status`() async throws {
        // Given
        let credentials = GitHubCredentials(token: "token", baseURL: "https://api.github.com")
        mockCredentialStorage.preloadCredentials(credentials)

        let pr = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 4,
            title: "PR with no checks",
            authorLogin: "author",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/4")!,
            commentCount: 0
        )
        mockGitHubAPI.pullRequestsToReturn = [pr]

        // Configure PR details with unknown check status
        let metadata = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 2,
            requestedReviewers: [],
            checkStatus: .unknown
        )
        mockGitHubAPI.prDetailsToReturn["owner/repo#4"] = metadata

        // Configure empty check runs response
        let checkRuns = CheckRunsResponse(total_count: 0, check_runs: [])
        mockGitHubAPI.checkRunsToReturn["owner/repo@jkl012"] = checkRuns

        // When
        await container.loadPullRequests()
        guard case .loaded(let prs) = container.loadingState else {
            Issue.record("Expected loaded state")
            return
        }
        guard let firstPR = prs.first else {
            Issue.record("Expected at least one PR")
            return
        }

        // Then
        guard let loadedMetadata = firstPR.previewMetadata else {
            Issue.record("Expected metadata to be loaded")
            return
        }
        #expect(loadedMetadata.checkStatus == .unknown)
    }

    @Test
    func `PR with mergeable status shows mergeable`() async throws {
        // Given
        let credentials = GitHubCredentials(token: "token", baseURL: "https://api.github.com")
        mockCredentialStorage.preloadCredentials(credentials)

        let pr = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 5,
            title: "Mergeable PR",
            authorLogin: "author",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/5")!,
            commentCount: 0
        )
        mockGitHubAPI.pullRequestsToReturn = [pr]

        // Configure PR details with mergeable status
        let metadata = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 2,
            requestedReviewers: [],
            mergeStatus: .mergeable
        )
        mockGitHubAPI.prDetailsToReturn["owner/repo#5"] = metadata

        // When
        await container.loadPullRequests()
        guard case .loaded(let prs) = container.loadingState else {
            Issue.record("Expected loaded state")
            return
        }
        guard let firstPR = prs.first else {
            Issue.record("Expected at least one PR")
            return
        }

        // Then
        guard let loadedMetadata = firstPR.previewMetadata else {
            Issue.record("Expected metadata to be loaded")
            return
        }
        #expect(loadedMetadata.mergeStatus == .mergeable)
    }

    @Test
    func `PR with conflicting status shows conflicting`() async throws {
        // Given
        let credentials = GitHubCredentials(token: "token", baseURL: "https://api.github.com")
        mockCredentialStorage.preloadCredentials(credentials)

        let pr = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 6,
            title: "Conflicting PR",
            authorLogin: "author",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/6")!,
            commentCount: 0
        )
        mockGitHubAPI.pullRequestsToReturn = [pr]

        // Configure PR details with conflicting status
        let metadata = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 2,
            requestedReviewers: [],
            mergeStatus: .conflicting
        )
        mockGitHubAPI.prDetailsToReturn["owner/repo#6"] = metadata

        // When
        await container.loadPullRequests()
        guard case .loaded(let prs) = container.loadingState else {
            Issue.record("Expected loaded state")
            return
        }
        guard let firstPR = prs.first else {
            Issue.record("Expected at least one PR")
            return
        }

        // Then
        guard let loadedMetadata = firstPR.previewMetadata else {
            Issue.record("Expected metadata to be loaded")
            return
        }
        #expect(loadedMetadata.mergeStatus == .conflicting)
    }
}
