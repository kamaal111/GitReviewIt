//
//  FilterSyncServiceTests.swift
//  GitReviewItAppTests
//
//  Created by Kamaal M Farah on 24/12/2025.
//

import Testing
import Foundation
@testable import GitReviewItAppPoc

@Suite("Filter Sync Service Tests")
struct FilterSyncServiceTests {
    let metadata = FilterMetadata(
        organizations: ["Microsoft", "Google", "Apple"],
        repositories: [
            "Microsoft/VSCode",
            "Microsoft/TypeScript",
            "Google/Chrome",
            "Google/Android",
            "Apple/Swift",
            "Apple/WebKit"
        ],
        teams: .idle
    )

    @Test("Selecting org selects all its repos")
    func selectOrgSelectsAllRepos() {
        let service = FilterSyncService(metadata: metadata)
        let initialRepos: Set<String> = []

        let updatedRepos = service.selectAllRepositories(
            from: "Microsoft",
            currentRepositories: initialRepos
        )

        #expect(updatedRepos.contains("Microsoft/VSCode"))
        #expect(updatedRepos.contains("Microsoft/TypeScript"))
        #expect(updatedRepos.count == 2)
    }

    @Test("Selecting org preserves other repo selections")
    func selectOrgPreservesOtherRepos() {
        let service = FilterSyncService(metadata: metadata)
        let initialRepos: Set<String> = ["Google/Chrome"]

        let updatedRepos = service.selectAllRepositories(
            from: "Microsoft",
            currentRepositories: initialRepos
        )

        #expect(updatedRepos.contains("Microsoft/VSCode"))
        #expect(updatedRepos.contains("Microsoft/TypeScript"))
        #expect(updatedRepos.contains("Google/Chrome"))
        #expect(updatedRepos.count == 3)
    }

    @Test("Deselecting org removes all its repos")
    func deselectOrgRemovesAllRepos() {
        let service = FilterSyncService(metadata: metadata)
        let initialRepos: Set<String> = ["Microsoft/VSCode", "Microsoft/TypeScript", "Google/Chrome"]

        let updatedRepos = service.deselectAllRepositories(
            from: "Microsoft",
            currentRepositories: initialRepos
        )

        #expect(!updatedRepos.contains("Microsoft/VSCode"))
        #expect(!updatedRepos.contains("Microsoft/TypeScript"))
        #expect(updatedRepos.contains("Google/Chrome"))
        #expect(updatedRepos.count == 1)
    }

    @Test("Deselecting org preserves other repo selections")
    func deselectOrgPreservesOtherRepos() {
        let service = FilterSyncService(metadata: metadata)
        let initialRepos: Set<String> = [
            "Microsoft/VSCode",
            "Google/Chrome",
            "Apple/Swift"
        ]

        let updatedRepos = service.deselectAllRepositories(
            from: "Microsoft",
            currentRepositories: initialRepos
        )

        #expect(updatedRepos.contains("Google/Chrome"))
        #expect(updatedRepos.contains("Apple/Swift"))
        #expect(updatedRepos.count == 2)
    }

    @Test("Sync selects org when all repos selected")
    func syncSelectsOrgWhenAllReposSelected() {
        let service = FilterSyncService(metadata: metadata)
        let repos: Set<String> = ["Microsoft/VSCode", "Microsoft/TypeScript"]
        let orgs: Set<String> = []

        let updatedOrgs = service.syncOrganizations(
            basedOn: repos,
            currentOrganizations: orgs
        )

        #expect(updatedOrgs.contains("Microsoft"))
        #expect(updatedOrgs.count == 1)
    }

    @Test("Sync deselects org when only some repos selected")
    func syncDeselectsOrgWhenSomeReposSelected() {
        let service = FilterSyncService(metadata: metadata)
        let repos: Set<String> = ["Microsoft/VSCode"] // Only 1 of 2 Microsoft repos
        let orgs: Set<String> = ["Microsoft"]

        let updatedOrgs = service.syncOrganizations(
            basedOn: repos,
            currentOrganizations: orgs
        )

        #expect(!updatedOrgs.contains("Microsoft"))
        #expect(updatedOrgs.isEmpty)
    }

    @Test("Sync leaves org unchanged when no repos selected")
    func syncLeavesOrgUnchangedWhenNoReposSelected() {
        let service = FilterSyncService(metadata: metadata)
        let repos: Set<String> = ["Google/Chrome"]
        let orgs: Set<String> = ["Microsoft"]

        let updatedOrgs = service.syncOrganizations(
            basedOn: repos,
            currentOrganizations: orgs
        )

        #expect(updatedOrgs.contains("Microsoft"))
        #expect(updatedOrgs.count == 1)
    }

