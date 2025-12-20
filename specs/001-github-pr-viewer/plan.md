# Implementation Plan: GitHub PR Review Viewer

**Branch**: `001-github-pr-viewer` | **Date**: December 20, 2025 | **Spec**: [spec.md](./spec.md)

## Summary

**Primary Requirement**: Build a macOS SwiftUI app that authenticates with GitHub OAuth and displays pull requests awaiting the user's review.

**Technical Approach**: 
- SwiftUI with Observation framework for state management
- ASWebAuthenticationSession for native OAuth flow (no embedded web views)
- Protocol-oriented architecture with dependency injection for testability
- URLSession for networking; Keychain for secure token storage
- Integration-style testing with mocked HTTP transport layer using JSON fixtures
- Unidirectional data flow: Views → Intent → State Container → View Update
- 12 incremental PRs, each delivering testable, working functionality
- Zero third-party dependencies (stdlib + Foundation + Security framework only)

## Technical Context

**Language/Version**: Swift 6.0 (latest stable)  
**UI Framework**: SwiftUI with Observation framework (`@Observable`, `@State`)  
**Primary Dependencies**: None (stdlib + Foundation + Security framework for Keychain)  
**Storage**: Keychain for secure token storage only; no database needed for MVP  
**Testing**: XCTest with integration-style tests; mock only network transport layer using fixtures  
**Target Platform**: macOS 15.0+ (single-platform MVP)  
**Architecture**: Unidirectional data flow with view-owned state containers via `@State`  
**Deployment Target**: macOS 15.0  
**Performance Goals**: PR list loads in <3 seconds; smooth scrolling for 100+ items; OAuth completes in <30 seconds  
**Constraints**: No backend; minimal dependencies; protocol-based boundaries; SwiftUI-only UI  
**Scale/Scope**: 3 main screens (Login, PR List, Error states); ~10-15 source files; support 100+ PRs in list

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**I. Unidirectional Data Flow**
- [x] Views are declarative and lightweight (no business logic)
- [x] State is owned by explicit state containers
- [x] State flows one direction: Intent → Container → View Update

**II. Protocol-Oriented Design**
- [x] Cross-layer dependencies defined by protocols
- [x] Services/repositories use protocol abstractions
- [x] Test doubles are easily created via protocol conformance

**III. Separation of Concerns**
- [x] Clear boundaries: UI / State / Domain / Infrastructure
- [x] Domain models don't import SwiftUI/UIKit unnecessarily
- [x] UI code doesn't perform I/O or side effects

**IV. Testability First**
- [x] Core logic testable without SwiftUI
- [x] No hard dependencies on singletons
- [x] Side effects are injectable via protocols

**V. SwiftUI & Observation Standards**
- [x] Views under 200 lines (target <150)
- [x] State containers use `@Observable`
- [x] Views use `@State` to own containers
- [x] Navigation is state-driven and explicit

**VI. State Management**
- [x] State containers expose intent-based methods
- [x] No public mutable properties without justification
- [x] Views send intent, not imperative mutations

**VII. Concurrency & Async**
- [x] Swift Concurrency (`async/await`) used exclusively
- [x] No new Combine usage (or justified)
- [x] UI-facing state updates on main actor
- [x] Task cancellation strategies defined

**VIII. Dependency Management**
- [x] Minimize third-party dependencies
- [x] Each dependency has documented justification
- [x] Third-party types isolated by wrapper protocols

**IX. Code Style & Immutability**
- [x] Prefer `let` and `struct` by default
- [x] Descriptive naming over brevity
- [x] Magic numbers/strings extracted as constants
- [x] Intentional access control (`private` by default)

**X. Error Handling**
- [x] Typed errors (enums conforming to Error)
- [x] No force-try or force-unwrap in production
- [x] Errors surfaced as explicit state
- [x] User-facing error messages are actionable

