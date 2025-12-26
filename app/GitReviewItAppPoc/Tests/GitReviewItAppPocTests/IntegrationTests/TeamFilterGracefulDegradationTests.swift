//
//  TeamFilterGracefulDegradationTests.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 24/12/2025.
//

import Foundation
import Testing

@testable import GitReviewItAppPoc

@Suite("Team Filter Graceful Degradation Tests")
@MainActor
struct TeamFilterGracefulDegradationTests {
    private let mockHTTPClient = MockHTTPClient()
    private let mockPersistence = MockFilterPersistence()
    private let api: GitHubAPIClient

    init() {
        self.api = GitHubAPIClient(httpClient: mockHTTPClient)
    }

    @Test
    func `FilterState handles team fetch failure gracefully`() async throws {
        let filterState = FilterState(persistence: mockPersistence)

        let credentials = GitHubCredentials(token: "test-token", baseURL: "https://api.github.com")

        // Mock 403 response for teams endpoint
        mockHTTPClient.setResponse(for: "https://api.github.com/user/teams", data: Data(), statusCode: 403)

        let prs = [
            PullRequest(
                repositoryOwner: "CompanyA",
                repositoryName: "backend",
                number: 1,
                title: "Test PR",
                authorLogin: "author",
                authorAvatarURL: nil,
                updatedAt: Date(),
                htmlURL: URL(string: "https://github.com")!
            )
        ]

        // Update metadata which should fetch teams
        await filterState.updateMetadata(from: prs, api: api, credentials: credentials)

        // Teams should be in failed state
        #expect(filterState.metadata.teams.error != nil)

        // Organizations and repositories should still be populated
        #expect(filterState.metadata.organizations == ["CompanyA"])
        #expect(filterState.metadata.repositories == ["CompanyA/backend"])
    }

    @Test
    func `FilterState clears team filters when teams unavailable`() async throws {
        let filterState = FilterState(persistence: mockPersistence)

        let credentials = GitHubCredentials(token: "test-token", baseURL: "https://api.github.com")

        // Set initial configuration with team filter
        let initialConfig = FilterConfiguration(
            version: 1,
            selectedOrganizations: [],
            selectedRepositories: [],
            selectedTeams: ["backend-team"]
        )

        await filterState.updateFilterConfiguration(initialConfig)
        #expect(filterState.configuration.selectedTeams == ["backend-team"])

        // Mock 403 response for teams endpoint
        mockHTTPClient.setResponse(for: "https://api.github.com/user/teams", data: Data(), statusCode: 403)

        let prs = [
            PullRequest(
                repositoryOwner: "CompanyA",
                repositoryName: "backend",
                number: 1,
                title: "Test PR",
                authorLogin: "author",
                authorAvatarURL: nil,
                updatedAt: Date(),
                htmlURL: URL(string: "https://github.com")!
            )
        ]

        // Update metadata which should fetch teams and fail
        await filterState.updateMetadata(from: prs, api: api, credentials: credentials)

        // Team filters should be cleared
        #expect(filterState.configuration.selectedTeams.isEmpty)

        // Other filters should remain unchanged
        #expect(filterState.configuration.selectedOrganizations.isEmpty)
        #expect(filterState.configuration.selectedRepositories.isEmpty)
    }

    @Test
    func `FilterState shows error message when teams unavailable`() async throws {
        let filterState = FilterState(persistence: mockPersistence)

        let credentials = GitHubCredentials(token: "test-token", baseURL: "https://api.github.com")

        // Set initial configuration with team filter
        let initialConfig = FilterConfiguration(
            version: 1,
            selectedOrganizations: [],
            selectedRepositories: [],
            selectedTeams: ["backend-team"]
        )

        await filterState.updateFilterConfiguration(initialConfig)

        // Mock 403 response for teams endpoint
        mockHTTPClient.setResponse(for: "https://api.github.com/user/teams", data: Data(), statusCode: 403)

        let prs = [
            PullRequest(
                repositoryOwner: "CompanyA",
                repositoryName: "backend",
                number: 1,
                title: "Test PR",
                authorLogin: "author",
                authorAvatarURL: nil,
                updatedAt: Date(),
                htmlURL: URL(string: "https://github.com")!
            )
        ]

        // Update metadata which should fetch teams and fail
        await filterState.updateMetadata(from: prs, api: api, credentials: credentials)

        // Error message should be set
        #expect(filterState.errorMessage != nil)
        #expect(filterState.errorMessage?.contains("Team filtering is unavailable") == true)
    }

