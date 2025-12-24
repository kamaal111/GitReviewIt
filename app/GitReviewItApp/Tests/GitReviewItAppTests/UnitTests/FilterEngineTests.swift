//
//  FilterEngineTests.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 23/12/2025.
//

import Testing
import Foundation
@testable import GitReviewItApp

@Suite("Filter Engine Tests")
struct FilterEngineTests {
    private let engine = FilterEngine()
    private let now = Date()
    private let url = URL(string: "https://github.com")!

    @Test
    func `apply returns all PRs when no filters active`() {
        let prs = [makePR(), makePR()]
        let result = engine.apply(
            configuration: .empty,
            searchQuery: "",
            to: prs,
            teamMetadata: []
        )
        #expect(result.count == 2)
    }

    @Test
    func `apply filters by organization`() {
        let pr1 = makePR(owner: "OrgA")
        let pr2 = makePR(owner: "OrgB")
        let config = FilterConfiguration(
            version: 1,
            selectedOrganizations: ["OrgA"],
            selectedRepositories: [],
            selectedTeams: []
        )

        let result = engine.apply(
            configuration: config,
            searchQuery: "",
            to: [pr1, pr2],
            teamMetadata: []
        )

        #expect(result.count == 1)
        #expect(result.first?.repositoryOwner == "OrgA")
    }

    @Test
    func `apply filters by repository`() {
        let pr1 = makePR(owner: "OrgA", repo: "Repo1")
        let pr2 = makePR(owner: "OrgA", repo: "Repo2")
        let config = FilterConfiguration(
            version: 1,
            selectedOrganizations: [],
            selectedRepositories: ["OrgA/Repo1"],
            selectedTeams: []
        )

        let result = engine.apply(
            configuration: config,
            searchQuery: "",
            to: [pr1, pr2],
            teamMetadata: []
        )

        #expect(result.count == 1)
        #expect(result.first?.repositoryName == "Repo1")
    }

    @Test
    func `apply filters by team`() {
        let pr1 = makePR(owner: "OrgA", repo: "Backend") // In team
        let pr2 = makePR(owner: "OrgA", repo: "Frontend") // Not in team

        let team = Team(
            slug: "backend-team",
            name: "Backend",
            organizationLogin: "OrgA",
            repositories: ["OrgA/Backend"]
        )

        let config = FilterConfiguration(
            version: 1,
            selectedOrganizations: [],
            selectedRepositories: [],
            selectedTeams: ["backend-team"]
        )

        let result = engine.apply(
            configuration: config,
            searchQuery: "",
            to: [pr1, pr2],
            teamMetadata: [team]
        )

        #expect(result.count == 1)
        #expect(result.first?.repositoryName == "Backend")
    }

    @Test
    func `apply combines multiple structured filters (AND logic)`() {
        // OrgA/Repo1, OrgA/Repo2, OrgB/Repo3
        let pr1 = makePR(owner: "OrgA", repo: "Repo1")
        let pr2 = makePR(owner: "OrgA", repo: "Repo2")
        let pr3 = makePR(owner: "OrgB", repo: "Repo3")

        // Filter: OrgA AND Repo1
        let config = FilterConfiguration(
            version: 1,
            selectedOrganizations: ["OrgA"],
            selectedRepositories: ["OrgA/Repo1"],
            selectedTeams: []
        )

        let result = engine.apply(
            configuration: config,
            searchQuery: "",
            to: [pr1, pr2, pr3],
            teamMetadata: []
        )

        #expect(result.count == 1)
        #expect(result.first?.repositoryName == "Repo1")
    }

    @Test
    func `apply applies fuzzy search after structured filters`() {
        let pr1 = makePR(owner: "OrgA", title: "Fix bug")
        let pr2 = makePR(owner: "OrgA", title: "Add feature")
        let pr3 = makePR(owner: "OrgB", title: "Fix bug")

        // Filter: OrgA AND Search "Fix"
        let config = FilterConfiguration(
            version: 1,
            selectedOrganizations: ["OrgA"],
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
        #expect(result.first?.repositoryOwner == "OrgA")
        #expect(result.first?.title == "Fix bug")
    }

    // Helper
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