✅ **All constitutional principles satisfied. No violations to justify.**

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
GitReviewIt/
├── GitReviewItApp.swift              # App entry point
├── ContentView.swift                 # Root view with navigation logic
├── Features/
│   ├── Authentication/
│   │   ├── Views/
│   │   │   └── LoginView.swift
│   │   ├── State/
│   │   │   └── AuthenticationContainer.swift
│   │   └── Models/
│   │       ├── GitHubToken.swift
│   │       └── AuthenticatedUser.swift
│   └── PullRequests/
│       ├── Views/
│       │   ├── PullRequestListView.swift
│       │   └── PullRequestRow.swift
│       ├── State/
│       │   └── PullRequestListContainer.swift
│       └── Models/
│           └── PullRequest.swift
├── Shared/
│   ├── Views/
│   │   ├── LoadingView.swift
│   │   └── ErrorView.swift
│   └── Models/
│       └── APIError.swift
└── Infrastructure/
    ├── Networking/
    │   ├── HTTPClient.swift           # Protocol + URLSession impl
    │   └── GitHubAPI.swift            # Protocol + concrete API client
    ├── Storage/
    │   └── TokenStorage.swift         # Protocol + Keychain impl
    └── OAuth/
        └── OAuthManager.swift         # Protocol + ASWebAuthenticationSession impl

GitReviewItTests/
├── IntegrationTests/
│   ├── AuthenticationFlowTests.swift
│   ├── PullRequestListTests.swift
│   └── ErrorHandlingTests.swift
├── TestDoubles/
│   ├── MockHTTPClient.swift
│   ├── MockTokenStorage.swift
│   └── MockOAuthManager.swift
└── Fixtures/
    ├── user-response.json
    ├── prs-response.json
    └── error-responses.json
```

**Structure Decision**: Feature-oriented organization for GitReviewIt. Each feature (Authentication, PullRequests) has its own Views/State/Models subfolder. Infrastructure layer contains protocol-based abstractions for networking, storage, and OAuth to enable testability. Shared contains cross-feature UI components and domain models. This structure supports the app's unidirectional data flow and makes feature boundaries explicit.

## Complexity Tracking

No constitutional violations. All architectural choices align with the GitReviewIt constitution.

---

## Implementation Plan: PR-Sized Steps

This section breaks the MVP into small, testable, incremental PRs. Each PR delivers working, tested functionality.

---

### **PR #1: Project Setup & Infrastructure Protocols**

**Goal**: Establish Xcode project structure, define all infrastructure protocol boundaries, and add Info.plist configuration for OAuth callback.

**User-Visible Outcome**: No UI changes yet; foundation for testability is in place.

**Files to Create**:
- `GitReviewIt/Infrastructure/Networking/HTTPClient.swift` (protocol + URLSessionHTTPClient)
- `GitReviewIt/Infrastructure/Storage/TokenStorage.swift` (protocol only)
- `GitReviewIt/Infrastructure/OAuth/OAuthManager.swift` (protocol only)
- `GitReviewIt/Infrastructure/Networking/GitHubAPI.swift` (protocol only)
- `GitReviewIt/Shared/Models/APIError.swift`
- `GitReviewIt/Shared/Models/LoadingState.swift`
- `GitReviewItTests/TestDoubles/MockHTTPClient.swift`
- `GitReviewItTests/Fixtures/` (directory for JSON fixtures)

**Files to Modify**:
- `Info.plist`: Add `CFBundleURLTypes` with `gitreviewit://` custom URL scheme

**Public Interfaces**:
```swift
protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

protocol TokenStorage: Sendable {
    func saveToken(_ token: String) async throws
    func loadToken() async throws -> String?
    func deleteToken() async throws
}

protocol OAuthManager: Sendable {
    func authenticate(authorizationURL: URL, callbackURLScheme: String) async throws -> String
}

protocol GitHubAPI: Sendable {
    func exchangeCodeForToken(code: String, clientId: String, clientSecret: String) async throws -> GitHubToken
    func fetchUser(token: String) async throws -> AuthenticatedUser
    func fetchReviewRequests(token: String) async throws -> [PullRequest]
}

enum APIError: Error, LocalizedError { ... }
enum LoadingState<T: Equatable>: Equatable { ... }
```

**Tests**:
- `HTTPClientTests`: Test URLSessionHTTPClient with real URLSession (local endpoint or fixture server)
- Verify MockHTTPClient can load fixture files

**Acceptance Criteria**:
- [ ] All protocol signatures compile without errors
- [ ] URLSessionHTTPClient wraps URLSession.data(for:) with async/await
- [ ] MockHTTPClient loads JSON fixture from bundle
- [ ] APIError has user-friendly error descriptions
- [ ] Info.plist correctly registers `gitreviewit://` scheme
- [ ] Tests pass

---

### **PR #2: Domain Models & Keychain Token Storage**

