import Foundation
import Testing

@testable import GitReviewItApp

@MainActor struct GitHubAPIClientTests {
    private let mockHTTPClient = MockHTTPClient()
    private let api: GitHubAPIClient
    private let credentials = GitHubCredentials(token: "test-token", baseURL: "https://api.github.com")

    init() {
        self.api = GitHubAPIClient(httpClient: mockHTTPClient)
    }

    @Test func `fetchReviewRequests aggregates PRs including assignments and reviews`() async throws {
        // Prepare data
        let userJSON = Data(
            """
            { "login": "testuser", "id": 1 }
            """.utf8)

        let teamsJSON = Data(
            """
            [
                { "name": "Team A", "slug": "team-a", "organization": { "login": "org" }, "repositories": [] }
            ]
            """.utf8)

        // PR for user review
        let userPRsJSON = Data(
            """
            {
                "total_count": 1,
                "incomplete_results": false,
                "items": [
                    {
                        "number": 1,
                        "title": "User PR",
                        "html_url": "https://github.com/owner/repo/pull/1",
                        "updated_at": "2023-01-01T00:00:00Z",
                        "state": "open",
                        "user": { "login": "author1" },
                        "repository_url": "https://api.github.com/repos/owner/repo",
                        "comments": 0,
                        "labels": []
                    }
                ]
            }
            """.utf8)

        // PR for user assignment
        let assignedPRsJSON = Data(
            """
            {
                "total_count": 1,
                "incomplete_results": false,
                "items": [
                    {
                        "number": 3,
                        "title": "Assigned PR",
                        "html_url": "https://github.com/owner/repo/pull/3",
                        "updated_at": "2023-01-03T00:00:00Z",
                        "state": "open",
                        "user": { "login": "author3" },
                        "repository_url": "https://api.github.com/repos/owner/repo",
                        "comments": 0,
                        "labels": []
                    }
                ]
            }
            """.utf8)

        // PR for team review
        let teamPRsJSON = Data(
            """
            {
                "total_count": 1,
                "incomplete_results": false,
                "items": [
                    {
                        "number": 2,
                        "title": "Team PR",
                        "html_url": "https://github.com/owner/repo/pull/2",
                        "updated_at": "2023-01-02T00:00:00Z",
                        "state": "open",
                        "user": { "login": "author2" },
                        "repository_url": "https://api.github.com/repos/owner/repo",
                        "comments": 0,
                        "labels": []
                    }
                ]
            }
            """.utf8)

        // PR reviewed by user
        let reviewedPRsJSON = Data(
            """
            {
                "total_count": 1,
                "incomplete_results": false,
                "items": [
                    {
                        "number": 4,
                        "title": "Reviewed PR",
                        "html_url": "https://github.com/owner/repo/pull/4",
                        "updated_at": "2023-01-04T00:00:00Z",
                        "state": "open",
                        "user": { "login": "author4" },
                        "repository_url": "https://api.github.com/repos/owner/repo",
                        "comments": 0,
                        "labels": []
                    }
                ]
            }
            """.utf8)

        // Setup mock responses
        mockHTTPClient.setResponse(for: "https://api.github.com/user", data: userJSON, statusCode: 200)
        mockHTTPClient.setResponse(for: "https://api.github.com/user/teams", data: teamsJSON, statusCode: 200)

        // Note: URL encoding might affect the key lookup, so we might need to be careful or use responseHandler
        // Let's use responseHandler for searches to be safe about query params
        mockHTTPClient.responseHandler = { request in
            let urlString = request.url?.absoluteString ?? ""

            if urlString == "https://api.github.com/user" {
                return (
                    userJSON, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }
            if urlString == "https://api.github.com/user/teams" {
                return (
                    teamsJSON, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }

            if urlString.contains("review-requested:testuser") {
                return (
                    userPRsJSON,
                    HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }

            if urlString.contains("assignee:testuser") {
                return (
                    assignedPRsJSON,
                    HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }

            if urlString.contains("reviewed-by:testuser") {
                return (
                    reviewedPRsJSON,
                    HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }

            if urlString.contains("team-review-requested:org/team-a") {
                return (
                    teamPRsJSON,
                    HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }

            // Fallback for unexpected requests
            return (Data(), HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!)
        }

        // Execute
        let prs = try await api.fetchReviewRequests(credentials: credentials)

        // Verify
        #expect(prs.count == 4)

        let titles = prs.map { $0.title }.sorted()
        #expect(titles == ["Assigned PR", "Reviewed PR", "Team PR", "User PR"])

        // Verify requests
        #expect(mockHTTPClient.performCallCount == 6)  // user, teams, user-search, assigned, reviewed, team-search
    }

    @Test func `fetchReviewRequests handles deduplication`() async throws {
        // Prepare data
        let userJSON = Data(
            """
            { "login": "testuser", "id": 1 }
            """.utf8)

        let teamsJSON = Data(
            """
            [
                { "name": "Team A", "slug": "team-a", "organizationLogin": "org", "repositories": [] }
            ]
            """.utf8)

        // Same PR in both searches
        let searchResponseJSON = Data(
            """
            {
                "total_count": 1,
                "incomplete_results": false,
                "items": [
                    {
                        "number": 1,
                        "title": "Shared PR",
                        "html_url": "https://github.com/owner/repo/pull/1",
                        "updated_at": "2023-01-01T00:00:00Z",
                        "state": "open",
                        "user": { "login": "author1" },
                        "repository_url": "https://api.github.com/repos/owner/repo",
                        "comments": 0,
                        "labels": []
                    }
                ]
            }
            """.utf8)

        mockHTTPClient.responseHandler = { request in
            let urlString = request.url?.absoluteString ?? ""

            if urlString == "https://api.github.com/user" {
                return (
                    userJSON, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }
            if urlString == "https://api.github.com/user/teams" {
                return (
                    teamsJSON, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }

            // Return same PR for all searches
            if urlString.contains("/search/issues") {
                return (
                    searchResponseJSON,
                    HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }

            return (Data(), HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!)
        }

        // Execute
        let prs = try await api.fetchReviewRequests(credentials: credentials)

        // Verify
        #expect(prs.count == 1)
        #expect(prs.first?.title == "Shared PR")
    }

    @Test func `fetchReviewRequests continues if fetching teams fails`() async throws {
        // Prepare data
        let userJSON = Data(
            """
            { "login": "testuser", "id": 1 }
            """.utf8)

        let userPRsJSON = Data(
            """
            {
                "total_count": 1,
                "incomplete_results": false,
                "items": [
                    {
                        "number": 1,
                        "title": "User PR",
                        "html_url": "https://github.com/owner/repo/pull/1",
                        "updated_at": "2023-01-01T00:00:00Z",
                        "state": "open",
                        "user": { "login": "author1" },
                        "repository_url": "https://api.github.com/repos/owner/repo",
                        "comments": 0,
                        "labels": []
                    }
                ]
            }
            """.utf8)

        mockHTTPClient.responseHandler = { request in
            let urlString = request.url?.absoluteString ?? ""

            if urlString == "https://api.github.com/user" {
                return (
                    userJSON, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }
            if urlString == "https://api.github.com/user/teams" {
                // Return 403 Forbidden for teams
                return (
                    Data(), HTTPURLResponse(url: request.url!, statusCode: 403, httpVersion: nil, headerFields: nil)!
                )
            }

            if urlString.contains("review-requested:testuser") {
                return (
                    userPRsJSON,
                    HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }

            if urlString.contains("assignee:testuser") || urlString.contains("reviewed-by:testuser") {
                // Return empty list for assignee and reviewed-by
                return (
                    Data(
                        """
                        { "total_count": 0, "incomplete_results": false, "items": [] }
                        """.utf8),
                    HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }

            return (Data(), HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!)
        }

        // Execute
        let prs = try await api.fetchReviewRequests(credentials: credentials)

        // Verify
        #expect(prs.count == 1)
        #expect(prs.first?.title == "User PR")
        // Should fetch teams (failed), then proceed with user search, assignee search, and reviewed search
        #expect(mockHTTPClient.performCallCount == 5)  // user, teams (failed), user-search, assigned, reviewed
    }

    // MARK: - fetchTeams Tests

    @Test func `fetchTeams returns teams on success`() async throws {
        // Prepare fixture data
        let teamsJSON = try TestHelpers.loadFixture(.teamsFullResponse)

        mockHTTPClient.setResponse(for: "https://api.github.com/user/teams", data: teamsJSON, statusCode: 200)

        // Execute
        let teams = try await api.fetchTeams(credentials: credentials)

        // Verify
        #expect(teams.count == 4)

        let swiftCore = teams.first { $0.slug == "swift-core" }
        #expect(swiftCore != nil)
        #expect(swiftCore?.name == "Swift Core Team")
        #expect(swiftCore?.organizationLogin == "apple")
        #expect(swiftCore?.repositories == ["apple/swift", "apple/swift-evolution"])

        let backendTeam = teams.first { $0.slug == "backend-team" }
        #expect(backendTeam != nil)
        #expect(backendTeam?.name == "Backend Team")
        #expect(backendTeam?.organizationLogin == "CompanyA")
        #expect(backendTeam?.repositories == ["CompanyA/backend-service", "CompanyA/api-gateway"])

        #expect(mockHTTPClient.performCallCount == 1)
    }

    @Test func `fetchTeams throws unauthorized on 401`() async throws {
        mockHTTPClient.setResponse(for: "https://api.github.com/user/teams", data: Data(), statusCode: 401)

        // Execute and verify
        await #expect(throws: APIError.self) {
            try await api.fetchTeams(credentials: credentials)
        }
    }

    @Test func `fetchTeams throws on 403 forbidden`() async throws {
        let errorJSON = Data(
            """
            { "message": "Resource not accessible by integration" }
            """.utf8)

        mockHTTPClient.setResponse(for: "https://api.github.com/user/teams", data: errorJSON, statusCode: 403)

        // Execute and verify
        await #expect(throws: APIError.self) {
            try await api.fetchTeams(credentials: credentials)
        }
    }

    @Test func `fetchTeams returns empty array when no teams exist`() async throws {
        let emptyTeamsJSON = Data("[]".utf8)

        mockHTTPClient.setResponse(for: "https://api.github.com/user/teams", data: emptyTeamsJSON, statusCode: 200)

        // Execute
        let teams = try await api.fetchTeams(credentials: credentials)

        // Verify
        #expect(teams.isEmpty)
        #expect(mockHTTPClient.performCallCount == 1)
    }

    @Test func `fetchTeams deduplicates teams by fullSlug`() async throws {
        // This can happen if the API returns the same team multiple times
        // due to pagination or nested team memberships
        let duplicateTeamsJSON = Data(
            """
            [
                {
                    "slug": "backend-team",
                    "name": "Backend Team",
                    "organization": { "login": "CompanyA" },
                    "repositories": ["CompanyA/backend-service"]
                },
                {
                    "slug": "backend-team",
                    "name": "Backend Team",
                    "organization": { "login": "CompanyA" },
                    "repositories": ["CompanyA/backend-service"]
                },
                {
                    "slug": "frontend-team",
                    "name": "Frontend Team",
                    "organization": { "login": "CompanyA" },
                    "repositories": ["CompanyA/frontend-app"]
                }
            ]
            """.utf8)

        mockHTTPClient.setResponse(for: "https://api.github.com/user/teams", data: duplicateTeamsJSON, statusCode: 200)

        // Execute
        let teams = try await api.fetchTeams(credentials: credentials)

        // Verify - should only have 2 unique teams, not 3
        #expect(teams.count == 2)

        let teamSlugs = Set(teams.map { $0.fullSlug })
        #expect(teamSlugs.contains("CompanyA/backend-team"))
        #expect(teamSlugs.contains("CompanyA/frontend-team"))
        #expect(teamSlugs.count == 2)
    }

    @Test func `fetchTeams preserves teams with same slug in different organizations`() async throws {
        // Teams can have the same slug in different organizations
        // These should NOT be deduplicated as they're different teams
        let teamsJSON = Data(
            """
            [
                {
                    "slug": "backend-team",
                    "name": "Backend Team A",
                    "organization": { "login": "CompanyA" },
                    "repositories": ["CompanyA/backend-service"]
                },
                {
                    "slug": "backend-team",
                    "name": "Backend Team B",
                    "organization": { "login": "CompanyB" },
                    "repositories": ["CompanyB/backend-service"]
                },
                {
                    "slug": "backend-team",
                    "name": "Backend Team C",
                    "organization": { "login": "CompanyC" },
                    "repositories": ["CompanyC/backend-service"]
                }
            ]
            """.utf8)

        mockHTTPClient.setResponse(for: "https://api.github.com/user/teams", data: teamsJSON, statusCode: 200)

        // Execute
        let teams = try await api.fetchTeams(credentials: credentials)

        // Verify - should have 3 teams since they're in different orgs
        #expect(teams.count == 3)

        let teamIDs = Set(teams.map { $0.id })
        #expect(teamIDs.contains("CompanyA/backend-team"))
        #expect(teamIDs.contains("CompanyB/backend-team"))
        #expect(teamIDs.contains("CompanyC/backend-team"))
        #expect(teamIDs.count == 3)

        // Verify each team has the correct organization
        let companyATeam = teams.first { $0.organizationLogin == "CompanyA" }
        #expect(companyATeam?.name == "Backend Team A")

        let companyBTeam = teams.first { $0.organizationLogin == "CompanyB" }
        #expect(companyBTeam?.name == "Backend Team B")

        let companyCTeam = teams.first { $0.organizationLogin == "CompanyC" }
        #expect(companyCTeam?.name == "Backend Team C")
    }
}