    @Test
    func `FilterState loads teams successfully when available`() async throws {
        let filterState = FilterState(persistence: mockPersistence)

        let credentials = GitHubCredentials(token: "test-token", baseURL: "https://api.github.com")

        let teamsJSON = Data("""
        [
            {
                "slug": "backend-team",
                "name": "Backend Team",
                "organization": { "login": "CompanyA" },
                "repositories": ["CompanyA/backend"]
            }
        ]
        """.utf8)

        mockHTTPClient.setResponse(for: "https://api.github.com/user/teams", data: teamsJSON, statusCode: 200)

        let prs = [
            PullRequest(
                repositoryOwner: "CompanyA",
                repositoryName: "backend",
                number: 1,
                title: "Test PR",
                authorLogin: "author",
                authorAvatarURL: nil,
                updatedAt: Date(),
                htmlURL: URL(string: "https://github.com")!
            )
        ]

        // Update metadata which should fetch teams successfully
        await filterState.updateMetadata(from: prs, api: api, credentials: credentials)

        // Teams should be loaded
        guard case .loaded(let teams) = filterState.metadata.teams else {
            Issue.record("Expected teams to be loaded")
            return
        }

        #expect(teams.count == 1)
        #expect(teams[0].slug == "backend-team")
        #expect(teams[0].name == "Backend Team")
    }

    @Test
    func `Organization and repository filters work when teams unavailable`() async throws {
        let filterEngine = FilterEngine()

        let pr1 = PullRequest(
            repositoryOwner: "CompanyA",
            repositoryName: "backend",
            number: 1,
            title: "Test PR 1",
            authorLogin: "author1",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com")!
        )

        let pr2 = PullRequest(
            repositoryOwner: "CompanyB",
            repositoryName: "frontend",
            number: 2,
            title: "Test PR 2",
            authorLogin: "author2",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com")!
        )

        let config = FilterConfiguration(
            version: 1,
            selectedOrganizations: ["CompanyA"],
            selectedRepositories: [],
            selectedTeams: []  // No team filters
        )

        // Apply filter with empty team metadata (teams unavailable)
        let result = filterEngine.apply(
            configuration: config,
            searchQuery: "",
            to: [pr1, pr2],
            teamMetadata: []
        )

        // Organization filter should still work
        #expect(result.count == 1)
        #expect(result[0].repositoryOwner == "CompanyA")
    }

    @Test
    func `FilterMetadata areTeamsAvailable returns false when teams failed`() {
        let metadata = FilterMetadata(
            organizations: ["CompanyA"],
            repositories: ["CompanyA/backend"],
            teams: .failed(.unauthorized)
        )

        #expect(metadata.areTeamsAvailable == false)
    }

    @Test
    func `FilterMetadata areTeamsAvailable returns true for loaded teams`() {
        let metadata = FilterMetadata(
            organizations: ["CompanyA"],
            repositories: ["CompanyA/backend"],
            teams: .loaded([])
        )

        #expect(metadata.areTeamsAvailable == true)
    }

    @Test
    func `FilterMetadata areTeamsAvailable returns true for idle state`() {
        let metadata = FilterMetadata(
            organizations: ["CompanyA"],
            repositories: ["CompanyA/backend"],
            teams: .idle
        )

        #expect(metadata.areTeamsAvailable == true)
    }

    @Test
    func `FilterMetadata areTeamsAvailable returns true for loading state`() {
        let metadata = FilterMetadata(
            organizations: ["CompanyA"],
            repositories: ["CompanyA/backend"],
            teams: .loading
        )

        #expect(metadata.areTeamsAvailable == true)
    }
}
