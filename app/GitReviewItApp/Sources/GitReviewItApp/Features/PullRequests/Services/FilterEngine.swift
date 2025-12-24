//
//  FilterEngine.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 23/12/2025.
//

import Foundation

protocol FilterEngineProtocol {
    func apply(
        configuration: FilterConfiguration,
        searchQuery: String,
        to pullRequests: [PullRequest],
        teamMetadata: [Team]
    ) -> [PullRequest]
}

struct FilterEngine: FilterEngineProtocol {
    private let fuzzyMatcher: FuzzyMatcherProtocol

    init(fuzzyMatcher: FuzzyMatcherProtocol = FuzzyMatcher()) {
        self.fuzzyMatcher = fuzzyMatcher
    }

    func apply(
        configuration: FilterConfiguration,
        searchQuery: String,
        to pullRequests: [PullRequest],
        teamMetadata: [Team]
    ) -> [PullRequest] {
        var filtered = pullRequests

        // 1. Organization Filter
        if !configuration.selectedOrganizations.isEmpty {
            filtered = filtered.filter { configuration.selectedOrganizations.contains($0.repositoryOwner) }
        }

        // 2. Repository Filter
        if !configuration.selectedRepositories.isEmpty {
            filtered = filtered.filter { configuration.selectedRepositories.contains($0.repositoryFullName) }
        }

        // 3. Team Filter
        if !configuration.selectedTeams.isEmpty {
            let teamRepositories = Set(
                teamMetadata
                    .filter { configuration.selectedTeams.contains($0.slug) }
                    .flatMap { $0.repositories }
            )
            filtered = filtered.filter { teamRepositories.contains($0.repositoryFullName) }
        }

        // 4. Fuzzy Search
        if !searchQuery.isEmpty {
            filtered = fuzzyMatcher.match(query: searchQuery, in: filtered)
        }

        return filtered
    }
}
