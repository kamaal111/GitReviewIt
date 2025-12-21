import Foundation

/// Represents credentials for authenticating with GitHub API (including GitHub Enterprise)
struct GitHubCredentials: Codable, Equatable, Sendable {
    /// The Personal Access Token (PAT)
    let token: String

    /// The API base URL (e.g., "https://api.github.com" or "https://github.company.com/api/v3")
    let baseURL: String

    /// Creates a new set of GitHub credentials
    /// - Parameters:
    ///   - token: The Personal Access Token (must not be empty)
    ///   - baseURL: The API base URL (must be a valid URL string)
    init(token: String, baseURL: String) {
        precondition(!token.isEmpty, "Token cannot be empty")
        precondition(URL(string: baseURL) != nil, "Base URL must be a valid URL")

        self.token = token
        self.baseURL = baseURL
    }
}
