import Foundation
import OSLog

private let logger = Logger(subsystem: "com.gitreviewit.app", category: "Reviewer")

/// Review state for a pull request reviewer
enum ReviewState: String, Codable, Sendable {
    case requested  // Reviewer requested but hasn't reviewed yet
    case approved  // Reviewer approved the PR
    case changesRequested = "changes_requested"  // Reviewer requested changes
    case commented  // Reviewer commented without approval/rejection
}

/// Represents a user requested to review or who has reviewed a pull request
///
/// Reviewers are GitHub users who have been explicitly requested to review a PR
/// or have already submitted a review.
/// This model captures the essential information needed to display reviewer information
/// in the PR list preview.
///
/// **Invariants**:
/// - `login` must not be empty
/// - `avatarURL` may be nil if the user has no avatar or the API didn't provide it
/// - `state` indicates whether review is pending or completed
///
/// **Usage**:
/// ```swift
/// let reviewer = Reviewer(
///     login: "octocat",
///     avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1"),
///     state: .requested
/// )
/// ```
struct Reviewer: Identifiable, Equatable, Sendable {
    let login: String
    let avatarURL: URL?
    let state: ReviewState

    var id: String { login }

    /// Creates a new reviewer with validation
    ///
    /// - Parameters:
    ///   - login: GitHub username (must not be empty)
    ///   - avatarURL: Optional URL to the user's avatar image
    ///   - state: Review state (requested, approved, etc.)
    ///
    /// - Precondition: `login` must not be empty
    init(login: String, avatarURL: URL?, state: ReviewState = .requested) {
        guard !login.isEmpty else {
            preconditionFailure("login must not be empty")
        }

        self.login = login
        self.avatarURL = avatarURL
        self.state = state
        logger.debug("Created Reviewer: \(login) (\(state.rawValue))")
    }
}

// MARK: - Decodable Conformance

extension Reviewer: Decodable {
    enum CodingKeys: String, CodingKey {
        case login
        case avatarURL = "avatar_url"
        case state
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let login = try container.decode(String.self, forKey: .login)
        let avatarURL = try container.decodeIfPresent(URL.self, forKey: .avatarURL)
        let state = try container.decodeIfPresent(ReviewState.self, forKey: .state) ?? .requested

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
        self.state = state
    }
}
