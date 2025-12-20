# Developer Quickstart Guide

**Feature**: 001-github-pr-viewer  
**Date**: December 20, 2025  
**Target Audience**: Developers implementing the GitHub PR Review Viewer MVP

## Prerequisites

- Xcode 16.0+ (for Swift 6.0 support)
- macOS 15.0+ (for running the app)
- GitHub account (for testing OAuth and API)
- GitHub OAuth App credentials (client ID and secret)

---

## GitHub OAuth App Setup

Before implementing the app, you need to create a GitHub OAuth App to obtain client credentials.

### Steps:

1. Go to https://github.com/settings/developers
2. Click "New OAuth App"
3. Fill in the form:
   - **Application name**: GitReviewIt (Dev)
   - **Homepage URL**: https://github.com/kamaal111/GitReviewIt
   - **Authorization callback URL**: `gitreviewit://oauth-callback`
4. Click "Register application"
5. Note your **Client ID** (publicly visible)
6. Click "Generate a new client secret" and note the **Client Secret** (keep private)

### Store Credentials:

Create a file `GitReviewIt/Infrastructure/OAuth/GitHubOAuthConfig.swift`:

```swift
enum GitHubOAuthConfig {
    static let clientId = "your_client_id_here"
    static let clientSecret = "your_client_secret_here"
    static let callbackURLScheme = "gitreviewit"
    static let scopes = ["repo"]  // Access to private repositories
}
```

⚠️ **Security Note**: For MVP, embedding the secret is acceptable. For production, migrate to GitHub Device Flow to eliminate the secret.

---

## Project Structure Overview

```
GitReviewIt/
├── Features/
│   ├── Authentication/
│   │   ├── Views/          # LoginView
│   │   ├── State/          # AuthenticationContainer
│   │   └── Models/         # GitHubToken, AuthenticatedUser
│   └── PullRequests/
│       ├── Views/          # PullRequestListView, PullRequestRow
│       ├── State/          # PullRequestListContainer
│       └── Models/         # PullRequest
├── Shared/
│   ├── Views/              # LoadingView, ErrorView
│   └── Models/             # APIError, LoadingState
├── Infrastructure/
│   ├── Networking/         # HTTPClient, GitHubAPI
│   ├── Storage/            # TokenStorage (Keychain)
│   └── OAuth/              # OAuthManager, GitHubOAuthConfig
├── GitReviewItApp.swift    # App entry point
└── ContentView.swift       # Root view with navigation

GitReviewItTests/
├── IntegrationTests/       # Full-flow tests
├── TestDoubles/            # Mocks for protocols
└── Fixtures/               # JSON response fixtures
```

---

## Implementation Sequence

Follow this order to build the app incrementally with tests at each step:

### 1. Infrastructure Layer (Bottom-Up)

**a. HTTPClient Protocol + Implementation**
- Define `HTTPClient` protocol in `Infrastructure/Networking/HTTPClient.swift`
- Implement `URLSessionHTTPClient` (wraps URLSession)
- Create `MockHTTPClient` in tests with fixture loading

**b. TokenStorage Protocol + Implementation**
- Define `TokenStorage` protocol in `Infrastructure/Storage/TokenStorage.swift`
- Implement `KeychainTokenStorage` (uses Security framework)
- Create `MockTokenStorage` in tests (in-memory dictionary)

**c. OAuthManager Protocol + Implementation**
- Define `OAuthManager` protocol in `Infrastructure/OAuth/OAuthManager.swift`
- Implement `ASWebAuthenticationSessionOAuthManager`
- Create `MockOAuthManager` in tests (returns predetermined code)

**d. GitHubAPI Protocol + Implementation**
- Define `GitHubAPI` protocol in `Infrastructure/Networking/GitHubAPI.swift`
- Implement `GitHubAPIClient` (uses HTTPClient for requests)
- Create `MockGitHubAPI` in tests

### 2. Domain Models

**a. Error Types**
- `APIError` enum in `Shared/Models/APIError.swift`
- `LoadingState<T>` enum in `Shared/Models/LoadingState.swift`

**b. Domain Entities**
- `GitHubToken` struct in `Features/Authentication/Models/GitHubToken.swift`
- `AuthenticatedUser` struct in `Features/Authentication/Models/AuthenticatedUser.swift`
- `PullRequest` struct in `Features/PullRequests/Models/PullRequest.swift`

### 3. State Containers

**a. AuthenticationContainer**
- Create `@Observable` class in `Features/Authentication/State/AuthenticationContainer.swift`
- Implement methods: `startOAuth()`, `completeOAuth(code:)`, `checkExistingToken()`, `logout()`
- Add integration tests in `AuthenticationFlowTests`

**b. PullRequestListContainer**
- Create `@Observable` class in `Features/PullRequests/State/PullRequestListContainer.swift`
- Implement methods: `loadPullRequests()`, `retry()`, `openPR(url:)`
- Add integration tests in `PullRequestListTests`

### 4. Views (Top-Down)

