import Foundation
import Testing

@testable import GitReviewItApp

@MainActor
struct GitHubAPIClientTests {
    private let mockHTTPClient = MockHTTPClient()
    private let api: GitHubAPIClient
    private let credentials = GitHubCredentials(
        token: "test-token", baseURL: "https://api.github.com")

    init() {
        self.api = GitHubAPIClient(httpClient: mockHTTPClient)
    }

    @Test
    func `fetchReviewRequests fetches user, teams, and aggregates PRs including assignments`()
        async throws
    {
        // Prepare data
        let userJSON = """
            { "login": "testuser", "id": 1 }
            """.data(using: .utf8)!

        let teamsJSON = """
            [
                { "id": 1, "name": "Team A", "slug": "team-a", "organization": { "login": "org" } }
            ]
            """.data(using: .utf8)!

        // PR for user review
        let userPRsJSON = """
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
                        "repository_url": "https://api.github.com/repos/owner/repo"
                    }
                ]
            }
            """.data(using: .utf8)!

        // PR for user assignment
        let assignedPRsJSON = """
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
                        "repository_url": "https://api.github.com/repos/owner/repo"
                    }
                ]
            }
            """.data(using: .utf8)!

        // PR for team review
        let teamPRsJSON = """
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
                        "repository_url": "https://api.github.com/repos/owner/repo"
                    }
                ]
            }
            """.data(using: .utf8)!

        // Setup mock responses
        mockHTTPClient.setResponse(
            for: "https://api.github.com/user", data: userJSON, statusCode: 200)
        mockHTTPClient.setResponse(
            for: "https://api.github.com/user/teams", data: teamsJSON, statusCode: 200)

        // Note: URL encoding might affect the key lookup, so we might need to be careful or use responseHandler
        // Let's use responseHandler for searches to be safe about query params
        mockHTTPClient.responseHandler = { request in
            let urlString = request.url?.absoluteString ?? ""

            if urlString == "https://api.github.com/user" {
                return (
                    userJSON,
                    HTTPURLResponse(
                        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }
            if urlString == "https://api.github.com/user/teams" {
                return (
                    teamsJSON,
                    HTTPURLResponse(
                        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }

            if urlString.contains("review-requested:testuser") {
                return (
                    userPRsJSON,
                    HTTPURLResponse(
                        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }

            if urlString.contains("assignee:testuser") {
                return (
                    assignedPRsJSON,
                    HTTPURLResponse(
                        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }

            if urlString.contains("team-review-requested:org/team-a") {
                return (
                    teamPRsJSON,
                    HTTPURLResponse(
                        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }

            // Fallback for unexpected requests
            return (
                Data(),
                HTTPURLResponse(
                    url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            )
        }

        // Execute
        let prs = try await api.fetchReviewRequests(credentials: credentials)

        // Verify
        #expect(prs.count == 3)

        let titles = prs.map { $0.title }.sorted()
        #expect(titles == ["Assigned PR", "Team PR", "User PR"])

        // Verify requests
        #expect(mockHTTPClient.performCallCount == 5)  // user, teams, search user, search assignee, search team
    }

    @Test
    func `fetchReviewRequests handles deduplication`() async throws {
        // Prepare data
        let userJSON = """
            { "login": "testuser", "id": 1 }
            """.data(using: .utf8)!

        let teamsJSON = """
            [
                { "id": 1, "name": "Team A", "slug": "team-a", "organization": { "login": "org" } }
            ]
            """.data(using: .utf8)!

        // Same PR in both searches
        let searchResponseJSON = """
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
                        "repository_url": "https://api.github.com/repos/owner/repo"
                    }
                ]
            }
            """.data(using: .utf8)!

        mockHTTPClient.responseHandler = { request in
            let urlString = request.url?.absoluteString ?? ""

            if urlString == "https://api.github.com/user" {
                return (
                    userJSON,
                    HTTPURLResponse(
                        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }
            if urlString == "https://api.github.com/user/teams" {
                return (
                    teamsJSON,
                    HTTPURLResponse(
                        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }

            // Return same PR for both searches
            if urlString.contains("/search/issues") {
                return (
                    searchResponseJSON,
                    HTTPURLResponse(
                        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }

            return (
                Data(),
                HTTPURLResponse(
                    url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            )
        }

        // Execute
        let prs = try await api.fetchReviewRequests(credentials: credentials)

        // Verify
        #expect(prs.count == 1)
        #expect(prs.first?.title == "Shared PR")
    }

    @Test
    func `fetchReviewRequests continues if fetching teams fails`() async throws {
        // Prepare data
        let userJSON = """
            { "login": "testuser", "id": 1 }
            """.data(using: .utf8)!

        let userPRsJSON = """
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
                        "repository_url": "https://api.github.com/repos/owner/repo"
                    }
                ]
            }
            """.data(using: .utf8)!

        mockHTTPClient.responseHandler = { request in
            let urlString = request.url?.absoluteString ?? ""

            if urlString == "https://api.github.com/user" {
                return (
                    userJSON,
                    HTTPURLResponse(
                        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }
            if urlString == "https://api.github.com/user/teams" {
                // Return 403 Forbidden for teams
                return (
                    Data(),
                    HTTPURLResponse(
                        url: request.url!, statusCode: 403, httpVersion: nil, headerFields: nil)!
                )
            }

            if urlString.contains("review-requested:testuser") {
                return (
                    userPRsJSON,
                    HTTPURLResponse(
                        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }

            if urlString.contains("assignee:testuser") {
                // Return empty list for assignee
                return (
                    """
                    { "total_count": 0, "incomplete_results": false, "items": [] }
                    """.data(using: .utf8)!,
                    HTTPURLResponse(
                        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }

            return (
                Data(),
                HTTPURLResponse(
                    url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            )
        }

        // Execute
        let prs = try await api.fetchReviewRequests(credentials: credentials)

        // Verify
        #expect(prs.count == 1)
        #expect(prs.first?.title == "User PR")
        // Should have tried to fetch teams, failed, and then proceeded with user search and assignee search
        #expect(mockHTTPClient.performCallCount == 4)  // user, teams (failed), search user, search assignee
    }
}
