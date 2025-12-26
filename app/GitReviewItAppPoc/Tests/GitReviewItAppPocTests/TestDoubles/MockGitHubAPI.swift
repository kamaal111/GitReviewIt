import Foundation

@testable import GitReviewItAppPoc

/// Mock implementation of GitHubAPI for testing
/// Allows pre-configuring responses without making actual network calls
@MainActor
final class MockGitHubAPI: GitHubAPI {
    // MARK: - Configuration

    /// User to return from fetchUser
    var userToReturn: AuthenticatedUser?

    /// Teams to return from fetchTeams
    var teamsToReturn: [Team] = []

    /// Pull requests to return from fetchReviewRequests
    var pullRequestsToReturn: [PullRequest] = []

    /// Convenience alias for pullRequestsToReturn
    var pullRequests: [PullRequest] {
        get { pullRequestsToReturn }
        set { pullRequestsToReturn = newValue }
    }

    /// Error to throw from fetchUser
    var fetchUserErrorToThrow: Error?

    /// Error to throw from fetchTeams
    var fetchTeamsErrorToThrow: Error?

    /// Error to throw from fetchReviewRequests
    var fetchReviewRequestsErrorToThrow: Error?

    /// PR preview metadata to return from fetchPRDetails (keyed by "owner/repo#number")
    var prDetailsToReturn: [String: PRPreviewMetadata] = [:]

    /// Convenience alias for prDetailsToReturn
    var prDetailsResponses: [String: PRPreviewMetadata] {
        get { prDetailsToReturn }
        set { prDetailsToReturn = newValue }
    }

    /// Mock responses per PR (keyed by "owner/repo#number") - allows individual success/failure
    var mockPRDetailsResponses: [String: Result<PRPreviewMetadata, Error>] = [:]

    /// Set of PR IDs that should fail when fetching details
    var shouldFailPRDetails: Set<String> = []

    /// Error to throw from fetchPRDetails
    var fetchPRDetailsErrorToThrow: Error?

    /// Reviews to return from fetchPRReviews (keyed by "owner/repo#number")
    var prReviewsToReturn: [String: [PRReviewResponse]] = [:]

    /// Error to throw from fetchPRReviews
    var fetchPRReviewsErrorToThrow: Error?

    /// Review comments to return from fetchPRReviewComments (keyed by "owner/repo#number")
    var prReviewCommentsToReturn: [String: [PRReviewCommentResponse]] = [:]

    /// Error to throw from fetchPRReviewComments
    var fetchPRReviewCommentsErrorToThrow: Error?

    /// Check runs to return from fetchCheckRuns (keyed by "owner/repo@ref")
    var checkRunsToReturn: [String: CheckRunsResponse] = [:]

    /// Error to throw from fetchCheckRuns
    var fetchCheckRunsErrorToThrow: Error?

    /// Convenience property for counting PR details fetches
    var prDetailsFetchCount: Int {
        fetchPRDetailsCallCount
    }

    // MARK: - Captured Data

    /// Credentials passed to fetchUser
    private(set) var fetchUserCredentials: [GitHubCredentials] = []

    /// Credentials passed to fetchTeams
    private(set) var fetchTeamsCredentials: [GitHubCredentials] = []

    /// Credentials passed to fetchReviewRequests
    private(set) var fetchReviewRequestsCredentials: [GitHubCredentials] = []

    /// PR details requests captured (owner, repo, number, credentials)
    private(set) var fetchPRDetailsRequests:
        [(owner: String, repo: String, number: Int, credentials: GitHubCredentials)] = []

    /// PR reviews requests captured (owner, repo, number, credentials)
    private(set) var fetchPRReviewsRequests:
        [(owner: String, repo: String, number: Int, credentials: GitHubCredentials)] = []

    /// PR review comments requests captured (owner, repo, number, credentials)
    private(set) var fetchPRReviewCommentsRequests:
        [(owner: String, repo: String, number: Int, credentials: GitHubCredentials)] = []

    /// Check runs requests captured (owner, repo, ref, credentials)
    private(set) var fetchCheckRunsRequests:
        [(owner: String, repo: String, ref: String, credentials: GitHubCredentials)] = []

    /// Count of how many times fetchUser was called
    var fetchUserCallCount: Int {
        fetchUserCredentials.count
    }

    /// Count of how many times fetchTeams was called
    var fetchTeamsCallCount: Int {
        fetchTeamsCredentials.count
    }

    /// Count of how many times fetchReviewRequests was called
    var fetchReviewRequestsCallCount: Int {
        fetchReviewRequestsCredentials.count
    }

    /// Count of how many times fetchPRDetails was called
    var fetchPRDetailsCallCount: Int {
        fetchPRDetailsRequests.count
    }

    /// Count of how many times fetchPRReviews was called
    var fetchPRReviewsCallCount: Int {
        fetchPRReviewsRequests.count
    }

    /// Count of how many times fetchPRReviewComments was called
    var fetchPRReviewCommentsCallCount: Int {
        fetchPRReviewCommentsRequests.count
    }

    /// Count of how many times fetchCheckRuns was called
    var fetchCheckRunsCallCount: Int {
        fetchCheckRunsRequests.count
    }

    // MARK: - GitHubAPI Protocol

