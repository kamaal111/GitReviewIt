import Foundation
import OSLog

private let logger = Logger(subsystem: "com.gitreviewit.app", category: "Reviewer")

/// Represents a user requested to review a pull request
///
/// Reviewers are GitHub users who have been explicitly requested to review a PR.
/// This model captures the essential information needed to display reviewer information
/// in the PR list preview.
///
/// **Invariants**:
/// - `login` must not be empty
/// - `avatarURL` may be nil if the user has no avatar or the API didn't provide it
///
/// **Usage**:
/// ```swift
/// let reviewer = Reviewer(
///     login: "octocat",
///     avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1")
/// )
/// ```
struct Reviewer: Identifiable, Equatable, Sendable {
    let login: String
    let avatarURL: URL?

    var id: String { login }

    /// Creates a new reviewer with validation
    ///
    /// - Parameters:
    ///   - login: GitHub username (must not be empty)
    ///   - avatarURL: Optional URL to the user's avatar image
    ///
    /// - Precondition: `login` must not be empty
    init(login: String, avatarURL: URL?) {
        guard !login.isEmpty else {
            preconditionFailure("login must not be empty")
        }

        self.login = login
        self.avatarURL = avatarURL
        logger.debug("Created Reviewer: \(login)")
    }
}

// MARK: - Decodable Conformance

extension Reviewer: Decodable {
    enum CodingKeys: String, CodingKey {
        case login
        case avatarURL = "avatar_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let login = try container.decode(String.self, forKey: .login)
        let avatarURL = try container.decodeIfPresent(URL.self, forKey: .avatarURL)

        guard !login.isEmpty else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Reviewer login must not be empty"
                )
            )
        }

        self.login = login
        self.avatarURL = avatarURL
    }
}
