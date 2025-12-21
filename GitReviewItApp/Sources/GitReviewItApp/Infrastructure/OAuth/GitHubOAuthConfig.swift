//
//  GitHubOAuthConfig.swift
//  GitReviewIt
//
//  Created by Kamaal M Farah on 12/20/25.
//

enum GitHubOAuthConfig {
    static let clientId = "YOUR_GITHUB_CLIENT_ID"
    static let callbackURLScheme = "gitreviewit"
    static let scopes = ["repo"]
    
    // PKCE support - no client secret needed!
    static func generateCodeVerifier() -> String {
        fatalError("To be implemented")
    }

    static func generateCodeChallenge(from verifier: String) -> String {
        fatalError("To be implemented")
    }
}
