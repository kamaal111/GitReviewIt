import Foundation
import Testing

@testable import GitReviewItAppPoc

/// Unit tests for Reviewer model validation and behavior
struct ReviewerTests {

    // MARK: - Initialization Tests

    @Test
    func `Reviewer initializes with valid login and avatar URL`() throws {
        let avatarURL = try #require(URL(string: "https://avatars.githubusercontent.com/u/1"))
        let reviewer = Reviewer(login: "octocat", avatarURL: avatarURL)

        #expect(reviewer.login == "octocat")
        #expect(reviewer.avatarURL == avatarURL)
        #expect(reviewer.id == "octocat")
    }

    @Test
    func `Reviewer initializes with nil avatar URL`() {
        let reviewer = Reviewer(login: "octocat", avatarURL: nil)

        #expect(reviewer.login == "octocat")
        #expect(reviewer.avatarURL == nil)
        #expect(reviewer.id == "octocat")
    }

    @Test
    func `Reviewer uses login as identifier`() {
        let reviewer1 = Reviewer(login: "alice", avatarURL: nil)
        let reviewer2 = Reviewer(login: "bob", avatarURL: nil)

        #expect(reviewer1.id == "alice")
        #expect(reviewer2.id == "bob")
        #expect(reviewer1.id != reviewer2.id)
    }

    // MARK: - Validation Tests
    // Note: Precondition validation tests are omitted because preconditions cause
    // fatal errors that crash the test runner. In production, invalid inputs should
    // be prevented at the API boundary through proper input validation.

    @Test
    func `Reviewer accepts valid GitHub username formats`() {
        let reviewer1 = Reviewer(login: "user", avatarURL: nil)
        let reviewer2 = Reviewer(login: "user-name", avatarURL: nil)
        let reviewer3 = Reviewer(login: "user123", avatarURL: nil)

        #expect(reviewer1.login == "user")
        #expect(reviewer2.login == "user-name")
        #expect(reviewer3.login == "user123")
    }

    // MARK: - Equatable Tests

    @Test
    func `Reviewer equality compares login and avatar URL`() throws {
        let url1 = try #require(URL(string: "https://avatars.githubusercontent.com/u/1"))
        let url2 = try #require(URL(string: "https://avatars.githubusercontent.com/u/2"))

        let reviewer1 = Reviewer(login: "octocat", avatarURL: url1)
        let reviewer2 = Reviewer(login: "octocat", avatarURL: url1)
        let reviewer3 = Reviewer(login: "octocat", avatarURL: url2)
        let reviewer4 = Reviewer(login: "alice", avatarURL: url1)
        let reviewer5 = Reviewer(login: "octocat", avatarURL: nil)

        #expect(reviewer1 == reviewer2)
        #expect(reviewer1 != reviewer3)  // Different avatar URL
        #expect(reviewer1 != reviewer4)  // Different login
        #expect(reviewer1 != reviewer5)  // One has avatar, one doesn't
    }

    @Test
    func `Reviewer equality handles nil avatar URLs`() {
        let reviewer1 = Reviewer(login: "octocat", avatarURL: nil)
        let reviewer2 = Reviewer(login: "octocat", avatarURL: nil)

        #expect(reviewer1 == reviewer2)
    }

    // MARK: - Decodable Tests

    @Test
    func `Reviewer decodes from JSON with avatar URL`() throws {
        let json = """
            {
                "login": "octocat",
                "avatar_url": "https://avatars.githubusercontent.com/u/1"
            }
            """

        let data = try #require(json.data(using: .utf8))
        let reviewer = try JSONDecoder().decode(Reviewer.self, from: data)

        #expect(reviewer.login == "octocat")
        #expect(reviewer.avatarURL?.absoluteString == "https://avatars.githubusercontent.com/u/1")
    }

    @Test
    func `Reviewer decodes from JSON without avatar URL`() throws {
        let json = """
            {
                "login": "octocat"
            }
            """

        let data = try #require(json.data(using: .utf8))
        let reviewer = try JSONDecoder().decode(Reviewer.self, from: data)

        #expect(reviewer.login == "octocat")
        #expect(reviewer.avatarURL == nil)
    }

    @Test
    func `Reviewer decodes from JSON with null avatar URL`() throws {
        let json = """
            {
                "login": "octocat",
                "avatar_url": null
            }
            """

        let data = try #require(json.data(using: .utf8))
        let reviewer = try JSONDecoder().decode(Reviewer.self, from: data)

        #expect(reviewer.login == "octocat")
        #expect(reviewer.avatarURL == nil)
    }

    @Test
    func `Reviewer decoding fails for empty login`() throws {
        let json = """
            {
                "login": "",
                "avatar_url": "https://avatars.githubusercontent.com/u/1"
            }
            """

        let data = try #require(json.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Reviewer.self, from: data)
        }
    }

    @Test
    func `Reviewer decoding fails for missing login`() throws {
        let json = """
            {
                "avatar_url": "https://avatars.githubusercontent.com/u/1"
            }
            """

        let data = try #require(json.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Reviewer.self, from: data)
        }
    }

    @Test
    func `Reviewer decoding handles string avatar URL`() throws {
        let json = """
            {
                "login": "octocat",
                "avatar_url": "not-a-valid-url"
            }
            """

        let data = try #require(json.data(using: .utf8))
        let reviewer = try JSONDecoder().decode(Reviewer.self, from: data)

        // Foundation's URL initializer accepts various string formats
        #expect(reviewer.login == "octocat")
        #expect(reviewer.avatarURL != nil)
        #expect(reviewer.avatarURL?.absoluteString == "not-a-valid-url")
    }

    // MARK: - Sendable Tests

    @Test
    func `Reviewer is Sendable and thread-safe`() throws {
        let avatarURL = try #require(URL(string: "https://avatars.githubusercontent.com/u/1"))
        let reviewer = Reviewer(login: "octocat", avatarURL: avatarURL)

        // This test verifies that Reviewer conforms to Sendable
        // If this compiles, it proves thread-safety guarantees
        let _: any Sendable = reviewer

        #expect(reviewer.login == "octocat")
    }
}
