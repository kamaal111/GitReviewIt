//
//  FilterMetadata.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 23/12/2025.
//

import Foundation

/// Metadata containing available options for filtering pull requests.
///
/// Derived from the loaded pull requests and fetched team data.
/// Used to populate filter options in the filter sheet.
struct FilterMetadata {
    /// Set of available organization names
    let organizations: Set<String>

    /// Set of available repository full names ("owner/repo")
    let repositories: Set<String>

    /// Loading state of user's teams
    let teams: LoadingState<[Team]>

    /// Whether team data is available (not failed)
    var areTeamsAvailable: Bool {
        if case .failed = teams { return false }
        return true
    }

    /// Organizations sorted alphabetically
    var sortedOrganizations: [String] {
        organizations.sorted()
    }

    /// Repositories sorted alphabetically
    var sortedRepositories: [String] {
        repositories.sorted()
    }

    /// Creates metadata from a list of pull requests.
    /// - Parameter pullRequests: The list of PRs to extract metadata from
    /// - Returns: New metadata instance with organizations and repositories populated
    static func from(pullRequests: [PullRequest]) -> FilterMetadata {
        let organizations = Set(pullRequests.map { $0.repositoryOwner })
        let repositories = Set(pullRequests.map { $0.repositoryFullName })
        return FilterMetadata(
            organizations: organizations,
            repositories: repositories,
            teams: .idle
        )
    }
}
