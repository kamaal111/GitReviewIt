import Foundation

/// High-level abstraction for GitHub API operations.
/// Implementations handle authentication, request construction,
/// response parsing, and error mapping.
protocol GitHubAPI: Sendable {
    /// Exchanges OAuth authorization code for access token
    ///
    /// - Parameters:
    ///   - code: Authorization code from OAuth callback
    ///   - clientId: GitHub OAuth app client ID
    ///   - clientSecret: GitHub OAuth app client secret
    /// - Returns: GitHubToken with access token and metadata
    /// - Throws: APIError if exchange fails
    func exchangeCodeForToken(
        code: String,
        clientId: String,
        clientSecret: String
    ) async throws -> GitHubToken
    
    /// Fetches the authenticated user's GitHub profile
    ///
    /// - Parameter token: OAuth access token
    /// - Returns: AuthenticatedUser with username and profile info
    /// - Throws: APIError if request fails or token is invalid
    func fetchUser(token: String) async throws -> AuthenticatedUser
    
    /// Fetches pull requests where the authenticated user's review is requested
    ///
    /// - Parameter token: OAuth access token
    /// - Returns: Array of PullRequest objects (may be empty)
    /// - Throws: APIError if request fails
    func fetchReviewRequests(token: String) async throws -> [PullRequest]
}