**Goal**: Implement all domain models (GitHubToken, AuthenticatedUser, PullRequest) and Keychain-based token storage.

**User-Visible Outcome**: No UI changes; token can be saved/loaded from Keychain.

**Files to Create**:
- `GitReviewIt/Features/Authentication/Models/GitHubToken.swift`
- `GitReviewIt/Features/Authentication/Models/AuthenticatedUser.swift`
- `GitReviewIt/Features/PullRequests/Models/PullRequest.swift`
- `GitReviewIt/Infrastructure/Storage/KeychainTokenStorage.swift`
- `GitReviewItTests/TestDoubles/MockTokenStorage.swift`

**Public Interfaces**:
```swift
struct GitHubToken: Codable, Equatable {
    let value: String
    let createdAt: Date
    let scopes: Set<String>
}

struct AuthenticatedUser: Codable, Equatable {
    let login: String
    let name: String?
    let avatarURL: URL?
}

struct PullRequest: Identifiable, Codable, Equatable {
    let id: String
    let repositoryOwner: String
    let repositoryName: String
    let number: Int
    let title: String
    let authorLogin: String
    let authorAvatarURL: URL?
    let updatedAt: Date
    let htmlURL: URL
    var repositoryFullName: String { "\(repositoryOwner)/\(repositoryName)" }
}

final class KeychainTokenStorage: TokenStorage { ... }
final class MockTokenStorage: TokenStorage { ... }
```

**Main Logic**:
- KeychainTokenStorage uses Security framework (SecItemAdd, SecItemCopyMatching, SecItemDelete)
- Attributes: kSecClassGenericPassword, kSecAttrService = "com.gitreviewit.github-token", kSecAttrAccessible = kSecAttrAccessibleAfterFirstUnlock

**Tests**:
- `KeychainTokenStorageTests`:
  - testSaveAndLoadToken: Save token, reload, verify match
  - testLoadWhenNoToken: Verify returns nil (not error)
  - testDeleteToken: Save, delete, verify nil on reload
  - testSaveOverwritesExisting: Save twice with different tokens, verify latest
- `DomainModelsTests`:
  - testGitHubTokenDecoding: Decode from JSON fixture
  - testPullRequestComputedProperties: Verify repositoryFullName

**Network Fixtures Needed**: None yet

**Acceptance Criteria**:
- [ ] GitHubToken, AuthenticatedUser, PullRequest have precondition validations
- [ ] KeychainTokenStorage saves/loads/deletes tokens from Keychain
- [ ] MockTokenStorage works entirely in-memory
- [ ] All domain model tests pass
- [ ] Keychain tests pass (can run on simulator or Mac)

---

### **PR #3: GitHub API Client Implementation**

**Goal**: Implement GitHubAPIClient with methods for token exchange, user fetch, and PR search.

**User-Visible Outcome**: No UI changes; API client can communicate with GitHub.

**Files to Create**:
- `GitReviewIt/Infrastructure/Networking/GitHubAPIClient.swift`
- `GitReviewIt/Infrastructure/OAuth/GitHubOAuthConfig.swift` (client ID/secret constants)
- `GitReviewItTests/TestDoubles/MockGitHubAPI.swift`
- `GitReviewItTests/Fixtures/token-response.json`
- `GitReviewItTests/Fixtures/user-response.json`
- `GitReviewItTests/Fixtures/prs-response.json`
- `GitReviewItTests/Fixtures/error-401.json`
- `GitReviewItTests/Fixtures/error-403-rate-limit.json`

**Public Interface**:
```swift
actor GitHubAPIClient: GitHubAPI {
    private let httpClient: HTTPClient
    
    init(httpClient: HTTPClient)
    
    func exchangeCodeForToken(...) async throws -> GitHubToken
    func fetchUser(token: String) async throws -> AuthenticatedUser
    func fetchReviewRequests(token: String) async throws -> [PullRequest]
}
```

**Main Logic**:
- exchangeCodeForToken: POST to `https://github.com/login/oauth/access_token`, parse JSON response
- fetchUser: GET `https://api.github.com/user` with Bearer token, decode AuthenticatedUser
- fetchReviewRequests: GET `https://api.github.com/search/issues?q=type:pr+state:open+review-requested:<username>`, parse items, extract owner/repo from repository_url
- Error mapping: 401 → .unauthorized, 403 + rate limit headers → .rateLimited, 5xx → .serverError

