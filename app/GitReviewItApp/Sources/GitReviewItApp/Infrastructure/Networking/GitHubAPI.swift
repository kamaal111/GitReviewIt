import Foundation

/// High-level abstraction for GitHub API operations.
/// Implementations handle authentication, request construction,
/// response parsing, and error mapping.
protocol GitHubAPI: Sendable {
    /// Fetches the authenticated user's GitHub profile
    ///
    /// - Parameter credentials: GitHub credentials (token + baseURL)
    /// - Returns: AuthenticatedUser with username and profile info
    /// - Throws: APIError if request fails or token is invalid
    func fetchUser(credentials: GitHubCredentials) async throws -> AuthenticatedUser

    /// Fetches teams for the authenticated user
    ///
    /// - Parameter credentials: GitHub credentials (token + baseURL)
    /// - Returns: Array of Team objects (may be empty)
    /// - Throws: APIError if request fails
    func fetchTeams(credentials: GitHubCredentials) async throws -> [Team]

    /// Fetches pull requests where the authenticated user's review is requested or they are assigned
    ///
    /// - Parameter credentials: GitHub credentials (token + baseURL)
    /// - Returns: Array of PullRequest objects (may be empty)
    /// - Throws: APIError if request fails
    func fetchReviewRequests(credentials: GitHubCredentials) async throws -> [PullRequest]

    /// Fetches detailed information for a specific pull request
    ///
    /// - Parameters:
    ///   - owner: Repository owner username
    ///   - repo: Repository name
    ///   - number: PR number
    ///   - credentials: GitHub credentials (token + baseURL)
    /// - Returns: PRPreviewMetadata with change stats and reviewers
    /// - Throws: APIError if request fails or PR not found
    func fetchPRDetails(
        owner: String,
        repo: String,
        number: Int,
        credentials: GitHubCredentials
    ) async throws -> PRPreviewMetadata
}

// MARK: - GitHubAPIClient

/// Production implementation of GitHubAPI using HTTPClient
final class GitHubAPIClient: GitHubAPI {
    private let httpClient: HTTPClient
    private let decoder: JSONDecoder

    /// Initialize with an HTTPClient for network operations
    /// - Parameter httpClient: HTTPClient for making network requests
    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - GitHubAPI Methods

