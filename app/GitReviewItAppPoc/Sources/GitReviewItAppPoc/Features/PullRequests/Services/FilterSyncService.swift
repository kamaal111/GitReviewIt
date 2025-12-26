//
//  FilterSyncService.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 24/12/2025.
//

import Foundation

/// Service responsible for synchronizing organization and repository filter selections.
/// Maintains bidirectional consistency between org and repo selections.
struct FilterSyncService {
    let metadata: FilterMetadata

    /// Selects all repositories from the given organization.
    /// - Parameters:
    ///   - org: The organization name
    ///   - repositories: Current repository selections
    /// - Returns: Updated repository selections including all repos from the org
    func selectAllRepositories(
        from org: String,
        currentRepositories repositories: Set<String>
    ) -> Set<String> {
        var updated = repositories
        for repo in metadata.repositories where repo.starts(with: "\(org)/") {
            updated.insert(repo)
        }
        return updated
    }

    /// Deselects all repositories from the given organization.
    /// - Parameters:
    ///   - org: The organization name
    ///   - repositories: Current repository selections
    /// - Returns: Updated repository selections excluding all repos from the org
    func deselectAllRepositories(
        from org: String,
        currentRepositories repositories: Set<String>
    ) -> Set<String> {
        repositories.filter { !$0.starts(with: "\(org)/") }
    }

    /// Syncs organization selections based on repository selections.
    /// An organization is automatically selected if ALL its repositories are selected.
    /// An organization is automatically deselected if only SOME of its repositories are selected.
    /// - Parameters:
    ///   - repositories: Current repository selections
    ///   - organizations: Current organization selections
    /// - Returns: Updated organization selections synced with repository state
    func syncOrganizations(
        basedOn repositories: Set<String>,
        currentOrganizations organizations: Set<String>
    ) -> Set<String> {
        // Group repositories by organization
        var reposByOrg: [String: Set<String>] = [:]
        for repo in metadata.repositories {
            guard let slashIndex = repo.firstIndex(of: "/") else {
                continue
            }
            let org = String(repo[..<slashIndex])
            reposByOrg[org, default: []].insert(repo)
        }

        var updatedOrganizations = organizations

        // Update organization selections
        for org in metadata.organizations {
            guard let orgRepos = reposByOrg[org] else {
                continue
            }

            let selectedOrgRepos = repositories.intersection(orgRepos)

            if selectedOrgRepos.count == orgRepos.count {
                // All repos from this org are selected → select the org
                updatedOrganizations.insert(org)
            } else if !selectedOrgRepos.isEmpty {
                // Some (but not all) repos from this org are selected → deselect the org
                updatedOrganizations.remove(org)
            }
            // If no repos from this org are selected, leave org selection as-is
        }

        return updatedOrganizations
    }
}
