import Foundation
import Testing

@testable import GitReviewItAppPoc

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

    // MARK: - Graceful Degradation Tests

    @Test func `fetchPRDetails succeeds when check runs fail with unknown status`() async throws {
        // Given: PR details endpoint succeeds, but check runs endpoint fails
        let prDetailsJSON = Data(
            """
            {
                "additions": 42,
                "deletions": 17,
                "changed_files": 5,
                "comments": 0,
                "requested_reviewers": [
                    {
                        "login": "reviewer1",
                        "avatar_url": "https://avatars.github.com/u/1"
                    }
                ],
                "head": {
                    "sha": "abc123"
                },
                "mergeable": true,
                "mergeable_state": "clean"
            }
            """.utf8)

        let reviewsJSON = Data("[]".utf8)

        mockHTTPClient.responseHandler = { request in
            let urlString = request.url?.absoluteString ?? ""

            if urlString.contains("/repos/owner/repo/pulls/1") && !urlString.contains("/reviews") {
                return (
                    prDetailsJSON,
                    HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }

            if urlString.contains("/repos/owner/repo/pulls/1/reviews") {
                return (
                    reviewsJSON,
                    HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }

            if urlString.contains("/repos/owner/repo/commits/abc123/check-runs") {
                // Check runs endpoint fails
                return (
                    Data(),
                    HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
                )
            }

            return (Data(), HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!)
        }

        // When: fetchPRDetails is called
        let metadata = try await api.fetchPRDetails(
            owner: "owner",
            repo: "repo",
            number: 1,
            credentials: credentials
        )

        // Then: Metadata is returned with check status as unknown
        #expect(metadata.additions == 42)
        #expect(metadata.deletions == 17)
        #expect(metadata.changedFiles == 5)
        #expect(metadata.requestedReviewers.count == 1)
        #expect(metadata.requestedReviewers[0].login == "reviewer1")
        #expect(metadata.checkStatus == .unknown)
        #expect(metadata.mergeStatus == .mergeable)
    }

    @Test func `fetchPRDetails succeeds when reviews fail with empty reviewers`() async throws {
        // Given: PR details endpoint succeeds, but reviews endpoint fails
        let prDetailsJSON = Data(
            """
            {
                "additions": 30,
                "deletions": 10,
                "changed_files": 3,
                "comments": 0,
                "requested_reviewers": [],
                "head": {
                    "sha": "def456"
                },
                "mergeable": false,
                "mergeable_state": "dirty"
            }
            """.utf8)

        let checkRunsJSON = Data(
            """
            {
                "total_count": 2,
                "check_runs": [
                    {
                        "status": "completed",
                        "conclusion": "success"
                    },
                    {
                        "status": "completed",
                        "conclusion": "success"
                    }
                ]
            }
            """.utf8)

        mockHTTPClient.responseHandler = { request in
            let urlString = request.url?.absoluteString ?? ""

            if urlString.contains("/repos/owner/repo/pulls/2") && !urlString.contains("/reviews") {
                return (
                    prDetailsJSON,
                    HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }

            if urlString.contains("/repos/owner/repo/pulls/2/reviews") {
                // Reviews endpoint fails
                return (
                    Data(),
                    HTTPURLResponse(url: request.url!, statusCode: 503, httpVersion: nil, headerFields: nil)!
                )
            }

            if urlString.contains("/repos/owner/repo/commits/def456/check-runs") {
                return (
                    checkRunsJSON,
                    HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }

            return (Data(), HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!)
        }

        // When: fetchPRDetails is called
        let metadata = try await api.fetchPRDetails(
            owner: "owner",
            repo: "repo",
            number: 2,
            credentials: credentials
        )

        // Then: Metadata is returned with empty reviewers
        #expect(metadata.additions == 30)
        #expect(metadata.deletions == 10)
        #expect(metadata.changedFiles == 3)
        #expect(metadata.completedReviewers.isEmpty)
        #expect(metadata.checkStatus == .passing)
        #expect(metadata.mergeStatus == .conflicting)
    }

    @Test func `fetchPRDetails succeeds when both reviews and checks fail`() async throws {
        // Given: PR details succeeds, but both reviews and check runs fail
        let prDetailsJSON = Data(
            """
            {
                "additions": 15,
                "deletions": 8,
                "changed_files": 2,
                "comments": 0,
                "requested_reviewers": [
                    {
                        "login": "reviewer2",
                        "avatar_url": "https://avatars.github.com/u/2"
                    }
                ],
                "head": {
                    "sha": "ghi789"
                },
                "mergeable": null,
                "mergeable_state": "unknown"
            }
            """.utf8)

        mockHTTPClient.responseHandler = { request in
            let urlString = request.url?.absoluteString ?? ""

            if urlString.contains("/repos/owner/repo/pulls/3") && !urlString.contains("/reviews") {
                return (
                    prDetailsJSON,
                    HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }

            // Both reviews and check runs fail
            if urlString.contains("/reviews") || urlString.contains("/check-runs") {
                return (
                    Data(),
                    HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
                )
            }

            return (Data(), HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!)
        }

        // When: fetchPRDetails is called
        let metadata = try await api.fetchPRDetails(
            owner: "owner",
            repo: "repo",
            number: 3,
            credentials: credentials
        )

        // Then: Metadata is returned with default values for failed endpoints
        #expect(metadata.additions == 15)
        #expect(metadata.deletions == 8)
        #expect(metadata.changedFiles == 2)
        #expect(metadata.requestedReviewers.count == 1)
        #expect(metadata.completedReviewers.isEmpty)
        #expect(metadata.checkStatus == .unknown)
        #expect(metadata.mergeStatus == .unknown)
    }
}