    func fetchUser(credentials: GitHubCredentials) async throws -> AuthenticatedUser {
        let baseURL = credentials.baseURL.trimmingSuffix("/")
        guard let url = URL(string: "\(baseURL)/user") else { throw APIError.invalidResponse }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(credentials.token)", forHTTPHeaderField: "Authorization")
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

    func fetchTeams(credentials: GitHubCredentials) async throws -> [Team] {
        let baseURL = credentials.baseURL.trimmingSuffix("/")
        guard let url = URL(string: "\(baseURL)/user/teams") else { throw APIError.invalidResponse }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(credentials.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        do {
            let (data, response) = try await httpClient.perform(request)

            guard (200...299).contains(response.statusCode) else {
                throw mapHTTPError(statusCode: response.statusCode, data: data, response: response)
            }

            let teams = try decoder.decode([Team].self, from: data)

            // Deduplicate teams by fullSlug (org/slug) to prevent duplicates in UI
            var uniqueTeams: [String: Team] = [:]
            for team in teams {
                guard uniqueTeams[team.fullSlug] == nil else {
                    continue
                }
                uniqueTeams[team.fullSlug] = team
            }

            return Array(uniqueTeams.values)
        } catch let error as HTTPError {
            throw mapHTTPErrorToAPIError(error)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func fetchReviewRequests(credentials: GitHubCredentials) async throws -> [PullRequest] {
        // First, fetch the authenticated user to get their username
        let user = try await fetchUser(credentials: credentials)

        // Try to fetch teams, but don't fail if we can't (e.g. scopes, not in org, etc.)
        let teams: [Team]
        do {
            teams = try await fetchTeams(credentials: credentials)
        } catch {
            // Log error if we had logging, but for now just proceed without teams
            teams = []
        }

        // Build list of queries
        var queries = [
            "type:pr+state:open+review-requested:\(user.login)+-author:\(user.login)",
            "type:pr+state:open+assignee:\(user.login)+-author:\(user.login)",
            "type:pr+state:open+reviewed-by:\(user.login)+-author:\(user.login)",
        ]
        for team in teams {
            queries.append("type:pr+state:open+team-review-requested:\(team.fullSlug)+-author:\(user.login)")
        }

        // Execute searches in parallel
        return try await withThrowingTaskGroup(of: [PullRequest].self) { group in
            for query in queries {
                group.addTask {
                    try await self.performSearch(query: query, credentials: credentials)
                }
            }

            var allPRs: [PullRequest] = []
            for try await prs in group {
                allPRs.append(contentsOf: prs)
            }

            // Deduplicate by ID (which is owner/repo#number)
            let uniquePRs = Dictionary(grouping: allPRs, by: { $0.id })
                .compactMap { $0.value.first }
                .sorted { $0.updatedAt > $1.updatedAt }

            return uniquePRs
        }
    }

    func fetchPRDetails(
        owner: String,
        repo: String,
        number: Int,
        credentials: GitHubCredentials
    ) async throws -> PRPreviewMetadata {
        let baseURL = credentials.baseURL.trimmingSuffix("/")
        guard let url = URL(string: "\(baseURL)/repos/\(owner)/\(repo)/pulls/\(number)") else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(credentials.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        do {
            let (data, response) = try await httpClient.perform(request)

            guard (200...299).contains(response.statusCode) else {
                throw mapHTTPError(statusCode: response.statusCode, data: data, response: response)
            }

            let detailsResponse = try decoder.decode(PRDetailsResponse.self, from: data)
            return detailsResponse.toPRPreviewMetadata()
        } catch let error as HTTPError {
            throw mapHTTPErrorToAPIError(error)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func performSearch(query: String, credentials: GitHubCredentials) async throws -> [PullRequest] {
        let baseURL = credentials.baseURL.trimmingSuffix("/")
        guard var components = URLComponents(string: "\(baseURL)/search/issues") else { throw APIError.invalidResponse }
        components.queryItems = [URLQueryItem(name: "q", value: query)]

        guard let url = components.url else { throw APIError.invalidResponse }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(credentials.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        do {
            let (data, response) = try await httpClient.perform(request)

            guard (200...299).contains(response.statusCode) else {
                throw mapHTTPError(statusCode: response.statusCode, data: data, response: response)
            }

            let searchResponse = try decoder.decode(SearchIssuesResponse.self, from: data)
            return searchResponse.items.compactMap { self.mapSearchIssueToPullRequest($0) }
        } catch let error as HTTPError {
            throw mapHTTPErrorToAPIError(error)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func mapSearchIssueToPullRequest(_ item: SearchIssueItem) -> PullRequest? {
        guard let (owner, name) = extractRepositoryInfo(from: item.repository_url) else { return nil }

        // Map SearchLabel to PRLabel
        let labels = item.labels.map { searchLabel in
            PRLabel(name: searchLabel.name, color: searchLabel.color)
        }

        return PullRequest(
            repositoryOwner: owner,
            repositoryName: name,
            number: item.number,
            title: item.title,
            authorLogin: item.user.login,
            authorAvatarURL: item.user.avatar_url,
            updatedAt: item.updated_at,
            htmlURL: item.html_url,
            commentCount: item.comments,
            labels: labels,
            previewMetadata: nil
        )
    }

    // MARK: - Helper Methods

    private func mapHTTPError(statusCode: Int, data: Data, response: HTTPURLResponse) -> APIError {
        switch statusCode {
        case 401:
            return .unauthorized
        case 403:
            // Check for rate limiting
            // GitHub sends X-RateLimit-Remaining: 0 when limit is exceeded
            guard let remainingStr = response.value(forHTTPHeaderField: "X-RateLimit-Remaining") else {
                return defaultForbiddenError(statusCode: statusCode, data: data)
            }
            guard let remaining = Int(remainingStr) else {
                return defaultForbiddenError(statusCode: statusCode, data: data)
            }
            guard remaining == 0 else { return defaultForbiddenError(statusCode: statusCode, data: data) }
            guard let rateLimitReset = response.value(forHTTPHeaderField: "X-RateLimit-Reset") else {
                return .rateLimitExceeded(resetAt: nil)
            }
            guard let timestamp = TimeInterval(rateLimitReset) else { return .rateLimitExceeded(resetAt: nil) }

            let resetDate = Date(timeIntervalSince1970: timestamp)
            return .rateLimitExceeded(resetAt: resetDate)
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

    private func defaultForbiddenError(statusCode: Int, data: Data) -> APIError {
        // If not a rate limit 403, it's a permission issue
        if let errorMessage = try? decoder.decode(GitHubErrorResponse.self, from: data) {
            return .httpError(statusCode: statusCode, message: errorMessage.message)
        }
        return .httpError(statusCode: statusCode, message: "Access forbidden")
    }

    private func mapHTTPErrorToAPIError(_ error: HTTPError) -> APIError {
        switch error {
        case .connectionFailed(let underlyingError):
            // Check for offline status
            let nsError = underlyingError as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorNotConnectedToInternet {
                return .networkUnreachable
            }
            return .networkError(underlyingError)
        case .timeout, .dnsError:
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
        // Check for "repos" in path components to handle enterprise URLs or weird paths
        // Typically it is [..., "repos", "owner", "repo"]
        if let reposIndex = components.lastIndex(of: "repos"), reposIndex + 2 < components.count {
            return (owner: components[reposIndex + 1], name: components[reposIndex + 2])
        }

        // Fallback for standard path
        if components.count >= 4, components[1] == "repos" {
            return (owner: components[2], name: components[3])
        }

        return nil
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
    let comments: Int
    let labels: [SearchLabel]
}

private struct SearchLabel: Decodable {
    let name: String
    let color: String
}

private struct SearchUser: Decodable {
    let login: String
    let avatar_url: URL?
}

// MARK: - String Extension

extension String {
    /// Removes trailing slash from string if present
    fileprivate func trimmingSuffix(_ suffix: String) -> String {
        guard hasSuffix(suffix) else { return self }
        return String(dropLast(suffix.count))
    }
}
