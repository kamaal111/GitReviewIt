//
//  FilterMetadata.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 23/12/2025.
//

import Foundation

struct FilterMetadata {
    let organizations: Set<String>
    let repositories: Set<String>
    let teams: LoadingState<[Team]>

    var areTeamsAvailable: Bool {
        if case .failed = teams { return false }
        return true
    }

    var sortedOrganizations: [String] {
        organizations.sorted()
    }

    var sortedRepositories: [String] {
        repositories.sorted()
    }

    static func from(pullRequests: [PullRequest]) -> FilterMetadata {
        let organizations = Set(pullRequests.map { $0.repositoryOwner })
        let repositories = Set(pullRequests.map { $0.repositoryName })
        return FilterMetadata(
            organizations: organizations,
            repositories: repositories,
            teams: .idle
        )
    }
}
