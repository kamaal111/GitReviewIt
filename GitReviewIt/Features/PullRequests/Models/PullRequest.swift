import Foundation

/// Represents a GitHub pull request awaiting the user's review
struct PullRequest: Identifiable, Equatable, Sendable {
    /// Unique identifier in "owner/repo#number" format
    var id: String {
        "\(repositoryOwner)/\(repositoryName)#\(number)"
    }
    
    /// Repository owner username (e.g., "apple")
    let repositoryOwner: String
    
    /// Repository name (e.g., "swift")
    let repositoryName: String
    
    /// PR number within repository
    let number: Int
    
    /// PR title
    let title: String
    
    /// Username of PR author
    let authorLogin: String
    
    /// Avatar URL for PR author
    let authorAvatarURL: URL?
    
    /// Last update timestamp
    let updatedAt: Date
    
    /// GitHub web URL for opening PR
    let htmlURL: URL
    
    /// Repository full name in "owner/repo" format
    var repositoryFullName: String {
        "\(repositoryOwner)/\(repositoryName)"
    }
    
    /// Creates a new pull request
    /// - Parameters:
    ///   - repositoryOwner: Repository owner username (must not be empty)
    ///   - repositoryName: Repository name (must not be empty)
    ///   - number: PR number within repository (must be positive)
    ///   - title: PR title (must not be empty)
    ///   - authorLogin: Username of PR author (must not be empty)
    ///   - authorAvatarURL: Avatar URL for PR author
    ///   - updatedAt: Last update timestamp (must not be in future)
    ///   - htmlURL: GitHub web URL for opening PR
    init(
        repositoryOwner: String,
        repositoryName: String,
        number: Int,
        title: String,
        authorLogin: String,
        authorAvatarURL: URL?,
        updatedAt: Date,
        htmlURL: URL
    ) {
        precondition(!repositoryOwner.isEmpty, "Repository owner cannot be empty")
        precondition(!repositoryName.isEmpty, "Repository name cannot be empty")
        precondition(number > 0, "PR number must be positive")
        precondition(!title.isEmpty, "PR title cannot be empty")
        precondition(!authorLogin.isEmpty, "Author login cannot be empty")
        precondition(updatedAt <= Date(), "Updated date cannot be in future")
        
        self.repositoryOwner = repositoryOwner
        self.repositoryName = repositoryName
        self.number = number
        self.title = title
        self.authorLogin = authorLogin
        self.authorAvatarURL = authorAvatarURL
        self.updatedAt = updatedAt
        self.htmlURL = htmlURL
    }
}