**a. Shared Views**
- `LoadingView` in `Shared/Views/LoadingView.swift` (spinner + message)
- `ErrorView` in `Shared/Views/ErrorView.swift` (error message + retry button)

**b. Authentication Views**
- `LoginView` in `Features/Authentication/Views/LoginView.swift`
  - Shows "Sign in with GitHub" button
  - Owns AuthenticationContainer via @State
  - Calls `startOAuth()` on button tap

**c. Pull Request Views**
- `PullRequestRow` in `Features/PullRequests/Views/PullRequestRow.swift`
  - Displays single PR (repo, title, author, time)
- `PullRequestListView` in `Features/PullRequests/Views/PullRequestListView.swift`
  - Owns PullRequestListContainer via @State
  - Shows loading/error/empty/loaded states
  - Calls `loadPullRequests()` in .task modifier

**d. Root Navigation**
- Update `ContentView.swift` to switch between LoginView and PullRequestListView
- Create `AppContainer` to manage navigation state
- Check token presence at launch

### 5. App Configuration

**a. Info.plist Updates**
- Add `CFBundleURLTypes` with `gitreviewit` scheme for OAuth callback

**b. URL Handling**
- Implement `.onOpenURL` in ContentView to capture OAuth callback

---

## Key Implementation Patterns

### Pattern 1: Protocol Injection for Testability

```swift
// Container owns protocols, not concrete types
@Observable
final class AuthenticationContainer {
    private let oauthManager: OAuthManager
    private let githubAPI: GitHubAPI
    private let tokenStorage: TokenStorage
    
    init(oauthManager: OAuthManager, githubAPI: GitHubAPI, tokenStorage: TokenStorage) {
        self.oauthManager = oauthManager
        self.githubAPI = githubAPI
        self.tokenStorage = tokenStorage
    }
}

// Production usage
let container = AuthenticationContainer(
    oauthManager: ASWebAuthenticationSessionOAuthManager(),
    githubAPI: GitHubAPIClient(httpClient: URLSessionHTTPClient()),
    tokenStorage: KeychainTokenStorage()
)

// Test usage
let container = AuthenticationContainer(
    oauthManager: MockOAuthManager(codeToReturn: "test_code"),
    githubAPI: MockGitHubAPI(fixtures: ...),
    tokenStorage: MockTokenStorage()
)
```

### Pattern 2: View Owns State via @State

```swift
struct PullRequestListView: View {
    @State private var container: PullRequestListContainer
    
    init(githubAPI: GitHubAPI, tokenStorage: TokenStorage) {
        // Inject dependencies, @State owns lifecycle
        _container = State(initialValue: PullRequestListContainer(
            githubAPI: githubAPI,
            tokenStorage: tokenStorage
        ))
    }
    
    var body: some View {
        // View reads container state and sends intent
        List(container.pullRequests) { pr in
            PullRequestRow(pr: pr)
        }
        .task {
            await container.loadPullRequests()
        }
    }
}
```

### Pattern 3: Intent-Based State Container Methods

```swift
// ❌ Bad: Imperative setters
func setPullRequests(_ prs: [PullRequest]) { ... }
func setLoading(_ loading: Bool) { ... }

// ✅ Good: Intent-based methods
func loadPullRequests() async { ... }
func retry() async { ... }
func openPR(url: URL) { ... }
```

### Pattern 4: LoadingState for Async Operations

```swift
@Observable
final class PullRequestListContainer {
    private(set) var loadingState: LoadingState<[PullRequest]> = .idle
    
    func loadPullRequests() async {
        loadingState = .loading
        do {
            let prs = try await githubAPI.fetchReviewRequests(token: ...)
            loadingState = .loaded(prs)
        } catch let error as APIError {
            loadingState = .failed(error)
        }
    }
}

// View uses switch to render state
var body: some View {
    switch container.loadingState {
    case .idle:
        Text("Tap to load")
    case .loading:
        LoadingView()
    case .loaded(let prs):
        List(prs) { pr in PullRequestRow(pr: pr) }
    case .failed(let error):
        ErrorView(error: error, retry: container.retry)
    }
}
```

---

## Testing Strategy

### Integration Test Example

