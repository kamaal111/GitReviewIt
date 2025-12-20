# API Contracts: Infrastructure Layer

**Feature**: 001-github-pr-viewer  
**Date**: December 20, 2025  
**Status**: Complete

This document defines all protocol boundaries for the infrastructure layer, enabling dependency injection and testing.

---

## HTTPClient Protocol

**Purpose**: Abstraction over URLSession for HTTP request/response handling.

**Responsibilities**:
- Execute HTTP requests
- Return response data and metadata
- Propagate network errors

**Protocol Definition**:
```swift
/// Abstraction for HTTP networking. Implementations should handle
/// network requests and return response data with HTTP metadata.
protocol HTTPClient: Sendable {
    /// Executes an HTTP request and returns response data with HTTP metadata.
    ///
    /// - Parameter request: The URLRequest to execute
    /// - Returns: Tuple of response data and HTTPURLResponse
    /// - Throws: URLError for network failures, or HTTPError for invalid responses
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

/// Errors specific to HTTP operations
enum HTTPError: Error {
    case invalidResponse  // Response was not HTTPURLResponse
}
```

**Implementations**:
- Production: `URLSessionHTTPClient` (wraps URLSession)
- Testing: `MockHTTPClient` (returns fixture data)

**Example Usage**:
```swift
let request = URLRequest(url: url)
let (data, response) = try await httpClient.data(for: request)
guard response.statusCode == 200 else {
    throw APIError.invalidResponse(statusCode: response.statusCode)
}
```

---

## TokenStorage Protocol

**Purpose**: Abstraction for secure token persistence (Keychain).

**Responsibilities**:
- Save OAuth token securely
- Retrieve stored token
- Delete token on logout

**Protocol Definition**:
```swift
/// Abstraction for secure token storage. Implementations should
/// store tokens using platform-appropriate secure storage (e.g., Keychain).
protocol TokenStorage: Sendable {
    /// Saves a token to secure storage
    ///
    /// - Parameter token: The token string to save
    /// - Throws: TokenStorageError if save fails
    func saveToken(_ token: String) async throws
    
    /// Loads the stored token from secure storage
    ///
    /// - Returns: The token string, or nil if no token is stored
    /// - Throws: TokenStorageError if load fails (excluding "not found" case)
    func loadToken() async throws -> String?
    
    /// Deletes the stored token from secure storage
    ///
    /// - Throws: TokenStorageError if delete fails
    func deleteToken() async throws
}

/// Errors specific to token storage operations
enum TokenStorageError: Error, LocalizedError {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save token to keychain (status: \(status))"
        case .loadFailed(let status):
            return "Failed to load token from keychain (status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete token from keychain (status: \(status))"
        case .notFound:
            return "No token found in keychain"
        }
    }
}
```

**Implementations**:
- Production: `KeychainTokenStorage` (uses Security framework)
- Testing: `MockTokenStorage` (in-memory dictionary)

**Example Usage**:
```swift
// Save token after OAuth
try await tokenStorage.saveToken("ghp_abc123...")

// Load token at app launch
if let token = try await tokenStorage.loadToken() {
    // User is authenticated
}

// Delete token on logout
try await tokenStorage.deleteToken()
```

---

## OAuthManager Protocol

**Purpose**: Abstraction for GitHub OAuth flow (ASWebAuthenticationSession).

**Responsibilities**:
- Present OAuth web authentication UI
- Handle redirect callback
- Return authorization code or error

**Protocol Definition**:
```swift
/// Abstraction for OAuth authentication flow. Implementations should
/// present platform-appropriate OAuth UI and handle callbacks.
protocol OAuthManager: Sendable {
    /// Starts OAuth authentication flow
    ///
    /// - Parameters:
    ///   - authorizationURL: The OAuth provider's authorization URL with query params
    ///   - callbackURLScheme: The custom URL scheme for redirect (e.g., "gitreviewit")
    /// - Returns: The authorization code from successful authentication
    /// - Throws: OAuthError if authentication fails or is cancelled
    func authenticate(
        authorizationURL: URL,
        callbackURLScheme: String
    ) async throws -> String  // Returns authorization code
}

/// Errors specific to OAuth operations
enum OAuthError: Error, LocalizedError {
    case userCancelled
    case invalidState  // State parameter mismatch (CSRF protection)
    case invalidCallback  // Callback URL malformed or missing code
    case authenticationFailed(String)  // OAuth error from provider
    
    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "Authentication was cancelled."
        case .invalidState:
            return "Authentication failed: security validation error."
        case .invalidCallback:
            return "Authentication failed: invalid response from GitHub."
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        }
    }
}
```

**Implementations**:
- Production: `ASWebAuthenticationSessionOAuthManager`
- Testing: `MockOAuthManager` (returns predetermined code or error)

**Example Usage**:
```swift
let authURL = URL(string: "https://github.com/login/oauth/authorize?client_id=...&state=...")!
let code = try await oauthManager.authenticate(
    authorizationURL: authURL,
    callbackURLScheme: "gitreviewit"
)
// Exchange code for token via GitHub API
```

