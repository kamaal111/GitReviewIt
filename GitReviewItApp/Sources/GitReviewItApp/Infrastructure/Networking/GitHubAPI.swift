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

// MARK: - GitHubAPIClient

/// Production implementation of GitHubAPI using HTTPClient
final class GitHubAPIClient: GitHubAPI {
    private let httpClient: HTTPClient
    private let decoder: JSONDecoder
    private let apiBaseURL: String
    private let oauthBaseURL: String
    
    /// Initialize with an HTTPClient for network operations
    /// - Parameters:
    ///   - httpClient: HTTPClient for making network requests
    ///   - apiBaseURL: Base URL for GitHub API (default: https://api.github.com for GitHub.com, or https://github.enterprise.com/api/v3 for Enterprise)
    ///   - oauthBaseURL: Base URL for OAuth endpoints (default: https://github.com for GitHub.com, or https://github.enterprise.com for Enterprise)
    init(
        httpClient: HTTPClient,
        apiBaseURL: String = "https://api.github.com",
        oauthBaseURL: String = "https://github.com"
    ) {
        self.httpClient = httpClient
        self.apiBaseURL = apiBaseURL.trimmingSuffix("/")
        self.oauthBaseURL = oauthBaseURL.trimmingSuffix("/")
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - GitHubAPI Methods
    
    func exchangeCodeForToken(
        code: String,
        clientId: String,
        clientSecret: String
    ) async throws -> GitHubToken {
        guard let url = URL(string: "\(oauthBaseURL)/login/oauth/access_token") else {
            throw APIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "code": code,
            "redirect_uri": "gitreviewit://oauth-callback"
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await httpClient.perform(request)
            
            // Check for OAuth-specific errors in response
            if let errorResponse = try? decoder.decode(OAuthErrorResponse.self, from: data) {
                throw APIError.httpError(statusCode: response.statusCode, message: errorResponse.error_description)
            }
            
            guard response.statusCode == 200 else {
                throw mapHTTPError(statusCode: response.statusCode, data: data, response: response)
            }
            
            let tokenResponse = try decoder.decode(TokenResponse.self, from: data)
            
            // Parse scopes from comma-separated string
            let scopes = Set(tokenResponse.scope.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) })
            
            return GitHubToken(
                value: tokenResponse.access_token,
                createdAt: Date(),
                scopes: scopes.isEmpty ? [""] : scopes
            )
        } catch let error as HTTPError {
            throw mapHTTPErrorToAPIError(error)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    func fetchUser(token: String) async throws -> AuthenticatedUser {
        guard let url = URL(string: "\(apiBaseURL)/user") else {
            throw APIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        
        do {
            let (data, response) = try await httpClient.perform(request)
            
            guard (200...299).contains(response.statusCode) else {
                throw mapHTTPError(statusCode: response.statusCode, data: data, response: response)
            }
            
            return try decoder.decode(AuthenticatedUser.self, from: data)
        } catch let error as HTTPError {
            throw mapHTTPErrorToAPIError(error)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    func fetchReviewRequests(token: String) async throws -> [PullRequest] {
        // First, fetch the authenticated user to get their username
        let user = try await fetchUser(token: token)
        
        // Build search query for PRs where this user's review is requested
        let query = "type:pr+state:open+review-requested:\(user.login)"
        guard var components = URLComponents(string: "\(apiBaseURL)/search/issues") else {
            throw APIError.invalidResponse
        }
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "sort", value: "updated"),
            URLQueryItem(name: "order", value: "desc"),
            URLQueryItem(name: "per_page", value: "50")
        ]
        
        guard let url = components.url else {
            throw APIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        
        do {
            let (data, response) = try await httpClient.perform(request)
            
            guard (200...299).contains(response.statusCode) else {
                throw mapHTTPError(statusCode: response.statusCode, data: data, response: response)
            }
            
            let searchResponse = try decoder.decode(SearchIssuesResponse.self, from: data)
            
            // Convert search results to PullRequest models
            return searchResponse.items.compactMap { item in
                // Extract repository info from repository_url
                // Format: "https://api.github.com/repos/owner/repo"
                guard let repoComponents = extractRepositoryInfo(from: item.repository_url) else {
                    return nil
                }
                
                return PullRequest(
                    repositoryOwner: repoComponents.owner,
                    repositoryName: repoComponents.name,
                    number: item.number,
                    title: item.title,
                    authorLogin: item.user.login,
                    authorAvatarURL: item.user.avatar_url,
                    updatedAt: item.updated_at,
                    htmlURL: item.html_url
                )
            }
        } catch let error as HTTPError {
            throw mapHTTPErrorToAPIError(error)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    // MARK: - Helper Methods
    
    private func mapHTTPError(statusCode: Int, data: Data, response: HTTPURLResponse) -> APIError {
        switch statusCode {
        case 401:
            return .unauthorized
        case 403:
            // Check for rate limiting
            if let rateLimitReset = response.value(forHTTPHeaderField: "X-RateLimit-Reset"),
               let timestamp = TimeInterval(rateLimitReset) {
                let resetDate = Date(timeIntervalSince1970: timestamp)
                return .rateLimitExceeded(resetAt: resetDate)
            }
            return .rateLimitExceeded(resetAt: nil)
        case 404:
            return .notFound
        case 422:
            return .invalidResponse
        case 500...599:
            return .serverError(statusCode: statusCode)
        default:
            // Try to extract error message from response
            if let errorMessage = try? decoder.decode(GitHubErrorResponse.self, from: data) {
                return .httpError(statusCode: statusCode, message: errorMessage.message)
            }
            return .httpError(statusCode: statusCode, message: nil)
        }
    }
    
    private func mapHTTPErrorToAPIError(_ error: HTTPError) -> APIError {
        switch error {
        case .connectionFailed, .timeout, .dnsError:
            return .networkError(error)
        case .invalidResponse, .noData:
            return .invalidResponse
        case .cancelled:
            return .unknown(error)
        default:
            return .unknown(error)
        }
    }
    
    private func extractRepositoryInfo(from urlString: String) -> (owner: String, name: String)? {
        // Parse "https://api.github.com/repos/owner/repo"
        guard let url = URL(string: urlString) else { return nil }
        let components = url.pathComponents
        
        // Path components: ["", "repos", "owner", "repo"]
        guard components.count >= 4,
              components[1] == "repos" else {
            return nil
        }
        
        return (owner: components[2], name: components[3])
    }
}

// MARK: - Response Models

private struct TokenResponse: Decodable {
    let access_token: String
    let token_type: String
    let scope: String
}

private struct OAuthErrorResponse: Decodable {
    let error: String
    let error_description: String
}

private struct GitHubErrorResponse: Decodable {
    let message: String
}

private struct SearchIssuesResponse: Decodable {
    let total_count: Int
    let incomplete_results: Bool
    let items: [SearchIssueItem]
}

private struct SearchIssueItem: Decodable {
    let number: Int
    let title: String
    let html_url: URL
    let updated_at: Date
    let state: String
    let user: SearchUser
    let repository_url: String
}

private struct SearchUser: Decodable {
    let login: String
    let avatar_url: URL?
}

// MARK: - String Extension

private extension String {
    /// Removes trailing slash from string if present
    func trimmingSuffix(_ suffix: String) -> String {
        guard hasSuffix(suffix) else { return self }
        return String(dropLast(suffix.count))
    }
}