**Tests**:
- `GitHubAPIClientTests`:
  - testExchangeCodeForTokenSuccess: Mock 200 with token-response.json, verify GitHubToken returned
  - testExchangeCodeForTokenFailure: Mock 401, verify throws .unauthorized
  - testFetchUserSuccess: Mock 200 with user-response.json, verify AuthenticatedUser
  - testFetchUserUnauthorized: Mock 401, verify throws .unauthorized
  - testFetchReviewRequestsSuccess: Mock 200 with prs-response.json, verify [PullRequest]
  - testFetchReviewRequestsEmpty: Mock 200 with empty items, verify empty array
  - testFetchReviewRequestsRateLimited: Mock 403 with X-RateLimit headers, verify .rateLimited with Date

**Network Fixtures Needed**:
- token-response.json, user-response.json, prs-response.json (success cases)
- error-401.json, error-403-rate-limit.json (error cases)

**Acceptance Criteria**:
- [ ] All GitHub API methods implemented and tested
- [ ] Error mapping correctly handles 401, 403, 5xx
- [ ] Rate limit reset time parsed from X-RateLimit-Reset header
- [ ] PullRequest parsing extracts owner/repo from repository_url
- [ ] All tests pass with mocked HTTPClient

---

### **PR #4: OAuth Manager & ASWebAuthenticationSession**

**Goal**: Implement OAuthManager using ASWebAuthenticationSession for native OAuth flow.

**User-Visible Outcome**: OAuth web view can be presented (not yet integrated into app flow).

**Files to Create**:
- `GitReviewIt/Infrastructure/OAuth/ASWebAuthenticationSessionOAuthManager.swift`
- `GitReviewItTests/TestDoubles/MockOAuthManager.swift`

**Public Interface**:
```swift
@MainActor
final class ASWebAuthenticationSessionOAuthManager: OAuthManager {
    func authenticate(authorizationURL: URL, callbackURLScheme: String) async throws -> String
}
```

**Main Logic**:
- Create ASWebAuthenticationSession with authorization URL and callback scheme
- Set presentationContextProvider (requires conforming to ASWebAuthenticationPresentationContextProviding)
- Start session and await callback URL
- Parse callback URL query parameters: extract `code` and `state`
- Validate state parameter matches (require caller to pass expected state)
- Throw OAuthError.userCancelled if user cancels, OAuthError.invalidCallback if code missing

**Tests**:
- `OAuthManagerTests`:
  - testAuthenticateSuccess: Mock session callback with valid URL, verify code returned
  - testAuthenticateUserCancelled: Simulate cancellation, verify OAuthError.userCancelled
  - testAuthenticateInvalidCallback: Mock callback without code parameter, verify OAuthError.invalidCallback

**Note**: Testing ASWebAuthenticationSession is challenging; consider creating a testable wrapper or testing integration manually. For unit tests, MockOAuthManager returns predetermined code.

**Acceptance Criteria**:
- [ ] ASWebAuthenticationSession presents and handles callback
- [ ] Code is extracted from callback URL correctly
- [ ] User cancellation is handled gracefully
- [ ] MockOAuthManager allows tests to simulate success/failure
- [ ] Manual test: Tapping a button triggers OAuth flow (UI not required, just logging)

---

### **PR #5: Authentication State Container**

**Goal**: Implement AuthenticationContainer to orchestrate OAuth flow, token exchange, and user fetch.

**User-Visible Outcome**: No UI changes; authentication logic is testable.

**Files to Create**:
- `GitReviewIt/Features/Authentication/State/AuthenticationContainer.swift`
- `GitReviewItTests/IntegrationTests/AuthenticationFlowTests.swift`

**Public Interface**:
```swift
@Observable
@MainActor
final class AuthenticationContainer {
    enum State: Equatable {
        case unauthenticated
        case authenticating
        case authenticated
    }
    
    private(set) var state: State = .unauthenticated
    private(set) var user: AuthenticatedUser?
    private(set) var error: APIError?
    
    private let oauthManager: OAuthManager
    private let githubAPI: GitHubAPI
    private let tokenStorage: TokenStorage
    
    init(oauthManager: OAuthManager, githubAPI: GitHubAPI, tokenStorage: TokenStorage)
    
    func checkExistingToken() async
    func startOAuth() async
    func logout() async
}
```