    func fetchUser(credentials: GitHubCredentials) async throws -> AuthenticatedUser {
        fetchUserCredentials.append(credentials)

        if let error = fetchUserErrorToThrow {
            throw error
        }

        guard let user = userToReturn else {
            // Default user if none configured
            return AuthenticatedUser(
                login: "testuser",
                name: "Test User",
                avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4")
            )
        }

        return user
    }

    func fetchTeams(credentials: GitHubCredentials) async throws -> [Team] {
        fetchTeamsCredentials.append(credentials)

        if let error = fetchTeamsErrorToThrow {
            throw error
        }

        return teamsToReturn
    }

    func fetchReviewRequests(credentials: GitHubCredentials) async throws -> [PullRequest] {
        fetchReviewRequestsCredentials.append(credentials)

        if let error = fetchReviewRequestsErrorToThrow {
            throw error
        }

        return pullRequestsToReturn
    }

    func fetchPRDetails(
        owner: String,
        repo: String,
        number: Int,
        credentials: GitHubCredentials
    ) async throws -> PRPreviewMetadata {
        fetchPRDetailsRequests.append((owner, repo, number, credentials))

        let key = "\(owner)/\(repo)#\(number)"

        // Check for per-PR mock responses first
        if let mockResponse = mockPRDetailsResponses[key] {
            switch mockResponse {
            case .success(let metadata):
                return metadata
            case .failure(let error):
                throw error
            }
        }

        // Check if this PR should fail
        if shouldFailPRDetails.contains(key) {
            throw APIError.notFound
        }

        if let error = fetchPRDetailsErrorToThrow {
            throw error
        }

        guard let metadata = prDetailsToReturn[key] else {
            // Return default metadata if not configured
            return PRPreviewMetadata(
                additions: 10,
                deletions: 5,
                changedFiles: 2,
                requestedReviewers: [],
                completedReviewers: []
            )
        }

        return metadata
    }

    func fetchPRReviews(
        owner: String,
        repo: String,
        number: Int,
        credentials: GitHubCredentials
    ) async throws -> [PRReviewResponse] {
        fetchPRReviewsRequests.append((owner, repo, number, credentials))

        if let error = fetchPRReviewsErrorToThrow {
            throw error
        }

        let key = "\(owner)/\(repo)#\(number)"
        return prReviewsToReturn[key] ?? []
    }

    func fetchPRReviewComments(
        owner: String,
        repo: String,
        number: Int,
        credentials: GitHubCredentials
    ) async throws -> [PRReviewCommentResponse] {
        fetchPRReviewCommentsRequests.append((owner, repo, number, credentials))

        if let error = fetchPRReviewCommentsErrorToThrow {
            throw error
        }

        let key = "\(owner)/\(repo)#\(number)"
        return prReviewCommentsToReturn[key] ?? []
    }

    func fetchCheckRuns(
        owner: String,
        repo: String,
        ref: String,
        credentials: GitHubCredentials
    ) async throws -> CheckRunsResponse {
        fetchCheckRunsRequests.append((owner, repo, ref, credentials))

        if let error = fetchCheckRunsErrorToThrow {
            throw error
        }

        let key = "\(owner)/\(repo)@\(ref)"
        if let checkRuns = checkRunsToReturn[key] {
            return checkRuns
        }

        // Return default empty response if not configured
        return CheckRunsResponse(total_count: 0, check_runs: [])
    }

    // MARK: - Test Helpers

    /// Reset all captured data and configuration
    func reset() {
        userToReturn = nil
        teamsToReturn = []
        pullRequestsToReturn = []
        fetchUserErrorToThrow = nil
        fetchTeamsErrorToThrow = nil
        fetchReviewRequestsErrorToThrow = nil
        fetchUserCredentials.removeAll()
        fetchTeamsCredentials.removeAll()
        fetchReviewRequestsCredentials.removeAll()
        prDetailsToReturn.removeAll()
        mockPRDetailsResponses.removeAll()
        fetchPRDetailsErrorToThrow = nil
        fetchPRDetailsRequests.removeAll()
        shouldFailPRDetails.removeAll()
        prReviewsToReturn.removeAll()
        fetchPRReviewsErrorToThrow = nil
        fetchPRReviewsRequests.removeAll()
        prReviewCommentsToReturn.removeAll()
        fetchPRReviewCommentsErrorToThrow = nil
        fetchPRReviewCommentsRequests.removeAll()
        checkRunsToReturn.removeAll()
        fetchCheckRunsErrorToThrow = nil
        fetchCheckRunsRequests.removeAll()
    }

    /// Get the last credentials used for fetchUser
    var lastFetchUserCredentials: GitHubCredentials? {
        fetchUserCredentials.last
    }

    /// Get the last credentials used for fetchTeams
    var lastFetchTeamsCredentials: GitHubCredentials? {
        fetchTeamsCredentials.last
    }

    /// Get the last credentials used for fetchReviewRequests
    var lastFetchReviewRequestsCredentials: GitHubCredentials? {
        fetchReviewRequestsCredentials.last
    }

    /// Check if a specific base URL was used in any API call
    func didUseBaseURL(_ baseURL: String) -> Bool {
        let allCredentials = fetchUserCredentials + fetchTeamsCredentials + fetchReviewRequestsCredentials
        return allCredentials.contains { $0.baseURL == baseURL }
    }
}
