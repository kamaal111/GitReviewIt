import Foundation

/// Represents an OAuth access token for authenticating with GitHub API
struct GitHubToken: Codable, Equatable, Sendable {
    /// The raw OAuth token string
    let value: String
    
    /// Timestamp when token was obtained
    let createdAt: Date
    
    /// OAuth scopes granted (e.g., "repo", "user")
    let scopes: Set<String>
    
    /// Creates a new GitHub token
    /// - Parameters:
    ///   - value: The raw OAuth token string (must not be empty)
    ///   - createdAt: Timestamp when token was obtained (defaults to now, must not be in future)
    ///   - scopes: OAuth scopes granted (must not be empty)
    init(value: String, createdAt: Date = Date(), scopes: Set<String>) {
        precondition(!value.isEmpty, "Token value cannot be empty")
        precondition(createdAt <= Date(), "Token creation date cannot be in future")
        precondition(!scopes.isEmpty, "Token must have at least one scope")
        
        self.value = value
        self.createdAt = createdAt
        self.scopes = scopes
    }
}
