import AppKit
import Foundation
import Observation

@Observable
@MainActor
final class PullRequestListContainer {
    private(set) var loadingState: LoadingState<[PullRequest]> = .idle
    private(set) var filterState: FilterState

    private let githubAPI: GitHubAPI
    private let credentialStorage: CredentialStorage
    private let openURL: (URL) -> Void
    private let filterEngine: FilterEngineProtocol

    init(
        githubAPI: GitHubAPI,
        credentialStorage: CredentialStorage,
        filterEngine: FilterEngineProtocol = FilterEngine(),
        openURL: @escaping (URL) -> Void = { NSWorkspace.shared.open($0) }
    ) {
        self.githubAPI = githubAPI
        self.credentialStorage = credentialStorage
        self.openURL = openURL
        self.filterEngine = filterEngine
        self.filterState = FilterState(persistence: UserDefaultsFilterPersistence())
    }

    var filteredPullRequests: [PullRequest] {
        guard case .loaded(let allPRs) = loadingState else { return [] }
        return filterEngine.apply(
            configuration: filterState.configuration,
            searchQuery: filterState.searchQuery,
            to: allPRs,
            teamMetadata: []
        )
    }

    /// Fetches pull requests where the authenticated user's review is requested
    ///
    /// This method:
    /// 1. Updates state to .loading
    /// 2. Retrieves credentials from secure storage
    /// 3. Fetches PRs from GitHub API
    /// 4. Updates state to .loaded with results or .failed with error
    func loadPullRequests() async {
        loadingState = .loading

        do {
            guard let credentials = try await credentialStorage.retrieve() else {
                loadingState = .failed(APIError.unauthorized)
                return
            }

            let pullRequests = try await githubAPI.fetchReviewRequests(credentials: credentials)
            loadingState = .loaded(pullRequests)
        } catch let error as APIError {
            loadingState = .failed(error)
        } catch {
            loadingState = .failed(APIError.unknown(error))
        }
    }

    /// Retries the pull request fetch operation
    func retry() async {
        await loadPullRequests()
    }

    /// Opens the specified pull request URL in the default browser
    /// - Parameter url: The URL to open
    func openPR(url: URL) {
        openURL(url)
    }
}
