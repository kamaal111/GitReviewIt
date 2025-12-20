# Research: GitHub PR Review Viewer

**Feature**: 001-github-pr-viewer  
**Date**: December 20, 2025  
**Status**: Complete

## Purpose

This document consolidates research findings for implementing a SwiftUI macOS app that authenticates with GitHub OAuth and displays pull requests awaiting the user's review. All technical unknowns from the planning phase are resolved here.

## Research Areas

### 1. GitHub OAuth for Native macOS Apps

**Decision**: Use ASWebAuthenticationSession with custom URL scheme callback

**Rationale**:
- ASWebAuthenticationSession is Apple's recommended approach for native OAuth flows on macOS
- Provides system-level security (runs in separate process, isolated from app)
- Built-in support for custom URL schemes for redirect callbacks
- Handles cookie/session management automatically
- User sees trusted system UI, not app-embedded web view
- Supported on macOS 10.15+ (well below our 15.0 target)

**Alternatives Considered**:
- ❌ WKWebView: Apple discourages this for OAuth (security concerns, user trust issues)
- ❌ SFSafariViewController: iOS-only, not available on macOS
- ❌ Opening Safari + polling: Poor UX, unreliable state management

**Implementation Details**:
- Custom URL scheme: `gitreviewit://oauth-callback`
- Must register URL scheme in Info.plist under `CFBundleURLTypes`
- State parameter: Generate UUID for each flow, validate on callback to prevent CSRF
- Callback handling: Implement via `.onOpenURL` modifier in SwiftUI or AppDelegate

**Security Considerations**:
- Client secret: For native apps, GitHub treats them as "public clients" (secret cannot be truly protected). Consider GitHub Device Flow for production, but OAuth Web Flow acceptable for MVP given GitHub's security model.
- State validation: Critical—reject any callback where state doesn't match the initiated flow
- Token storage: Must use Keychain with kSecAttrAccessibleAfterFirstUnlock or stricter

---

### 2. Secure Token Storage with Keychain

**Decision**: Use Security framework directly with structured error handling

**Rationale**:
- Security framework provides direct Keychain access without third-party dependencies
- Keychain automatically syncs across devices via iCloud Keychain (can be disabled if desired)
- Encrypted at rest, OS-managed decryption
- Per-item access control policies (kSecAttrAccessible)
- Well-understood, battle-tested API

**Alternatives Considered**:
- ❌ Third-party wrappers (KeychainAccess, SwiftKeychainWrapper): Unnecessary abstraction for MVP
- ❌ UserDefaults: Not encrypted, inappropriate for secrets
- ❌ File storage with encryption: Complex, error-prone, reinventing the wheel

**Implementation Approach**:
```swift
protocol TokenStorage {
    func saveToken(_ token: String) async throws
    func loadToken() async throws -> String?
    func deleteToken() async throws
}

enum TokenStorageError: Error {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
    case notFound
}
```

