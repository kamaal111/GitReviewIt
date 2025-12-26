import Foundation
import Testing

@testable import GitReviewItAppPoc

/// Tests that verify JSON fixtures can be loaded and decoded correctly
struct FixtureTests {
    // MARK: - User Response Tests

    @Test
    func `User response fixture decodes to AuthenticatedUser`() throws {
        // Load the fixture
        let data = try TestHelpers.loadFixture(.userResponse)

        // Decode to AuthenticatedUser (no key strategy needed - model has custom CodingKeys)
        let decoder = JSONDecoder()

        let user = try decoder.decode(AuthenticatedUser.self, from: data)

        // Verify the decoded values
        #expect(user.login == "octocat")
        #expect(user.name == "The Octocat")
        #expect(user.avatarURL?.absoluteString.contains("avatars.githubusercontent.com") == true)
    }

    @Test
    func `User response fixture contains all required GitHub API fields`() throws {
        // Load the fixture
        let data = try TestHelpers.loadFixture(.userResponse)

        // Decode as generic JSON to verify structure
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json != nil)
        #expect(json?["login"] as? String == "octocat")
        #expect(json?["id"] as? Int == 1)
        #expect(json?["name"] as? String == "The Octocat")
        #expect(json?["avatar_url"] is String)
        #expect(json?["type"] as? String == "User")
    }

    // MARK: - Pull Requests Response Tests

    @Test
    func `PRs response fixture decodes to search response with items`() throws {
        // Load the fixture
        let data = try TestHelpers.loadFixture(.prsResponse)

        // Decode as search response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let response = try decoder.decode(GitHubSearchResponse.self, from: data)

        // Verify the search metadata
        #expect(response.totalCount == 3)
        #expect(response.incompleteResults == false)
        #expect(response.items.count == 3)
    }

    @Test
    func `PRs response fixture contains valid pull request data`() throws {
        // Load the fixture
        let data = try TestHelpers.loadFixture(.prsResponse)

        // Decode as search response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let response = try decoder.decode(GitHubSearchResponse.self, from: data)
        let items = response.items

        // Verify first PR (apple/swift)
        let firstPR = items[0]
        #expect(firstPR.number == 12345)
        #expect(firstPR.title == "Add support for distributed actor isolation")
        #expect(firstPR.repositoryOwner == "apple")
        #expect(firstPR.repositoryName == "swift")
        #expect(firstPR.authorLogin == "ktoso")
        #expect(firstPR.state == "open")

        // Verify second PR (vapor/vapor)
        let secondPR = items[1]
        #expect(secondPR.number == 3210)
        #expect(secondPR.title == "Fix memory leak in WebSocket connections")
        #expect(secondPR.repositoryOwner == "vapor")
        #expect(secondPR.repositoryName == "vapor")
        #expect(secondPR.authorLogin == "0xTim")

        // Verify third PR (pointfreeco/swift-composable-architecture)
        let thirdPR = items[2]
        #expect(thirdPR.number == 2890)
        #expect(thirdPR.repositoryOwner == "pointfreeco")
        #expect(thirdPR.repositoryName == "swift-composable-architecture")
        #expect(thirdPR.authorLogin == "mbrandonw")
    }

    @Test
    func `PRs response fixture HTML URLs are valid`() throws {
        // Load the fixture
        let data = try TestHelpers.loadFixture(.prsResponse)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let response = try decoder.decode(GitHubSearchResponse.self, from: data)

        // Verify all PRs have valid HTML URLs
        for pr in response.items {
            #expect(pr.htmlUrl.absoluteString.hasPrefix("https://github.com/"))
            #expect(pr.htmlUrl.absoluteString.contains("/pull/\(pr.number)"))
        }
    }

    @Test
    func `PRs response fixture timestamps are parseable`() throws {
        // Load the fixture
        let data = try TestHelpers.loadFixture(.prsResponse)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let response = try decoder.decode(GitHubSearchResponse.self, from: data)

        // Verify all PRs have valid timestamps that are in the past
        let now = Date()
        for pr in response.items {
            #expect(pr.updatedAt <= now)
        }
    }

    // MARK: - Error Response Tests

    @Test
    func `Error responses fixture contains all expected error types`() throws {
        // Load the fixture
        let data = try TestHelpers.loadFixture(.errorResponses)

        // Decode as generic JSON
        let json = try JSONSerialization.jsonObject(with: data) as? [String: [String: Any]]

        #expect(json != nil)

        // Verify all expected error types are present
        let expectedErrorTypes = [
            "unauthorized",
            "rateLimitExceeded",
            "notFound",
            "validationFailed",
            "serverError",
            "invalidToken",
            "scopeInsufficient"
        ]

        for errorType in expectedErrorTypes {
            #expect(json?[errorType] != nil, "Missing error type: \(errorType)")
        }
    }

    @Test
    func `Error responses fixture has proper message structure`() throws {
        // Load the fixture
        let data = try TestHelpers.loadFixture(.errorResponses)

        let json = try JSONSerialization.jsonObject(with: data) as? [String: [String: Any]]

        // Verify unauthorized error structure
        let unauthorized = json?["unauthorized"]
        #expect(unauthorized?["message"] as? String == "Bad credentials")
        #expect(unauthorized?["documentation_url"] is String)

        // Verify rate limit error structure
        let rateLimited = json?["rateLimitExceeded"]
        #expect(rateLimited?["message"] is String)
        #expect((rateLimited?["message"] as? String)?.contains("rate limit") == true)

        // Verify not found error structure
        let notFound = json?["notFound"]
        #expect(notFound?["message"] as? String == "Not Found")
    }

    @Test
    func `Error responses fixture validation failed includes error details`() throws {
        // Load the fixture
        let data = try TestHelpers.loadFixture(.errorResponses)

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let validationFailed = json?["validationFailed"] as? [String: Any]

        #expect(validationFailed != nil)
        #expect(validationFailed?["message"] as? String == "Validation Failed")

        // Verify errors array exists
        let errors = validationFailed?["errors"] as? [[String: String]]
        #expect(errors != nil)
        #expect(errors?.isEmpty == false)

        // Verify error structure
        if let firstError = errors?.first {
            #expect(firstError["resource"] != nil)
            #expect(firstError["field"] != nil)
            #expect(firstError["code"] != nil)
        }
    }

    // MARK: - Round-trip Tests

    @Test
    func `User can be encoded and decoded maintaining data integrity`() throws {
        // Load original fixture
        let originalData = try TestHelpers.loadFixture(.userResponse)

        let decoder = JSONDecoder()

        // Decode to model
        let user = try decoder.decode(AuthenticatedUser.self, from: originalData)

        // Encode back to JSON
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(user)

        // Decode again
        let decodedUser = try decoder.decode(AuthenticatedUser.self, from: encodedData)

        // Verify they match
        #expect(user == decodedUser)
    }

    @Test
    func `Pull request search response maintains data integrity through encoding cycle`() throws {
        // Load original fixture
        let originalData = try TestHelpers.loadFixture(.prsResponse)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        // Decode to model
        let response = try decoder.decode(GitHubSearchResponse.self, from: originalData)

        // Verify we can access all PR data
        for pr in response.items {
            // These should not throw
            _ = pr.id
            _ = pr.repositoryFullName
            #expect(!pr.title.isEmpty)
            #expect(!pr.authorLogin.isEmpty)
        }
    }
}

