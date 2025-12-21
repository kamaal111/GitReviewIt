import Foundation

/// Represents a GitHub team
struct Team: Codable, Identifiable, Sendable {
    /// Unique identifier
    let id: Int
    
    /// Team name (e.g., "Core Team")
    let name: String
    
    /// Team slug (e.g., "core-team")
    let slug: String
    
    /// Organization the team belongs to
    let organization: Organization
    
    /// Full team slug including organization (e.g., "org/team-slug")
    var fullSlug: String {
        "\(organization.login)/\(slug)"
    }
    
    struct Organization: Codable, Sendable {
        let login: String
    }
}