```swift
final class AuthenticationFlowTests: XCTestCase {
    func testSuccessfulLoginFlow() async throws {
        // Arrange: Set up mocks with fixtures
        let mockOAuth = MockOAuthManager(codeToReturn: "test_code")
        let mockHTTP = MockHTTPClient()
        mockHTTP.stubResponse(for: "/login/oauth/access_token", fixture: "token-response.json")
        mockHTTP.stubResponse(for: "/user", fixture: "user-response.json")
        
        let tokenStorage = MockTokenStorage()
        let githubAPI = GitHubAPIClient(httpClient: mockHTTP)
        
        let container = AuthenticationContainer(
            oauthManager: mockOAuth,
            githubAPI: githubAPI,
            tokenStorage: tokenStorage
        )
        
        // Act: Execute OAuth flow
        await container.startOAuth()
        await container.completeOAuth(code: "test_code")
        
        // Assert: Verify state transitions and token storage
        XCTAssertEqual(container.authState, .authenticated)
        XCTAssertNotNil(try await tokenStorage.loadToken())
        XCTAssertEqual(container.user?.login, "octocat")
    }
    
    func testTokenExpirationHandling() async throws {
        // Arrange: Mock returns 401 for PR fetch
        let mockHTTP = MockHTTPClient()
        mockHTTP.stubResponse(for: "/search/issues", statusCode: 401, body: Data())
        
        let tokenStorage = MockTokenStorage()
        try await tokenStorage.saveToken("expired_token")
        
        let githubAPI = GitHubAPIClient(httpClient: mockHTTP)
        let container = PullRequestListContainer(githubAPI: githubAPI, tokenStorage: tokenStorage)
        
        // Act: Load PRs with expired token
        await container.loadPullRequests()
        
        // Assert: Should fail with .unauthorized
        guard case .failed(let error) = container.loadingState,
              case .unauthorized = error else {
            XCTFail("Expected .unauthorized error")
            return
        }
        
        // Token should be cleared
        XCTAssertNil(try await tokenStorage.loadToken())
    }
}
```

### Fixture Files (GitReviewItTests/Fixtures/)

**token-response.json**:
```json
{
  "access_token": "gho_test_token_abc123",
  "token_type": "bearer",
  "scope": "repo"
}
```

**user-response.json**:
```json
{
  "login": "octocat",
  "name": "The Octocat",
  "avatar_url": "https://avatars.githubusercontent.com/u/1?v=4"
}
```

**prs-response.json**:
```json
{
  "total_count": 1,
  "items": [
    {
      "number": 123,
      "title": "Add feature X",
      "html_url": "https://github.com/owner/repo/pull/123",
      "updated_at": "2025-12-20T10:30:00Z",
      "user": {
        "login": "author",
        "avatar_url": "https://avatars.githubusercontent.com/u/2?v=4"
      },
      "repository_url": "https://api.github.com/repos/owner/repo"
    }
  ]
}
```

---

## Running the App

1. Open `GitReviewIt.xcodeproj` in Xcode
2. Select the GitReviewIt scheme and target macOS
3. Build and run (Cmd+R)
4. Click "Sign in with GitHub" to start OAuth flow
5. Authorize the app in the browser
6. View your PRs awaiting review

---

## Running Tests

```bash
# Run all tests
xcodebuild test -project GitReviewIt.xcodeproj -scheme GitReviewIt -destination 'platform=macOS'

# Or in Xcode: Cmd+U
```

---

## Common Pitfalls & Solutions

### Problem: ASWebAuthenticationSession doesn't present

**Solution**: Ensure your app has a valid `presentationContextProvider`. The session requires a window to anchor to.

```swift
let session = ASWebAuthenticationSession(...)
session.presentationContextProvider = self  // Must conform to ASWebAuthenticationPresentationContextProviding
```

### Problem: Keychain operations fail with errSecItemNotFound

**Solution**: This is expected when no token exists. Don't treat it as an error—return `nil` from `loadToken()`.

```swift
let status = SecItemCopyMatching(query as CFDictionary, &result)
if status == errSecItemNotFound {
    return nil  // Not an error, just no token
}
```

### Problem: GitHub API returns 422 for search query

**Solution**: Ensure query parameters are properly URL-encoded. Use `URLComponents` to build the URL safely.

```swift
var components = URLComponents(string: "https://api.github.com/search/issues")!
components.queryItems = [
    URLQueryItem(name: "q", value: "type:pr state:open review-requested:\(username)"),
    URLQueryItem(name: "sort", value: "updated"),
    URLQueryItem(name: "order", value: "desc")
]
let url = components.url!
```

### Problem: SwiftUI view not updating when state changes

**Solution**: Ensure container is `@Observable` and view uses `@State`. Check that state properties are accessed in the view body.

```swift
@Observable  // ← Must be present
final class MyContainer { ... }

struct MyView: View {
    @State private var container: MyContainer  // ← Use @State
    
    var body: some View {
        Text(container.someProperty)  // ← Accessing property triggers observation
    }
}
```

---

## Next Steps After MVP

- [ ] Add pull-to-refresh gesture
- [ ] Cache avatar images
- [ ] Display PR description and labels
- [ ] Add filtering/sorting options
- [ ] Implement GitHub Device Flow for production
- [ ] Add multi-account support
- [ ] Expand to iOS and iPadOS

---

## Resources

- [GitHub OAuth Documentation](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps)
- [GitHub REST API Documentation](https://docs.github.com/en/rest)
- [SwiftUI Observation Documentation](https://developer.apple.com/documentation/observation)
- [ASWebAuthenticationSession Documentation](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession)
- [Keychain Services Documentation](https://developer.apple.com/documentation/security/keychain_services)

---

**Last Updated**: December 20, 2025  
**Maintainer**: Development Team