---

## GitHubAPI Protocol

**Purpose**: High-level abstraction for GitHub API operations.

**Responsibilities**:
- Fetch authenticated user info
- Fetch pull requests awaiting review
- Handle token exchange (OAuth code → access token)
- Map HTTP responses to domain models
- Map HTTP errors to APIError

**Protocol Definition**:
```swift
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
```

**Implementations**:
- Production: `GitHubAPIClient` (constructs requests, parses JSON)
- Testing: `MockGitHubAPI` (returns fixture data without network calls)

**Example Usage**:
```swift
// Exchange code for token
let token = try await githubAPI.exchangeCodeForToken(
    code: "oauth_code_123",
    clientId: "client_id",
    clientSecret: "client_secret"
)

// Fetch user
let user = try await githubAPI.fetchUser(token: token.value)

// Fetch PRs
let prs = try await githubAPI.fetchReviewRequests(token: token.value)
```

---

## Request/Response Structures

### OAuth Token Exchange Request

**Endpoint**: `POST https://github.com/login/oauth/access_token`

**Headers**:
```
Accept: application/json
Content-Type: application/json
```

**Request Body**:
```json
{
  "client_id": "your_client_id",
  "client_secret": "your_client_secret",
  "code": "authorization_code",
  "redirect_uri": "gitreviewit://oauth-callback"
}
```

**Success Response (200)**:
```json
{
  "access_token": "gho_16C7e42F292c6912E7710c838347Ae178B4a",
  "token_type": "bearer",
  "scope": "repo,user"
}
```

**Error Response (400/401)**:
```json
{
  "error": "bad_verification_code",
  "error_description": "The code passed is incorrect or expired.",
  "error_uri": "https://docs.github.com/apps/managing-oauth-apps/troubleshooting-oauth-app-access-token-request-errors"
}
```

---

### Get User Request

**Endpoint**: `GET https://api.github.com/user`

**Headers**:
```
Authorization: Bearer gho_16C7e42F292c6912E7710c838347Ae178B4a
Accept: application/vnd.github+json
X-GitHub-Api-Version: 2022-11-28
```

**Success Response (200)**:
```json
{
  "login": "octocat",
  "id": 1,
  "name": "The Octocat",
  "avatar_url": "https://avatars.githubusercontent.com/u/1?v=4",
  "type": "User",
  ...
}
```

**Error Response (401)**:
```json
{
  "message": "Bad credentials",
  "documentation_url": "https://docs.github.com/rest"
}
```

---

### Search Pull Requests Request

**Endpoint**: `GET https://api.github.com/search/issues`

**Query Parameters**:
```
q=type:pr+state:open+review-requested:octocat
sort=updated
order=desc
per_page=50
```

**Headers**:
```
Authorization: Bearer gho_16C7e42F292c6912E7710c838347Ae178B4a
Accept: application/vnd.github+json
X-GitHub-Api-Version: 2022-11-28
```

**Success Response (200)**:
```json
{
  "total_count": 2,
  "incomplete_results": false,
  "items": [
    {
      "number": 123,
      "title": "Add feature X",
      "html_url": "https://github.com/owner/repo/pull/123",
      "updated_at": "2025-12-20T10:30:00Z",
      "state": "open",
      "user": {
        "login": "author-username",
        "avatar_url": "https://avatars.githubusercontent.com/u/456?v=4"
      },
      "repository_url": "https://api.github.com/repos/owner/repo"
    }
  ]
}
```

**Rate Limit Response (403)**:
```json
{
  "message": "API rate limit exceeded for user ID 1.",
  "documentation_url": "https://docs.github.com/rest/overview/resources-in-the-rest-api#rate-limiting"
}
```

**Rate Limit Headers**:
```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1703080800
```

---

## Error Mapping Strategy

| HTTP Status | Headers/Body Indicators | Maps To APIError |
|-------------|-------------------------|------------------|
| N/A (URLError.notConnectedToInternet) | - | `.networkUnavailable` |
| 401 | - | `.unauthorized` |
| 403 | `X-RateLimit-Remaining: 0` | `.rateLimited(resetDate: ...)` |
| 422 | - | `.invalidResponse(statusCode: 422)` |
| 500-599 | - | `.serverError(statusCode: ...)` |
| 200-299 | Invalid JSON structure | `.invalidResponse(statusCode: ...)` |
| Other | - | `.unknown(error)` |

**Implementation Note**:
Parse `X-RateLimit-Reset` header (Unix timestamp) and convert to Date for `.rateLimited` case.

---

## Summary

All infrastructure protocol boundaries are defined with clear responsibilities, method signatures, and error cases. Implementations are separated into production (using system frameworks) and testing (using mocks/fixtures). Request/response formats are documented for all GitHub API interactions.

Ready to proceed to quickstart.md generation.
