//
//  FilterState.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 23/12/2025.
//

import OSLog
import Observation
import SwiftUI

/// Observable state container for PR filtering and search.
///
/// **Responsibilities**:
/// - Manages search query with 300ms debouncing
/// - Manages structured filter configuration (org, repo, team)
/// - Persists filter configuration across app launches
/// - Manages filter metadata (available options)
/// - Handles team API errors with graceful degradation
///
/// **State properties**:
/// - `searchQuery`: Current search text (debounced by 300ms)
/// - `configuration`: Active structured filters (org, repo, team)
/// - `metadata`: Available filter options extracted from PRs
/// - `errorMessage`: User-facing error message (nil if no error)
///
/// **Usage**:
/// ```swift
/// @State private var filterState = FilterState(
///     persistence: UserDefaultsFilterPersistence(),
///     timeProvider: RealTimeProvider()
/// )
///
/// // Load persisted filters on app launch
/// await filterState.loadPersistedConfiguration()
///
/// // Update search (debounced)
/// filterState.updateSearchQuery("fix bug")
///
/// // Update structured filters (persisted)
/// await filterState.updateFilterConfiguration(newConfig)
/// ```
///
/// - Note: All methods must be called from MainActor context.
@Observable
@MainActor
final class FilterState {
    /// Current search query string (updated immediately for UI binding)
    private(set) var searchQuery: String = ""

    /// Debounced search query string (used for actual filtering)
    private(set) var debouncedSearchQuery: String = ""

    /// Active structured filter configuration (persisted)
    private(set) var configuration: FilterConfiguration = .empty

    /// Available filter options (extracted from PR list and GitHub API)
    private(set) var metadata: FilterMetadata = FilterMetadata(organizations: [], repositories: [], teams: .idle)

    /// Current user-facing error message, or nil if no error
    private(set) var errorMessage: String?

    private let persistence: FilterPersistence
    private let timeProvider: TimeProvider
    private let logger = Logger(subsystem: "com.gitreviewit.app", category: "FilterState")

    /// Active debounce task for search query updates
    private var searchTask: Task<Void, Never>?

    /// Initializes filter state with dependencies.
    ///
    /// - Parameters:
    ///   - persistence: Service for saving/loading filter configuration
    ///   - timeProvider: Time provider for debouncing (injectable for testing)
    init(persistence: FilterPersistence, timeProvider: TimeProvider = RealTimeProvider()) {
        self.persistence = persistence
        self.timeProvider = timeProvider
    }

    /// Updates the search query with 300ms debouncing.
    ///
    /// Cancels any pending search updates and schedules a new update after 300ms.
    /// This prevents excessive filtering during rapid typing.
    ///
    /// - Parameter query: The new search query string
    ///
    /// - Note: The query property is updated immediately for UI binding,
    ///         but filtering occurs after the debounce delay.
    func updateSearchQuery(_ query: String) {
        self.searchQuery = query
        searchTask?.cancel()
        searchTask = Task {
            do {
                try await timeProvider.sleep(nanoseconds: 300 * 1_000_000)
            } catch {
                return
            }

            guard !Task.isCancelled else { return }
            self.debouncedSearchQuery = query
        }
    }

    /// Clears the search query immediately.
    ///
    /// Cancels any pending debounced updates and resets the query to empty string.
    func clearSearchQuery() {
        searchTask?.cancel()
        searchTask = nil
        searchQuery = ""
        debouncedSearchQuery = ""
    }

    /// Await completion of any pending search query update. For testing purposes.
    func awaitSearchCompletion() async {
        await searchTask?.value
    }

    /// Updates and persists the filter configuration.
    ///
    /// Saves the configuration to persistent storage and updates the UI state.
    /// If persistence fails, sets an error message but keeps the UI state updated.
    ///
    /// - Parameter newConfiguration: The new filter configuration to apply
    func updateFilterConfiguration(_ newConfiguration: FilterConfiguration) async {
        configuration = newConfiguration
        do {
            try await persistence.save(newConfiguration)
        } catch {
            logger.error("Failed to save filter configuration: \(error.localizedDescription)")
            errorMessage = "Failed to save filter preferences. Your selections may not persist after restart."
        }
    }