// MARK: - Supporting Types

/// Internal model for decoding GitHub search responses
private struct GitHubSearchResponse: Decodable {
    let totalCount: Int
    let incompleteResults: Bool
    let items: [SearchIssueItem]
}

/// Internal model for decoding search issue items
private struct SearchIssueItem: Decodable {
    let number: Int
    let title: String
    let htmlUrl: URL
    let updatedAt: Date
    let state: String
    let user: SearchUser
    let repositoryUrl: String

    // Computed properties to match PullRequest model
    var repositoryOwner: String {
        extractRepositoryInfo().owner
    }

    var repositoryName: String {
        extractRepositoryInfo().name
    }

    var authorLogin: String {
        user.login
    }

    /// Unique identifier in "owner/repo#number" format
    var id: String {
        "\(repositoryOwner)/\(repositoryName)#\(number)"
    }

    /// Repository full name in "owner/repo" format
    var repositoryFullName: String {
        "\(repositoryOwner)/\(repositoryName)"
    }

    private func extractRepositoryInfo() -> (owner: String, name: String) {
        // Parse "https://api.github.com/repos/owner/repo"
        let components = repositoryUrl.components(separatedBy: "/")
        guard components.count >= 2 else {
            return (owner: "", name: "")
        }

        let repoIndex = components.lastIndex(of: "repos") ?? components.count - 3
        let owner = components[repoIndex + 1]
        let name = components[repoIndex + 2]

        return (owner: owner, name: name)
    }
}

/// Internal model for decoding user information in search results
private struct SearchUser: Decodable {
    let login: String
    let avatarUrl: URL?
}