**Main Logic**:
- checkExistingToken: Load token from storage, fetch user, set state to .authenticated if valid
- startOAuth: Generate state UUID, build authorization URL, call oauthManager.authenticate, exchange code for token, save token, fetch user, set state to .authenticated
- logout: Delete token from storage, set state to .unauthenticated

**Tests**:
- `AuthenticationFlowTests`:
  - testCheckExistingTokenSuccess: Pre-save token, call checkExistingToken, verify .authenticated
  - testCheckExistingTokenNone: No token saved, verify .unauthenticated
  - testCheckExistingToken401: Pre-save token, mock 401 on /user, verify .unauthenticated and token deleted
  - testStartOAuthSuccess: Mock OAuth code, mock token exchange + user fetch, verify .authenticated and token saved
  - testStartOAuthUserCancelled: Mock OAuthError.userCancelled, verify .unauthenticated
  - testLogout: Authenticate, logout, verify token deleted and .unauthenticated

**Network Fixtures Needed**: Reuse token-response.json, user-response.json, error-401.json

**Acceptance Criteria**:
- [ ] checkExistingToken handles valid/missing/expired tokens correctly
- [ ] startOAuth orchestrates full flow: OAuth → token exchange → user fetch → storage
- [ ] logout clears token and resets state
- [ ] All integration tests pass
- [ ] State transitions are correct: unauthenticated → authenticating → authenticated

---

### **PR #6: Pull Request List State Container**

**Goal**: Implement PullRequestListContainer to fetch and display PRs awaiting review.

**User-Visible Outcome**: No UI changes; PR loading logic is testable.

**Files to Create**:
- `GitReviewIt/Features/PullRequests/State/PullRequestListContainer.swift`
- `GitReviewItTests/IntegrationTests/PullRequestListTests.swift`

**Public Interface**:
```swift
@Observable
@MainActor
final class PullRequestListContainer {
    private(set) var loadingState: LoadingState<[PullRequest]> = .idle
    
    private let githubAPI: GitHubAPI
    private let tokenStorage: TokenStorage
    
    init(githubAPI: GitHubAPI, tokenStorage: TokenStorage)
    
    func loadPullRequests() async
    func retry() async
    func openPR(url: URL)
}
```

**Main Logic**:
- loadPullRequests: Set state to .loading, load token from storage, call githubAPI.fetchReviewRequests, set state to .loaded or .failed
- retry: Call loadPullRequests again
- openPR: Use NSWorkspace.shared.open(url) to open in Safari

**Tests**:
- `PullRequestListTests`:
  - testLoadPullRequestsSuccess: Mock prs-response.json, verify .loaded with PRs
  - testLoadPullRequestsEmpty: Mock empty response, verify .loaded with empty array
  - testLoadPullRequestsUnauthorized: Mock 401, verify .failed(.unauthorized)
  - testLoadPullRequestsRateLimited: Mock 403 with rate limit, verify .failed(.rateLimited)
  - testLoadPullRequestsNetworkError: Mock URLError, verify .failed(.networkUnavailable)
  - testRetry: Fail once, retry succeeds, verify .loaded

**Network Fixtures Needed**: prs-response.json, prs-empty-response.json, error-401.json, error-403-rate-limit.json

**Acceptance Criteria**:
- [ ] loadPullRequests fetches token and PRs correctly
- [ ] All error cases handled: 401, 403, network errors
- [ ] retry allows user to retry failed requests
- [ ] openPR opens URL in Safari
- [ ] All integration tests pass
- [ ] LoadingState transitions correctly: idle → loading → loaded/failed

---

### **PR #7: Shared UI Components (Loading & Error Views)**

**Goal**: Create reusable LoadingView and ErrorView components.

**User-Visible Outcome**: UI components exist but not yet integrated into screens.

**Files to Create**:
- `GitReviewIt/Shared/Views/LoadingView.swift`
- `GitReviewIt/Shared/Views/ErrorView.swift`

**Public Interfaces**:
```swift
struct LoadingView: View {
    let message: String
    init(message: String = "Loading...")
    var body: some View { ... }
}

struct ErrorView: View {
    let error: APIError
    let retry: () async -> Void
    var body: some View { ... }
}
```

**Main Logic**:
- LoadingView: Display ProgressView (spinner) with optional message
- ErrorView: Display error icon, error.localizedDescription, and "Try Again" button that calls retry closure