    /// Loads persisted filter configuration from storage.
    ///
    /// Should be called on app launch to restore user's previous filter selections.
    /// If loading fails (e.g., corrupted data), clears the storage and sets an error message.
    func loadPersistedConfiguration() async {
        do {
            if let loaded = try await persistence.load() {
                configuration = loaded
            }
        } catch {
            logger.warning(
                "Failed to load filter configuration: \(error.localizedDescription). Clearing corrupted data."
            )
            try? await persistence.clear()
            errorMessage = "Previous filter preferences could not be loaded and have been reset."
        }
    }

    /// Clears all active filters and removes persisted configuration.
    ///
    /// Resets configuration to empty state and clears storage.
    /// If clearing storage fails, sets an error message.
    func clearAllFilters() async {
        configuration = .empty
        do {
            try await persistence.clear()
        } catch {
            logger.error("Failed to clear filter configuration: \(error.localizedDescription)")
            errorMessage = "Failed to clear filter preferences. Some filters may still be saved."
        }
    }

    /// Dismisses the current error message.
    func clearError() {
        errorMessage = nil
    }

    /// Updates filter metadata from pull request list (organizations and repositories only).
    ///
    /// Extracts unique organizations and repositories from the PR list.
    /// Sets teams to idle state (use `updateMetadata(from:api:credentials:)` to fetch teams).
    ///
    /// - Parameter pullRequests: The list of PRs to extract metadata from
    func updateMetadata(from pullRequests: [PullRequest]) {
        metadata = FilterMetadata.from(pullRequests: pullRequests)
    }

    /// Updates filter metadata from PRs and fetches team data from GitHub API.
    ///
    /// First extracts organizations and repositories from PRs, then asynchronously
    /// fetches team data from GitHub. Updates UI progressively:
    /// 1. Immediately sets orgs/repos with teams in loading state
    /// 2. Updates teams to loaded/failed state when API call completes
    ///
    /// If team API fails with 403 (permission denied) or other errors, gracefully
    /// degrades to failed state and clears any invalid team filters from configuration.
    ///
    /// - Parameters:
    ///   - pullRequests: The list of PRs to extract metadata from
    ///   - api: GitHub API client for fetching teams
    ///   - credentials: User's GitHub credentials
    func updateMetadata(
        from pullRequests: [PullRequest],
        api: GitHubAPI,
        credentials: GitHubCredentials
    ) async {
        // Update organizations and repositories synchronously
        let organizations = Set(pullRequests.map { $0.repositoryOwner })
        let repositories = Set(pullRequests.map { $0.repositoryFullName })

        // Set teams to loading state
        metadata = FilterMetadata(
            organizations: organizations,
            repositories: repositories,
            teams: .loading
        )

        // Fetch teams asynchronously
        do {
            let teams = try await api.fetchTeams(credentials: credentials)
            metadata = FilterMetadata(
                organizations: organizations,
                repositories: repositories,
                teams: .loaded(teams)
            )
        } catch {
            guard
                let apiError = error as? APIError
            else {
                logger.error("Failed to fetch teams with unexpected error: \(error.localizedDescription)")
                metadata = FilterMetadata(
                    organizations: organizations,
                    repositories: repositories,
                    teams: .failed(.unknown(error))
                )
                return
            }

            logger.warning("Failed to fetch teams: \(apiError.localizedDescription)")
            metadata = FilterMetadata(
                organizations: organizations,
                repositories: repositories,
                teams: .failed(apiError)
            )

            // Clear invalid team filters if teams unavailable
            await clearInvalidTeamFilters()
        }
    }

    /// Removes team filters from configuration when team data is unavailable.
    ///
    /// Called automatically when team API fails. Persists the updated configuration
    /// without team filters, so invalid selections don't persist across app restarts.
    private func clearInvalidTeamFilters() async {
        guard
            !configuration.selectedTeams.isEmpty
        else {
            return
        }

        logger.info("Clearing team filters due to unavailable team data")
        let clearedConfig = FilterConfiguration(
            version: configuration.version,
            selectedOrganizations: configuration.selectedOrganizations,
            selectedRepositories: configuration.selectedRepositories,
            selectedTeams: []
        )

        await updateFilterConfiguration(clearedConfig)
        errorMessage = "Team filtering is unavailable. Your team filter selections have been cleared."
    }
}
