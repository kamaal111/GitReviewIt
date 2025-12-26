import AppKit
import Foundation
import OSLog
import Observation

@Observable
@MainActor
final class PullRequestListContainer {
    private(set) var loadingState: LoadingState<[PullRequest]> = .idle
    private(set) var filterState: FilterState

    /// Indicates whether metadata enrichment is currently in progress
    private(set) var isEnrichingMetadata: Bool = false

    private let githubAPI: GitHubAPI
    private let credentialStorage: CredentialStorage
    private let openURL: (URL) -> Void
    private let filterEngine: FilterEngineProtocol
    private let logger = Logger(subsystem: "com.gitreviewit.app", category: "PullRequestListContainer")

    /// Cache for PR preview metadata to avoid redundant API calls
    private var metadataCache: [String: PRPreviewMetadata] = [:]

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

        // Load persisted filters
        Task {
            await self.filterState.loadPersistedConfiguration()
        }
    }

    var filteredPullRequests: [PullRequest] {
        guard case .loaded(let allPRs) = loadingState else { return [] }
        return filterEngine.apply(
            configuration: filterState.configuration,
            searchQuery: filterState.debouncedSearchQuery,
            to: allPRs,
            teamMetadata: filterState.metadata.teams.value ?? []
        )
    }

    /// Fetches pull requests where the authenticated user's review is requested
    ///
    /// This method:
    /// 1. Updates state to .loading
    /// 2. Retrieves credentials from secure storage
    /// 3. Fetches PRs from GitHub API
    /// 4. Updates state to .loaded with results or .failed with error
    /// 5. Clears metadata cache for fresh data
    /// 6. Enriches PRs with preview metadata asynchronously
    func loadPullRequests() async {
        loadingState = .loading
        clearMetadataCache()

        do {
            guard let credentials = try await credentialStorage.retrieve() else {
                loadingState = .failed(APIError.unauthorized)
                return
            }

            let pullRequests = try await githubAPI.fetchReviewRequests(credentials: credentials)
            loadingState = .loaded(pullRequests)

            // Update metadata with teams
            await filterState.updateMetadata(
                from: pullRequests,
                api: githubAPI,
                credentials: credentials
            )

            // Enrich PRs with preview metadata asynchronously
            await enrichPreviewMetadata(for: pullRequests, credentials: credentials)
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

    /// Enriches pull requests with preview metadata by fetching details from GitHub API in parallel
    ///
    /// This method:
    /// 1. Fetches PR details for each PR concurrently
    /// 2. Updates each PR's previewMetadata field as data arrives
    /// 3. Uses cached metadata to avoid redundant API calls
    /// 4. Handles individual PR failures gracefully (logs error, continues with others)
    ///
    /// - Parameters:
    ///   - pullRequests: Array of pull requests to enrich
    ///   - credentials: GitHub credentials for API access
    func enrichPreviewMetadata(for pullRequests: [PullRequest], credentials: GitHubCredentials) async {
        guard case .loaded(var prs) = loadingState else { return }

        isEnrichingMetadata = true
        defer { isEnrichingMetadata = false }

        logger.info("Starting metadata enrichment for \(pullRequests.count) PRs")

        await withTaskGroup(of: (String, PRPreviewMetadata?).self) { group in
            for pr in pullRequests {
                let prID = pr.id

                // Check cache first
                guard metadataCache[prID] == nil else {
                    logger.debug("Using cached metadata for PR \(prID)")
                    continue
                }

                group.addTask {
                    do {
                        let metadata = try await self.githubAPI.fetchPRDetails(
                            owner: pr.repositoryOwner,
                            repo: pr.repositoryName,
                            number: pr.number,
                            credentials: credentials
                        )
                        self.logger.debug("Successfully fetched metadata for PR \(prID)")
                        return (prID, metadata)
                    } catch {
                        self.logger.error("Failed to fetch metadata for PR \(prID): \(error.localizedDescription)")
                        return (prID, nil)
                    }
                }
            }

            // Process results as they arrive
            for await (prID, metadata) in group {
                guard let metadata = metadata else { continue }

                // Cache the metadata
                metadataCache[prID] = metadata

                // Update the PR in the loaded state
                guard let index = prs.firstIndex(where: { $0.id == prID }) else { continue }
                prs[index].previewMetadata = metadata
                loadingState = .loaded(prs)
            }
        }

        logger.info("Metadata enrichment completed")
    }

    /// Clears the metadata cache
    ///
    /// Should be called when refreshing PR list to ensure fresh data is fetched
    func clearMetadataCache() {
        logger.debug("Clearing metadata cache (\(self.metadataCache.count) entries)")
        metadataCache.removeAll()
    }
}
