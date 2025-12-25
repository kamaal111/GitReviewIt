//
//  PRFilteringTests.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 24/12/2025.
//

import Foundation
import Testing

@testable import GitReviewItApp

@Suite("PR Filtering Integration Tests")
struct PRFilteringTests {
    private let engine = FilterEngine()
    private let now = Date()
    private let url = URL(string: "https://github.com")!

    // MARK: - Organization Filtering

    @Test
    func `Filter by single organization shows only that org PRs`() {
        let pr1 = makePR(owner: "CompanyA", repo: "Repo1")
        let pr2 = makePR(owner: "CompanyB", repo: "Repo2")
        let pr3 = makePR(owner: "CompanyA", repo: "Repo3")

        let config = FilterConfiguration(
            version: 1,
            selectedOrganizations: ["CompanyA"],
            selectedRepositories: [],
            selectedTeams: []
        )

        let result = engine.apply(
            configuration: config,
            searchQuery: "",
            to: [pr1, pr2, pr3],
            teamMetadata: []
        )

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.repositoryOwner == "CompanyA" })
    }

    @Test
    func `Filter by multiple organizations shows all selected orgs`() {
        let pr1 = makePR(owner: "CompanyA")
        let pr2 = makePR(owner: "CompanyB")
        let pr3 = makePR(owner: "CompanyC")

        let config = FilterConfiguration(
            version: 1,
            selectedOrganizations: ["CompanyA", "CompanyB"],
            selectedRepositories: [],
            selectedTeams: []
        )

        let result = engine.apply(
            configuration: config,
            searchQuery: "",
            to: [pr1, pr2, pr3],
            teamMetadata: []
        )

        #expect(result.count == 2)
        let owners = Set(result.map { $0.repositoryOwner })
        #expect(owners == ["CompanyA", "CompanyB"])
    }

    // MARK: - Repository Filtering

    @Test
    func `Filter by single repository shows only that repo PRs`() {
        let pr1 = makePR(owner: "CompanyA", repo: "backend-service")
        let pr2 = makePR(owner: "CompanyA", repo: "frontend")
        let pr3 = makePR(owner: "CompanyB", repo: "api")

        let config = FilterConfiguration(
            version: 1,
            selectedOrganizations: [],
            selectedRepositories: ["CompanyA/backend-service"],
            selectedTeams: []
        )

        let result = engine.apply(
            configuration: config,
            searchQuery: "",
            to: [pr1, pr2, pr3],
            teamMetadata: []
        )

        #expect(result.count == 1)
        #expect(result.first?.repositoryFullName == "CompanyA/backend-service")
    }

    @Test
    func `Filter by multiple repositories shows all selected repos`() {
        let pr1 = makePR(owner: "CompanyA", repo: "backend")
        let pr2 = makePR(owner: "CompanyA", repo: "frontend")
        let pr3 = makePR(owner: "CompanyB", repo: "api")

        let config = FilterConfiguration(
            version: 1,
            selectedOrganizations: [],
            selectedRepositories: ["CompanyA/backend", "CompanyB/api"],
            selectedTeams: []
        )

        let result = engine.apply(
            configuration: config,
            searchQuery: "",
            to: [pr1, pr2, pr3],
            teamMetadata: []
        )

        #expect(result.count == 2)
        let repos = Set(result.map { $0.repositoryFullName })
        #expect(repos == ["CompanyA/backend", "CompanyB/api"])
    }

    // MARK: - Combined Filtering

    @Test
    func `Combining org and repo filters applies AND logic`() {
        let pr1 = makePR(owner: "CompanyA", repo: "backend")
        let pr2 = makePR(owner: "CompanyA", repo: "frontend")
        let pr3 = makePR(owner: "CompanyB", repo: "backend")

        let config = FilterConfiguration(
            version: 1,
            selectedOrganizations: ["CompanyA"],
            selectedRepositories: ["CompanyA/backend"],
            selectedTeams: []
        )

        let result = engine.apply(
            configuration: config,
            searchQuery: "",
            to: [pr1, pr2, pr3],
            teamMetadata: []
        )

        #expect(result.count == 1)
        #expect(result.first?.repositoryFullName == "CompanyA/backend")
    }

    @Test
    func `Org filter with multiple repo filters shows intersection`() {
        let pr1 = makePR(owner: "CompanyA", repo: "backend")
        let pr2 = makePR(owner: "CompanyA", repo: "frontend")
        let pr3 = makePR(owner: "CompanyB", repo: "api")
        let pr4 = makePR(owner: "CompanyA", repo: "mobile")

        let config = FilterConfiguration(
            version: 1,
            selectedOrganizations: ["CompanyA"],
            selectedRepositories: ["CompanyA/backend", "CompanyA/frontend"],
            selectedTeams: []
        )

        let result = engine.apply(
            configuration: config,
            searchQuery: "",
            to: [pr1, pr2, pr3, pr4],
            teamMetadata: []
        )

        #expect(result.count == 2)
        let repos = Set(result.map { $0.repositoryFullName })
        #expect(repos == ["CompanyA/backend", "CompanyA/frontend"])
    }

    // MARK: - Empty States

    @Test
    func `Filter with no matches returns empty array`() {
        let pr1 = makePR(owner: "CompanyA")
        let pr2 = makePR(owner: "CompanyB")

        let config = FilterConfiguration(
            version: 1,
            selectedOrganizations: ["CompanyC"],
            selectedRepositories: [],
            selectedTeams: []
        )

        let result = engine.apply(
            configuration: config,
            searchQuery: "",
            to: [pr1, pr2],
            teamMetadata: []
        )

        #expect(result.isEmpty)
    }

    @Test
    func `Empty configuration returns all PRs`() {
        let pr1 = makePR()
        let pr2 = makePR()
        let pr3 = makePR()

        let result = engine.apply(
            configuration: .empty,
            searchQuery: "",
            to: [pr1, pr2, pr3],
            teamMetadata: []
        )

        #expect(result.count == 3)
    }

    // MARK: - Metadata Extraction

    @Test
    func `FilterMetadata extracts unique organizations from PRs`() {
        let pr1 = makePR(owner: "CompanyA")
        let pr2 = makePR(owner: "CompanyB")
        let pr3 = makePR(owner: "CompanyA")

        let metadata = FilterMetadata.from(pullRequests: [pr1, pr2, pr3])

        #expect(metadata.organizations.count == 2)
        #expect(metadata.organizations.contains("CompanyA"))
        #expect(metadata.organizations.contains("CompanyB"))
    }

    @Test
    func `FilterMetadata extracts unique repositories from PRs`() {
        let pr1 = makePR(owner: "CompanyA", repo: "backend")
        let pr2 = makePR(owner: "CompanyA", repo: "frontend")
        let pr3 = makePR(owner: "CompanyB", repo: "api")
        let pr4 = makePR(owner: "CompanyA", repo: "backend")  // duplicate

        let metadata = FilterMetadata.from(pullRequests: [pr1, pr2, pr3, pr4])

        #expect(metadata.repositories.count == 3)
        #expect(metadata.repositories.contains("CompanyA/backend"))
        #expect(metadata.repositories.contains("CompanyA/frontend"))
        #expect(metadata.repositories.contains("CompanyB/api"))
    }

    @Test
    func `FilterMetadata sorts organizations alphabetically`() {
        let pr1 = makePR(owner: "Zebra")
        let pr2 = makePR(owner: "Apple")
        let pr3 = makePR(owner: "Microsoft")

        let metadata = FilterMetadata.from(pullRequests: [pr1, pr2, pr3])

        #expect(metadata.sortedOrganizations == ["Apple", "Microsoft", "Zebra"])
    }

    @Test
    func `FilterMetadata sorts repositories alphabetically`() {
        let pr1 = makePR(repo: "zulu")
        let pr2 = makePR(repo: "alpha")
        let pr3 = makePR(repo: "bravo")

        let metadata = FilterMetadata.from(pullRequests: [pr1, pr2, pr3])

        #expect(metadata.sortedRepositories == ["owner/alpha", "owner/bravo", "owner/zulu"])
    }

    @Test
    func `Repository filter works with metadata extracted repositories`() {
        // This test simulates the real-world scenario where:
        // 1. User sees PRs in the list
        // 2. FilterMetadata extracts available repositories
        // 3. User selects a repository from FilterSheet
        // 4. FilterEngine filters using the selected repository
        let pr1 = makePR(owner: "CompanyA", repo: "backend")
        let pr2 = makePR(owner: "CompanyA", repo: "frontend")
        let pr3 = makePR(owner: "CompanyB", repo: "api")

        // Extract metadata (simulates what FilterState.updateMetadata does)
        let metadata = FilterMetadata.from(pullRequests: [pr1, pr2, pr3])

        // User selects the first repository from the available list
        let selectedRepo = metadata.sortedRepositories[0]  // Will be "api"

        let config = FilterConfiguration(
            version: 1,
            selectedOrganizations: [],
            selectedRepositories: [selectedRepo],
            selectedTeams: []
        )

        let result = engine.apply(
            configuration: config,
            searchQuery: "",
            to: [pr1, pr2, pr3],
            teamMetadata: []
        )

        // Should find the matching PR, but won't because of the bug
        #expect(result.count == 1, "Expected to find 1 PR matching repository '\(selectedRepo)'")
        #expect(result.first?.repositoryFullName == selectedRepo)
    }

    // MARK: - Combined Search and Filters

    @Test
    func `Combine organization filter and search query`() {
        let pr1 = makePR(owner: "CompanyA", title: "Fix bug")
        let pr2 = makePR(owner: "CompanyA", title: "Add feature")
        let pr3 = makePR(owner: "CompanyB", title: "Fix bug")

        let config = FilterConfiguration(
            version: 1,
            selectedOrganizations: ["CompanyA"],
            selectedRepositories: [],
            selectedTeams: []
        )

        let result = engine.apply(
            configuration: config,
            searchQuery: "Fix",
            to: [pr1, pr2, pr3],
            teamMetadata: []
        )

        #expect(result.count == 1)
        #expect(result.first?.repositoryOwner == "CompanyA")
        #expect(result.first?.title == "Fix bug")
    }

    @Test
    func `Combine repository filter and search query`() {
        let pr1 = makePR(owner: "CompanyA", repo: "backend", title: "Update API")
        let pr2 = makePR(owner: "CompanyA", repo: "backend", title: "Fix typo")
        let pr3 = makePR(owner: "CompanyA", repo: "frontend", title: "Update API")

        let config = FilterConfiguration(
            version: 1,
            selectedOrganizations: [],
            selectedRepositories: ["CompanyA/backend"],
            selectedTeams: []
        )

        let result = engine.apply(
            configuration: config,
            searchQuery: "API",
            to: [pr1, pr2, pr3],
            teamMetadata: []
        )

        #expect(result.count == 1)
        #expect(result.first?.repositoryFullName == "CompanyA/backend")
        #expect(result.first?.title == "Update API")
    }

    // MARK: - Team Filtering

    @Test
    func `Filter by single team shows only repos in that team`() {
        let pr1 = makePR(owner: "CompanyA", repo: "backend-service")
        let pr2 = makePR(owner: "CompanyA", repo: "frontend")
        let pr3 = makePR(owner: "CompanyB", repo: "api")

        let backendTeam = Team(
            slug: "backend-team",
            name: "Backend Team",
            organizationLogin: "CompanyA",
            repositories: ["CompanyA/backend-service"]
        )

        let config = FilterConfiguration(
            version: 1,
            selectedOrganizations: [],
            selectedRepositories: [],
            selectedTeams: ["CompanyA/backend-team"]
        )

        let result = engine.apply(
            configuration: config,
            searchQuery: "",
            to: [pr1, pr2, pr3],
            teamMetadata: [backendTeam]
        )

        #expect(result.count == 1)
        #expect(result.first?.repositoryFullName == "CompanyA/backend-service")
    }

    @Test
    func `Filter by multiple teams shows repos from all selected teams`() {
        let pr1 = makePR(owner: "CompanyA", repo: "backend")
        let pr2 = makePR(owner: "CompanyA", repo: "frontend")
        let pr3 = makePR(owner: "CompanyA", repo: "mobile")

        let backendTeam = Team(
            slug: "backend-team",
            name: "Backend Team",
            organizationLogin: "CompanyA",
            repositories: ["CompanyA/backend"]
        )

        let frontendTeam = Team(
            slug: "frontend-team",
            name: "Frontend Team",
            organizationLogin: "CompanyA",
            repositories: ["CompanyA/frontend"]
        )

        let config = FilterConfiguration(
            version: 1,
            selectedOrganizations: [],
            selectedRepositories: [],
            selectedTeams: ["CompanyA/backend-team", "CompanyA/frontend-team"]
        )

        let result = engine.apply(
            configuration: config,
            searchQuery: "",
            to: [pr1, pr2, pr3],
            teamMetadata: [backendTeam, frontendTeam]
        )

        #expect(result.count == 2)

        let repos = Set(result.map { $0.repositoryFullName })
        #expect(repos == ["CompanyA/backend", "CompanyA/frontend"])
    }

    @Test
    func `Team filter with empty team metadata returns no results`() {
        let pr1 = makePR(owner: "CompanyA", repo: "backend")
        let pr2 = makePR(owner: "CompanyA", repo: "frontend")

        let config = FilterConfiguration(
            version: 1,
            selectedOrganizations: [],
            selectedRepositories: [],
            selectedTeams: ["CompanyA/backend-team"]
        )

        // No teams available - simulates graceful degradation
        let result = engine.apply(
            configuration: config,
            searchQuery: "",
            to: [pr1, pr2],
            teamMetadata: []
        )

        #expect(result.isEmpty)
    }

    @Test
    func `Team filter with team that has multiple repositories`() {
        let pr1 = makePR(owner: "CompanyA", repo: "service-a")
        let pr2 = makePR(owner: "CompanyA", repo: "service-b")
        let pr3 = makePR(owner: "CompanyA", repo: "service-c")

        let infraTeam = Team(
            slug: "infra-team",
            name: "Infrastructure Team",
            organizationLogin: "CompanyA",
            repositories: ["CompanyA/service-a", "CompanyA/service-b"]
        )

        let config = FilterConfiguration(
            version: 1,
            selectedOrganizations: [],
            selectedRepositories: [],
            selectedTeams: ["CompanyA/infra-team"]
        )

        let result = engine.apply(
            configuration: config,
            searchQuery: "",
            to: [pr1, pr2, pr3],
            teamMetadata: [infraTeam]
        )

        #expect(result.count == 2)

        let repos = Set(result.map { $0.repositoryFullName })
        #expect(repos == ["CompanyA/service-a", "CompanyA/service-b"])
    }

    @Test
    func `Combine organization and team filters (AND logic)`() {
        let pr1 = makePR(owner: "CompanyA", repo: "backend")
        let pr2 = makePR(owner: "CompanyB", repo: "backend")
        let pr3 = makePR(owner: "CompanyA", repo: "frontend")

        let backendTeam = Team(
            slug: "backend-team",
            name: "Backend Team",
            organizationLogin: "CompanyA",
            repositories: ["CompanyA/backend", "CompanyB/backend"]
        )

        let config = FilterConfiguration(
            version: 1,
            selectedOrganizations: ["CompanyA"],
            selectedRepositories: [],
            selectedTeams: ["CompanyA/backend-team"]
        )

        let result = engine.apply(
            configuration: config,
            searchQuery: "",
            to: [pr1, pr2, pr3],
            teamMetadata: [backendTeam]
        )

        // Should only show CompanyA/backend (matches both org and team)
        #expect(result.count == 1)
        #expect(result.first?.repositoryFullName == "CompanyA/backend")
    }

    @Test
    func `Combine team filter and search query`() {
        let pr1 = makePR(owner: "CompanyA", repo: "backend", title: "Fix API bug")
        let pr2 = makePR(owner: "CompanyA", repo: "backend", title: "Update docs")
        let pr3 = makePR(owner: "CompanyA", repo: "frontend", title: "Fix API bug")

        let backendTeam = Team(
            slug: "backend-team",
            name: "Backend Team",
            organizationLogin: "CompanyA",
            repositories: ["CompanyA/backend"]
        )

        let config = FilterConfiguration(
            version: 1,
            selectedOrganizations: [],
            selectedRepositories: [],
            selectedTeams: ["CompanyA/backend-team"]
        )

        let result = engine.apply(
            configuration: config,
            searchQuery: "API",
            to: [pr1, pr2, pr3],
            teamMetadata: [backendTeam]
        )

        #expect(result.count == 1)
        #expect(result.first?.repositoryFullName == "CompanyA/backend")
        #expect(result.first?.title == "Fix API bug")
    }

    @Test
    func `Teams with same name in different orgs are filtered independently`() {
        // Regression test: Selecting "backend-team" from CompanyA should not select
        // "backend-team" from CompanyB (issue where team.slug was used instead of team.fullSlug)
        let pr1 = makePR(owner: "CompanyA", repo: "service-a")
        let pr2 = makePR(owner: "CompanyB", repo: "service-b")
        let pr3 = makePR(owner: "CompanyC", repo: "service-c")

        let companyABackendTeam = Team(
            slug: "backend-team",
            name: "Backend Team",
            organizationLogin: "CompanyA",
            repositories: ["CompanyA/service-a"]
        )

        let companyBBackendTeam = Team(
            slug: "backend-team",  // Same slug, different org
            name: "Backend Team",
            organizationLogin: "CompanyB",
            repositories: ["CompanyB/service-b"]
        )

        // Only select CompanyA's backend-team, NOT CompanyB's
        let config = FilterConfiguration(
            version: 1,
            selectedOrganizations: [],
            selectedRepositories: [],
            selectedTeams: ["CompanyA/backend-team"]  // fullSlug format: org/slug
        )

        let result = engine.apply(
            configuration: config,
            searchQuery: "",
            to: [pr1, pr2, pr3],
            teamMetadata: [companyABackendTeam, companyBBackendTeam]
        )

        // Should only include PRs from CompanyA's backend-team
        #expect(result.count == 1)
        #expect(result.first?.repositoryFullName == "CompanyA/service-a")
        #expect(result.first?.repositoryOwner == "CompanyA")

        // Verify CompanyB's repos are NOT included
        let owners = Set(result.map { $0.repositoryOwner })
        #expect(owners == ["CompanyA"])
        #expect(!owners.contains("CompanyB"))
    }

    // MARK: - Preview Metadata Compatibility

    @Test
    func `Filtering works correctly with preview metadata enabled`() {
        let metadata = PRPreviewMetadata(
            additions: 100,
            deletions: 50,
            changedFiles: 5,
            requestedReviewers: [Reviewer(login: "reviewer1", avatarURL: nil)],
            completedReviewers: []
        )

        var pr1 = makePR(owner: "CompanyA", repo: "Repo1")
        pr1.previewMetadata = metadata

        var pr2 = makePR(owner: "CompanyB", repo: "Repo2")
        pr2.previewMetadata = metadata

        var pr3 = makePR(owner: "CompanyA", repo: "Repo3")
        pr3.previewMetadata = nil

        let config = FilterConfiguration(
            version: 1,
            selectedOrganizations: ["CompanyA"],
            selectedRepositories: [],
            selectedTeams: []
        )

        let result = engine.apply(
            configuration: config,
            searchQuery: "",
            to: [pr1, pr2, pr3],
            teamMetadata: []
        )

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.repositoryOwner == "CompanyA" })
        #expect(result.contains(where: { $0.previewMetadata != nil }))
        #expect(result.contains(where: { $0.previewMetadata == nil }))
    }

    @Test
    func `PRs can be sorted by updatedAt with preview metadata enabled`() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: now)!

        let metadata = PRPreviewMetadata(
            additions: 100,
            deletions: 50,
            changedFiles: 5,
            requestedReviewers: [],
            completedReviewers: []
        )

        var pr1 = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 1,
            title: "Oldest PR",
            authorLogin: "author",
            authorAvatarURL: nil,
            updatedAt: twoDaysAgo,
            htmlURL: url
        )
        pr1.previewMetadata = metadata

        var pr2 = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 2,
            title: "Middle PR",
            authorLogin: "author",
            authorAvatarURL: nil,
            updatedAt: yesterday,
            htmlURL: url
        )
        pr2.previewMetadata = nil

        var pr3 = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 3,
            title: "Newest PR",
            authorLogin: "author",
            authorAvatarURL: nil,
            updatedAt: now,
            htmlURL: url
        )
        pr3.previewMetadata = metadata

        let prs = [pr1, pr2, pr3]
        let sorted = prs.sorted { $0.updatedAt > $1.updatedAt }

        #expect(sorted[0].title == "Newest PR")
        #expect(sorted[1].title == "Middle PR")
        #expect(sorted[2].title == "Oldest PR")
        #expect(sorted[0].previewMetadata != nil)
        #expect(sorted[1].previewMetadata == nil)
        #expect(sorted[2].previewMetadata != nil)
    }

    // MARK: - Helper

    private func makePR(
        owner: String = "owner",
        repo: String = "repo",
        number: Int = 1,
        title: String = "Title",
        author: String = "author"
    ) -> PullRequest {
        PullRequest(
            repositoryOwner: owner,
            repositoryName: repo,
            number: number,
            title: title,
            authorLogin: author,
            authorAvatarURL: nil,
            updatedAt: now,
            htmlURL: url
        )
    }
}
