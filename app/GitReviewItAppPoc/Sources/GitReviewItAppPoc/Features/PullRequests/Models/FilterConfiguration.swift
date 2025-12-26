//
//  FilterConfiguration.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 23/12/2025.
//

import Foundation

/// Configuration defining active filters for the pull request list.
///
/// Persisted to disk to restore user preferences across sessions.
struct FilterConfiguration: Codable, Equatable {
    /// Schema version for migration support
    let version: Int

    /// Selected organization names (e.g., "apple")
    let selectedOrganizations: Set<String>

    /// Selected repository full names (e.g., "apple/swift")
    let selectedRepositories: Set<String>

    /// Selected team slugs (e.g., "apple/core-team")
    let selectedTeams: Set<String>

    /// Default empty configuration (no filters applied)
    static let empty = FilterConfiguration(
        version: 1,
        selectedOrganizations: [],
        selectedRepositories: [],
        selectedTeams: []
    )
}
