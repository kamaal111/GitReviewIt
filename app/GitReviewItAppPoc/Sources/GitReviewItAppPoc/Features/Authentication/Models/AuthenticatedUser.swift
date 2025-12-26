import Foundation

/// Represents the currently logged-in GitHub user
struct AuthenticatedUser: Codable, Equatable, Sendable {
    /// GitHub username (e.g., "octocat")
    let login: String

    /// Display name (may be nil if user hasn't set one)
    let name: String?

    /// URL to user's profile avatar image
    let avatarURL: URL?

    enum CodingKeys: String, CodingKey {
        case login
        case name
        case avatarURL = "avatar_url"
    }

    /// Creates a new authenticated user
    /// - Parameters:
    ///   - login: GitHub username (must not be empty)
    ///   - name: Display name
    ///   - avatarURL: URL to user's profile avatar image
    init(login: String, name: String? = nil, avatarURL: URL? = nil) {
        precondition(!login.isEmpty, "Login cannot be empty")
        self.login = login
        self.name = name
        self.avatarURL = avatarURL
    }
}
