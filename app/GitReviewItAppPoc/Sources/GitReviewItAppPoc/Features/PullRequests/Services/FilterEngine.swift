//
//  FilterEngine.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 23/12/2025.
//

import Foundation

/// Protocol defining the filtering pipeline for pull requests.
///
/// The filter engine applies a two-stage filtering pipeline:
/// 1. **Structured filters** (organization, repository, team) - filters PRs that don't match
/// 2. **Fuzzy search** - ranks matching PRs by relevance
///
/// This design ensures structured filters always take precedence, and fuzzy search
/// only ranks PRs that pass all structured filters.
protocol FilterEngineProtocol {
    /// Applies filters and search to a list of pull requests.
    ///
    /// - Parameters:
    ///   - configuration: The structured filter configuration (org, repo, team filters)
    ///   - searchQuery: The fuzzy search query string
    ///   - pullRequests: The complete list of PRs to filter
    ///   - teamMetadata: Team data for resolving team filters to repositories
    /// - Returns: Filtered and ranked pull requests matching all criteria
    func apply(
        configuration: FilterConfiguration,
        searchQuery: String,
        to pullRequests: [PullRequest],
        teamMetadata: [Team]
    ) -> [PullRequest]
}

/// Implementation of the PR filtering pipeline.
///
/// **Performance**: Designed to handle up to 500 PRs with <500ms filtering time.
/// All operations are synchronous and execute on the caller's thread.
///
/// **Pipeline stages**:
/// 1. Organization filter - keeps only PRs from selected organizations
/// 2. Repository filter - keeps only PRs from selected repositories
/// 3. Team filter - keeps only PRs from repositories belonging to selected teams
/// 4. Fuzzy search - ranks remaining PRs by search relevance
///
/// **Example**:
/// ```swift
/// let engine = FilterEngine()
/// let config = FilterConfiguration(
///     version: 1,
///     selectedOrganizations: ["apple"],
///     selectedRepositories: [],
///     selectedTeams: []
/// )
/// let results = engine.apply(
///     configuration: config,
///     searchQuery: "fix bug",
///     to: allPRs,
///     teamMetadata: teams
/// )
/// // Returns: PRs from "apple" org matching "fix bug", ranked by relevance
/// ```
struct FilterEngine: FilterEngineProtocol {
    private let fuzzyMatcher: FuzzyMatcherProtocol

    init(fuzzyMatcher: FuzzyMatcherProtocol = FuzzyMatcher()) {
        self.fuzzyMatcher = fuzzyMatcher
    }

    /// Applies the complete filtering pipeline to pull requests.
    ///
    /// The pipeline executes in order:
    /// 1. Organization filter (if any orgs selected)
    /// 2. Repository filter (if any repos selected)
    /// 3. Team filter (if any teams selected)
    /// 4. Fuzzy search (if query is non-empty)
    ///
    /// - Parameters:
    ///   - configuration: Active structured filter selections
    ///   - searchQuery: User's search query (can be empty)
    ///   - pullRequests: All available PRs to filter
    ///   - teamMetadata: Team data for team filter resolution
    /// - Returns: PRs matching all filters, ranked by relevance if search is active
    ///
    /// - Note: Filters are applied with AND logic - PRs must match ALL active filters.
    ///         Empty filter arrays are treated as "no filter" (all PRs pass).
    func apply(
        configuration: FilterConfiguration,
        searchQuery: String,
        to pullRequests: [PullRequest],
        teamMetadata: [Team]
    ) -> [PullRequest] {
        var filtered = pullRequests

        // Stage 1: Organization Filter
        // Only keep PRs from selected organizations
        if !configuration.selectedOrganizations.isEmpty {
            filtered = filtered.filter { configuration.selectedOrganizations.contains($0.repositoryOwner) }
        }

        // Stage 2: Repository Filter
        // Only keep PRs from selected repositories (full name: "owner/repo")
        if !configuration.selectedRepositories.isEmpty {
            filtered = filtered.filter { configuration.selectedRepositories.contains($0.repositoryFullName) }
        }

        // Stage 3: Team Filter
        // Map selected teams to their repositories, then filter PRs
        if !configuration.selectedTeams.isEmpty {
            let teamRepositories = Set(
                teamMetadata
                    .filter { configuration.selectedTeams.contains($0.fullSlug) }
                    .flatMap { $0.repositories }
            )
            filtered = filtered.filter { teamRepositories.contains($0.repositoryFullName) }
        }

        // Stage 4: Fuzzy Search
        // Rank PRs by search relevance (returns empty if query is empty)
        if !searchQuery.isEmpty {
            filtered = fuzzyMatcher.match(query: searchQuery, in: filtered)
        }

        return filtered
    }
}