**Tests**: Manual SwiftUI preview testing (no automated tests for simple Views)

**Acceptance Criteria**:
- [ ] LoadingView displays spinner and message
- [ ] ErrorView displays error description and retry button
- [ ] ErrorView calls retry closure when button tapped
- [ ] Views look polished (appropriate spacing, colors, SF Symbols)

---

### **PR #8: Login View & Initial Navigation**

**Goal**: Create LoginView and wire up ContentView to show login screen when unauthenticated.

**User-Visible Outcome**: App launches and shows a "Sign in with GitHub" button.

**Files to Create**:
- `GitReviewIt/Features/Authentication/Views/LoginView.swift`

**Files to Modify**:
- `GitReviewIt/ContentView.swift`: Add navigation logic based on auth state
- `GitReviewIt/GitReviewItApp.swift`: Inject dependencies into ContentView

**Public Interface**:
```swift
struct LoginView: View {
    @State private var container: AuthenticationContainer
    let onAuthenticated: () -> Void
    
    init(
        oauthManager: OAuthManager,
        githubAPI: GitHubAPI,
        tokenStorage: TokenStorage,
        onAuthenticated: @escaping () -> Void
    )
    
    var body: some View { ... }
}
```

**Main Logic**:
- LoginView displays app logo/title, "Sign in with GitHub" button
- Button taps call `await container.startOAuth()`
- When state becomes .authenticated, call onAuthenticated() to trigger navigation
- Display error message if authentication fails

**Tests**: Manual testing (visual verification)

**Acceptance Criteria**:
- [ ] LoginView displays "Sign in with GitHub" button
- [ ] Tapping button starts OAuth flow (opens ASWebAuthenticationSession)
- [ ] On success, onAuthenticated callback is invoked
- [ ] ContentView switches to login screen when unauthenticated
- [ ] App checks for existing token at launch via .task modifier

---

### **PR #9: Pull Request List View**

**Goal**: Create PullRequestListView and PullRequestRow to display PRs.

**User-Visible Outcome**: After login, user sees list of PRs awaiting review (or empty state).

**Files to Create**:
- `GitReviewIt/Features/PullRequests/Views/PullRequestListView.swift`
- `GitReviewIt/Features/PullRequests/Views/PullRequestRow.swift`

**Files to Modify**:
- `GitReviewIt/ContentView.swift`: Navigate to PullRequestListView when authenticated

**Public Interfaces**:
```swift
struct PullRequestListView: View {
    @State private var container: PullRequestListContainer
    let onLogout: () async -> Void
    
    init(
        githubAPI: GitHubAPI,
        tokenStorage: TokenStorage,
        onLogout: @escaping () async -> Void
    )
    
    var body: some View { ... }
}

struct PullRequestRow: View {
    let pr: PullRequest
    var body: some View { ... }
}
```

**Main Logic**:
- PullRequestListView: Use switch statement on loadingState to render LoadingView, ErrorView, empty state, or List
- Call loadPullRequests in .task modifier
- List displays PullRequestRow for each PR
- PullRequestRow: Display repo name, PR title, author, relative time (e.g., "2 hours ago")
- Tap on row calls container.openPR(pr.htmlURL)
- Toolbar with logout button calls onLogout

**Tests**: Manual testing (visual verification, tap rows to open Safari)

**Acceptance Criteria**:
- [ ] PullRequestListView displays loading spinner while fetching
- [ ] List displays all PRs with correct formatting
- [ ] Empty state shows "No PRs awaiting your review" message
- [ ] Error state shows error message and retry button
- [ ] Tapping row opens PR in Safari
- [ ] Logout button returns to login screen and clears token

---

### **PR #10: Error Handling & Edge Cases**

**Goal**: Ensure all error scenarios are handled gracefully with user-friendly messages.

**User-Visible Outcome**: App never crashes; errors display appropriate messages and recovery options.

**Files to Modify**:
- All containers: Ensure all async calls wrapped in do-catch
- ErrorView: Ensure all APIError cases display correct messages

**Tests**:
- `ErrorHandlingTests`:
  - testNetworkUnavailable: Simulate URLError.notConnectedToInternet, verify .networkUnavailable error shown
  - testRateLimitHandling: Simulate 403 rate limit, verify reset time displayed
  - testInvalidTokenAutoLogout: Simulate 401 during PR fetch, verify logout and return to login
  - testRetryAfterTransientError: Simulate 500 error, retry succeeds, verify PRs load