    @Test("Sync handles multiple orgs correctly")
    func syncHandlesMultipleOrgs() {
        let service = FilterSyncService(metadata: metadata)
        let repos: Set<String> = [
            "Microsoft/VSCode",
            "Microsoft/TypeScript",
            "Google/Chrome",
            "Apple/Swift"
        ]
        let orgs: Set<String> = []

        let updatedOrgs = service.syncOrganizations(
            basedOn: repos,
            currentOrganizations: orgs
        )

        #expect(updatedOrgs.contains("Microsoft")) // All Microsoft repos
        #expect(!updatedOrgs.contains("Google")) // Only 1 of 2 Google repos
        #expect(!updatedOrgs.contains("Apple")) // Only 1 of 2 Apple repos
        #expect(updatedOrgs.count == 1)
    }

    @Test("Sync preserves unrelated org selections")
    func syncPreservesUnrelatedOrgSelections() {
        let service = FilterSyncService(metadata: metadata)
        let repos: Set<String> = ["Microsoft/VSCode"]
        let orgs: Set<String> = ["Google", "Apple"]

        let updatedOrgs = service.syncOrganizations(
            basedOn: repos,
            currentOrganizations: orgs
        )

        #expect(updatedOrgs.contains("Google"))
        #expect(updatedOrgs.contains("Apple"))
        #expect(!updatedOrgs.contains("Microsoft"))
    }

    @Test("Sync with empty repos keeps org selections")
    func syncWithEmptyReposKeepsOrgSelections() {
        let service = FilterSyncService(metadata: metadata)
        let repos: Set<String> = []
        let orgs: Set<String> = ["Microsoft", "Google"]

        let updatedOrgs = service.syncOrganizations(
            basedOn: repos,
            currentOrganizations: orgs
        )

        #expect(updatedOrgs.contains("Microsoft"))
        #expect(updatedOrgs.contains("Google"))
        #expect(updatedOrgs.count == 2)
    }

    @Test("Round trip: select org then sync maintains consistency")
    func roundTripSelectOrgThenSync() {
        let service = FilterSyncService(metadata: metadata)

        // Step 1: User selects Microsoft org
        let repos1 = service.selectAllRepositories(
            from: "Microsoft",
            currentRepositories: []
        )

        // Step 2: Sync orgs based on repo selection
        let orgs = service.syncOrganizations(
            basedOn: repos1,
            currentOrganizations: []
        )

        #expect(orgs.contains("Microsoft"))
        #expect(repos1.contains("Microsoft/VSCode"))
        #expect(repos1.contains("Microsoft/TypeScript"))
    }

    @Test("Round trip: select individual repos then sync updates org")
    func roundTripSelectReposThenSync() {
        let service = FilterSyncService(metadata: metadata)
        let initialOrgs: Set<String> = []
        var repos: Set<String> = []

        // Step 1: User selects first Microsoft repo
        repos.insert("Microsoft/VSCode")
        let orgs1 = service.syncOrganizations(
            basedOn: repos,
            currentOrganizations: initialOrgs
        )

        #expect(!orgs1.contains("Microsoft")) // Not all repos selected

        // Step 2: User selects second Microsoft repo
        repos.insert("Microsoft/TypeScript")
        let orgs2 = service.syncOrganizations(
            basedOn: repos,
            currentOrganizations: orgs1
        )

        #expect(orgs2.contains("Microsoft")) // All repos now selected
    }

    @Test("Round trip: deselect org then sync removes repos")
    func roundTripDeselectOrgThenSync() {
        let service = FilterSyncService(metadata: metadata)
        let initialRepos: Set<String> = ["Microsoft/VSCode", "Microsoft/TypeScript"]
        let initialOrgs: Set<String> = ["Microsoft"]

        // Step 1: User deselects Microsoft org
        let repos = service.deselectAllRepositories(
            from: "Microsoft",
            currentRepositories: initialRepos
        )

        #expect(repos.isEmpty)

        // Step 2: Sync orgs (should remove Microsoft since no repos selected)
        let orgs = service.syncOrganizations(
            basedOn: repos,
            currentOrganizations: initialOrgs
        )

        #expect(orgs.contains("Microsoft")) // Stays selected when no repos (as per spec)
    }
}