**Key Attributes**:
- `kSecClass`: kSecClassGenericPassword
- `kSecAttrService`: "com.gitreviewit.github-token" (app-specific service identifier)
- `kSecAttrAccount`: "oauth-token" (single token per user)
- `kSecAttrAccessible`: kSecAttrAccessibleAfterFirstUnlock (balance security and usability)
- `kSecAttrSynchronizable`: kCFBooleanFalse (don't sync to iCloud for security; user can re-auth on other devices)

**Operations**:
- Save: SecItemAdd with kSecValueData (token as UTF-8 Data)
- Load: SecItemCopyMatching with kSecReturnData
- Delete: SecItemDelete
- Update: Use SecItemUpdate if token changes (though OAuth tokens typically replaced, not updated)

---

### 3. GitHub API for Pull Request Review Requests

**Decision**: Use Search API with query `type:pr state:open review-requested:<username>`

**Rationale**:
- GitHub Search API is purpose-built for querying across repositories
- Single endpoint returns all PRs matching criteria (no pagination across repos)
- Supports sorting by last updated (most recent activity first)
- No need for GraphQL complexity for MVP

**Alternatives Considered**:
- ❌ REST API per-repo queries: Requires knowing all repos user has access to, then querying each (hundreds of requests)
- ❌ GraphQL API: More powerful but overkill for MVP; adds complexity in query construction
- ❌ Notifications API: Returns all notifications (not just review requests), requires filtering

**API Endpoint**:
```
GET https://api.github.com/search/issues
```

**Query Parameters**:
- `q`: `type:pr state:open review-requested:<username>`
- `sort`: `updated`
- `order`: `desc`
- `per_page`: `50` (GitHub max is 100, 50 is reasonable default)

**Request Headers**:
- `Authorization`: `Bearer <token>`
- `Accept`: `application/vnd.github+json`
- `X-GitHub-Api-Version`: `2022-11-28` (current stable version)

**Response Structure**:
```json
{
  "total_count": 5,
  "incomplete_results": false,
  "items": [
    {
      "number": 123,
      "title": "Add feature X",
      "html_url": "https://github.com/owner/repo/pull/123",
      "updated_at": "2025-12-20T10:30:00Z",
      "user": {
        "login": "author-username",
        "avatar_url": "https://avatars.githubusercontent.com/u/123?v=4"
      },
      "repository_url": "https://api.github.com/repos/owner/repo"
    }
  ]
}
```

**Parsing Notes**:
- `repository_url` must be parsed to extract owner/repo (last two path components)
- `updated_at` is ISO8601, use ISO8601DateFormatter or Codable's built-in Date decoding with `.iso8601` strategy
- Fields may be null in edge cases; use optionals and handle gracefully

**Error Handling**:
- 401: Token invalid/expired → force logout
- 403: Rate limit exceeded (check `X-RateLimit-*` headers for reset time)
- 422: Invalid query (shouldn't happen with static query, but handle gracefully)
- 5xx: GitHub service issues → retry with exponential backoff

---

### 4. Best Practices for SwiftUI + Observation

**Decision**: Use `@Observable` macro for state containers, `@State` in views

**Rationale**:
- `@Observable` is the modern Swift way (introduced iOS 17/macOS 14)
- Reduces boilerplate compared to `ObservableObject` + `@Published`
- Fine-grained observation (only re-renders when accessed properties change)
- Reference semantics (class-based) appropriate for state containers with complex lifecycle
- `@State` in views ensures SwiftUI manages container lifecycle and preserves across view updates

**Alternatives Considered**:
- ❌ `ObservableObject` + `@Published`: Legacy approach, more verbose
- ❌ `@StateObject` / `@ObservedObject`: Deprecated in favor of Observation
- ❌ `@EnvironmentObject`: Global state anti-pattern, harder to test

**Container Pattern**:
```swift
@Observable
@MainActor
final class PullRequestListContainer {
    private(set) var pullRequests: [PullRequest] = []
    private(set) var isLoading = false
    private(set) var error: APIError?
    
    private let apiClient: GitHubAPI
    
    init(apiClient: GitHubAPI) {
        self.apiClient = apiClient
    }
    
    func loadPullRequests() async {
        isLoading = true
        error = nil
        do {
            pullRequests = try await apiClient.fetchReviewRequests()
            isLoading = false
        } catch let apiError as APIError {
            error = apiError
            isLoading = false
        }
    }
    
    func retry() async {
        await loadPullRequests()
    }
}
```

**View Usage**:
```swift
struct PullRequestListView: View {
    @State private var container: PullRequestListContainer
    
    init(apiClient: GitHubAPI) {
        _container = State(initialValue: PullRequestListContainer(apiClient: apiClient))
    }
    
    var body: some View {
        // View reads container state and calls intent methods
    }
}
```

**Benefits**:
- Container owns all state, view is declarative
- Protocol injection via initializer enables testing with mocks
- `@MainActor` ensures UI updates happen on main thread
- Private(set) prevents external mutation, maintains encapsulation

---

### 5. URLSession for HTTP Networking

**Decision**: Use URLSession directly with `async/await` APIs

**Rationale**:
- URLSession provides native async/await support as of Swift 5.5
- No need for third-party networking libraries (Alamofire, etc.)
- Supports request/response handling, error propagation, cancellation
- Built-in caching, authentication challenges, background sessions (not needed for MVP)
- Protocol abstraction over URLSession enables testing without hitting real network

**Alternatives Considered**:
- ❌ Alamofire/Moya: Unnecessary dependencies, adds compile time and app size
- ❌ Combine's `URLSession.dataTaskPublisher`: Swift Concurrency is preferred
- ❌ Callback-based URLSession: Legacy API, harder to manage cancellation

**Protocol Design**:
```swift
protocol HTTPClient {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

actor URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPError.invalidResponse
        }
        return (data, httpResponse)
    }
}
```

**Error Handling**:
- Network errors: Map URLError codes to custom APIError cases
- HTTP status codes: Check statusCode on HTTPURLResponse
- Decoding errors: Catch DecodingError and wrap in APIError.invalidResponse

**Testing Strategy**:
- Production: Inject URLSessionHTTPClient
- Tests: Inject MockHTTPClient that returns fixture data without network calls

---

### 6. Testing Strategy: Integration-Style with Mocked Network

**Decision**: Mock only the HTTPClient protocol boundary; test full flows end-to-end

**Rationale**:
- Integration tests catch more bugs than isolated unit tests
- Mocking HTTP transport is sufficient—validates business logic + error handling
- Avoids brittle tests that mock every internal layer
- Fixtures ensure deterministic, repeatable tests
- Fast (no real network), isolated (no external dependencies)

**Alternatives Considered**:
- ❌ Granular unit tests of every class: Brittle, high maintenance, misses integration bugs
- ❌ UI tests: Slow, flaky, appropriate for smoke tests only
- ❌ Real API calls in tests: Unreliable, slow, requires network, can hit rate limits

**Test Structure**:
```swift
final class AuthenticationFlowTests: XCTestCase {
    func testSuccessfulLogin() async throws {
        let mockHTTP = MockHTTPClient()
        mockHTTP.stubResponse(for: "/user", fixture: "user-response.json")
        
        let tokenStorage = MockTokenStorage()
        let apiClient = GitHubAPIClient(httpClient: mockHTTP)
        let container = AuthenticationContainer(apiClient: apiClient, tokenStorage: tokenStorage)
        
        await container.completeOAuth(code: "test-code")
        
        XCTAssertEqual(container.authState, .authenticated)
        XCTAssertNotNil(try await tokenStorage.loadToken())
    }
}
```

**Fixture Management**:
- Store JSON responses in `GitReviewItTests/Fixtures/`
- Name files descriptively: `user-response.json`, `prs-empty-response.json`, `error-401.json`
- Use Bundle.module.url(forResource:withExtension:) to load

**Coverage Goals**:
- ✅ First launch (no token) → login screen
- ✅ OAuth success → token saved → PR list
- ✅ OAuth failure → error displayed
- ✅ Token present at launch → PR list
- ✅ PR list load success → display PRs
- ✅ PR list empty → empty state
- ✅ 401 response → logout, return to login
- ✅ Network error → error message + retry
- ✅ Rate limit → error with reset time
- ✅ Logout → token cleared → login screen

---

### 7. State-Driven Navigation in SwiftUI

**Decision**: Use enum-based navigation state with NavigationStack

**Rationale**:
- Single source of truth for navigation state
- Testable (state changes are pure logic)
- SwiftUI NavigationStack (macOS 13+) supports programmatic navigation
- Enum captures all possible screens/states exhaustively

**Alternatives Considered**:
- ❌ NavigationLink with implicit state: Hard to test, unclear control flow
- ❌ Global router singleton: Violates dependency injection principles
- ❌ Coordinator pattern: Overkill for simple linear navigation

**Navigation State**:
```swift
enum AppRoute: Hashable {
    case login
    case pullRequestList
}

@Observable
@MainActor
final class AppContainer {
    private(set) var navigationPath: [AppRoute] = []
    private(set) var currentRoute: AppRoute = .login
    
    private let tokenStorage: TokenStorage
    
    init(tokenStorage: TokenStorage) {
        self.tokenStorage = tokenStorage
    }
    
    func checkAuthentication() async {
        if let _ = try? await tokenStorage.loadToken() {
            currentRoute = .pullRequestList
        } else {
            currentRoute = .login
        }
    }
    
    func didAuthenticate() {
        currentRoute = .pullRequestList
    }
    
    func logout() async {
        try? await tokenStorage.deleteToken()
        currentRoute = .login
    }
}
```

**View Structure**:
```swift
struct ContentView: View {
    @State private var appContainer: AppContainer
    
    var body: some View {
        Group {
            switch appContainer.currentRoute {
            case .login:
                LoginView(onAuthenticated: appContainer.didAuthenticate)
            case .pullRequestList:
                PullRequestListView(onLogout: { await appContainer.logout() })
            }
        }
        .task {
            await appContainer.checkAuthentication()
        }
    }
}
```

**Benefits**:
- No NavigationStack needed for simple case (just conditional view switching)
- State machine is explicit: can only be in login or pullRequestList
- Easy to test state transitions independently of UI

---

### 8. OAuth Client Secret Management

**Decision**: Accept client secret embedded in app for MVP; document migration path to Device Flow

**Rationale**:
- GitHub treats native apps as "public clients"—secrets can be extracted via reverse engineering
- GitHub Device Flow is the recommended approach for production but adds complexity
- For MVP, OAuth Web Flow with embedded secret is acceptable and common practice
- Secret exposure risk is low (scoped to app's OAuth client, can be rotated)

**Alternatives Considered**:
- ✅ GitHub Device Flow: Better security (no secret), but requires multi-step UX (user enters code)
- ❌ Backend proxy for token exchange: Requires server, defeats "no backend" constraint
- ❌ Public OAuth app with no secret: Not supported by GitHub

**Implementation for MVP**:
- Store client_id and client_secret as constants in a `GitHubOAuthConfig.swift` file
- Mark constants as `private` to discourage misuse
- Add `.gitignore` entry for config file OR use `.xcconfig` file for build-time injection
- Document in README: "Production apps should use GitHub Device Flow"

**Migration Path**:
When upgrading to production:
1. Implement Device Flow (user sees 8-char code, enters on github.com/device)
2. Poll `https://github.com/login/oauth/access_token` for token
3. Update LoginView to show code input UI
4. Remove embedded client secret

---

## Summary

All technical unknowns are resolved:

1. ✅ **OAuth**: ASWebAuthenticationSession with custom URL scheme
2. ✅ **Token Storage**: Security framework Keychain API with kSecAttrAccessibleAfterFirstUnlock
3. ✅ **PR Fetching**: GitHub Search API with `review-requested:<username>` query
4. ✅ **State Management**: @Observable containers owned by @State in views
5. ✅ **Networking**: URLSession with async/await, protocol abstraction for testing
6. ✅ **Testing**: Integration-style with mocked HTTP layer and JSON fixtures
7. ✅ **Navigation**: Enum-based route state with conditional view switching
8. ✅ **Secret Management**: Embedded secret acceptable for MVP; Device Flow for production

No blocking issues identified. Ready to proceed to Phase 1 (data model and contracts).