**Network Fixtures Needed**: error-500.json, error-network-unavailable (simulated via mock)

**Acceptance Criteria**:
- [ ] All error types (networkUnavailable, unauthorized, rateLimited, serverError, invalidResponse) display correct messages
- [ ] 401 during PR fetch automatically logs out user
- [ ] Rate limit error displays reset time in human-readable format
- [ ] Retry button works for all transient errors
- [ ] No force-unwrap or force-try in production code
- [ ] All error handling tests pass

---

### **PR #11: Relative Time Formatting & Polish**

**Goal**: Format "updated at" timestamps as relative time (e.g., "2 hours ago"), improve UI polish.

**User-Visible Outcome**: PR list shows human-readable update times; UI feels polished.

**Files to Create**:
- `GitReviewIt/Shared/Extensions/Date+RelativeFormatting.swift`

**Files to Modify**:
- `PullRequestRow`: Use relative time formatter for `updatedAt`
- All views: Adjust spacing, fonts, colors for visual consistency

**Main Logic**:
- Use RelativeDateTimeFormatter to format dates as "2 hours ago", "3 days ago"
- Extract as Date extension or helper

**Tests**: Manual visual testing

**Acceptance Criteria**:
- [ ] PR timestamps display as relative time
- [ ] UI uses SF Symbols for icons where appropriate
- [ ] Views have consistent spacing and alignment
- [ ] App icon placeholder replaced with custom icon (optional for MVP)

---

### **PR #12: Final Testing & Documentation**

**Goal**: Run full integration tests, add README, document setup process.

**User-Visible Outcome**: App is fully functional and documented.

**Files to Create**:
- `README.md`: Project overview, setup instructions, OAuth app setup
- `TESTING.md`: How to run tests, what's covered

**Files to Modify**:
- Fix any bugs discovered during manual testing
- Add inline code documentation where needed

**Tests**: Run all tests, perform manual end-to-end testing:
- [ ] Fresh install: Login flow works
- [ ] Return user: Token persists, skips login
- [ ] Logout: Token cleared, login screen returns
- [ ] 401 handling: Auto-logout on expired token
- [ ] Network error: Retry works
- [ ] Empty state: Shows message when no PRs
- [ ] Open PR: Safari opens correctly

**Acceptance Criteria**:
- [ ] All automated tests pass (100% of integration tests)
- [ ] Manual test scenarios completed successfully
- [ ] README documents setup process (OAuth app, running app)
- [ ] No TODOs or FIXMEs in production code
- [ ] Code reviewed and merged

---

## Summary: Implementation Plan

**Total PRs**: 12  
**Estimated Completion**: 2-3 weeks (assuming 1-2 PRs per day)

**Dependency Graph**:
```
PR #1 (Infrastructure Protocols)
  ├── PR #2 (Domain Models + Keychain)
  │     └── PR #5 (Auth Container) ────┐
  │                                      │
  ├── PR #3 (GitHub API Client)         │
  │     ├── PR #5 (Auth Container)      │
  │     └── PR #6 (PR List Container) ──┤
  │                                      │
  └── PR #4 (OAuth Manager)              │
        └── PR #5 (Auth Container)       │
                                         ↓
                               PR #7 (Shared Views)
                                         ↓
                        ┌────────────────┴────────────────┐
                        │                                 │
                  PR #8 (Login View)             PR #9 (PR List View)
                        │                                 │
                        └────────────────┬────────────────┘
                                         ↓
                              PR #10 (Error Handling)
                                         ↓
                              PR #11 (Polish & Formatting)
                                         ↓
                              PR #12 (Final Testing & Docs)
```

**Critical Path**: PRs #1 → #2 → #3 → #5 → #6 → #7 → #9 → #10 → #12

**Parallel Work Opportunities**:
- PR #4 (OAuth Manager) can be developed alongside PR #2-3
- PR #7 (Shared Views) can be built while waiting on containers
- PR #8 (Login View) and PR #9 (PR List View) can be developed in parallel after PR #7

**Risk Mitigation**:
- Each PR is tested independently before merging
- Integration tests catch cross-layer issues early
- Manual testing verifies OAuth flow (hardest to automate)
- Constitutional principles enforced via code review checklist
