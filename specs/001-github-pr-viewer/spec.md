# Feature Specification: GitHub PR Review Viewer

**Feature Branch**: `001-github-pr-viewer`  
**Created**: December 20, 2025  
**Status**: Draft  
**Input**: User description: "Build an Apple-platform SwiftUI app that provides a convenient way to view all GitHub Pull Requests the user needs to review"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - First-Time GitHub Authentication (Priority: P1)

As a developer who wants to review PRs, I need to authenticate with my GitHub account so the app can access my review requests.

**Why this priority**: Without authentication, no other features can work. This is the foundational capability that enables all value.

**Independent Test**: Can be fully tested by launching a fresh install, seeing the login screen, completing OAuth flow, and verifying a token is stored. Delivers value by establishing a secure connection to GitHub.

**Acceptance Scenarios**:

1. **Given** the app is launched for the first time with no stored token, **When** the user views the first screen, **Then** a login screen is displayed with a "Sign in with GitHub" option
2. **Given** the user taps "Sign in with GitHub", **When** the OAuth flow completes successfully, **Then** an access token is obtained and stored securely
3. **Given** authentication succeeds, **When** the token is stored, **Then** the app navigates to the PR review list screen
4. **Given** authentication fails or is cancelled, **When** the OAuth flow returns, **Then** the user remains on the login screen with an appropriate message

---

### User Story 2 - View PRs Awaiting My Review (Priority: P1)

As an authenticated user, I need to see a list of all pull requests where my review is requested, so I can decide what to review next.

**Why this priority**: This is the core value proposition—showing the user what needs their attention. Without this, the app provides no value beyond authentication.

**Independent Test**: Can be fully tested by authenticating a user, then verifying the app fetches and displays PRs where review is requested. Delivers immediate value by surfacing review work.

**Acceptance Scenarios**:

1. **Given** the user is authenticated with a valid token, **When** the PR list screen loads, **Then** the app fetches PRs where the user's review is requested
2. **Given** PRs are being fetched, **When** the request is in progress, **Then** a loading indicator is displayed
3. **Given** the API returns PR data, **When** the data is received, **Then** each PR is displayed showing repository name, PR title, author, and last update time
4. **Given** the user has no PRs awaiting review, **When** the list loads, **Then** an empty state message is shown (e.g., "No PRs awaiting your review")
5. **Given** a PR is displayed, **When** the user taps on it, **Then** the PR opens in Safari at its GitHub URL

---

### User Story 3 - Return to PR List Without Re-Authentication (Priority: P1)

As a returning user, I need the app to remember my authentication so I can view my PR list immediately without logging in again.

**Why this priority**: Essential for usability—users won't use an app that requires login every time. This completes the basic happy-path experience.

**Independent Test**: Can be fully tested by authenticating once, closing the app completely, relaunching, and verifying the PR list loads immediately without showing the login screen.

**Acceptance Scenarios**:

1. **Given** a token is stored from a previous session, **When** the app launches, **Then** the login screen is skipped and the PR list screen is shown
2. **Given** the app uses a stored token, **When** the token is valid, **Then** PRs load successfully
3. **Given** a stored token is used, **When** the token is invalid or expired (401 response), **Then** the app clears the token and returns to the login screen

---

### User Story 4 - Handle Errors Gracefully (Priority: P2)

As a user, I need to understand when something goes wrong and be able to retry, so I'm not stuck in a broken state.

**Why this priority**: Important for reliability and user trust, but the app can be demonstrated without this if error scenarios are avoided during demo.

**Independent Test**: Can be tested by simulating network failures or API errors and verifying appropriate error messages and retry options appear.

**Acceptance Scenarios**:

1. **Given** a network request fails, **When** the error occurs, **Then** an error message is displayed explaining the issue (e.g., "Unable to load PRs. Check your connection.")
2. **Given** an error message is displayed, **When** a retry action is available, **Then** the user can tap it to retry the failed operation
3. **Given** the GitHub API returns a rate limit error (403), **When** the response is received, **Then** a message explains the rate limit and when it resets
4. **Given** the API returns an unexpected response format, **When** decoding fails, **Then** a generic error message is shown without crashing

---

### User Story 5 - Log Out and Clear Session (Priority: P2)

As a user, I need to be able to log out of my GitHub account so I can switch accounts or secure my session when needed.

**Why this priority**: Important for security and multi-account scenarios, but not critical for initial MVP demo. Can be added after core list functionality works.

**Independent Test**: Can be tested by authenticating, logging out, and verifying the token is cleared and the login screen returns.

**Acceptance Scenarios**:

1. **Given** the user is on the PR list screen, **When** a logout option is available (e.g., in a menu or settings), **Then** the user can trigger logout
2. **Given** the user logs out, **When** logout completes, **Then** the stored token is removed from secure storage
3. **Given** logout completes, **When** the token is cleared, **Then** the app navigates back to the login screen
4. **Given** the user has logged out, **When** the app is relaunched, **Then** the login screen is displayed

---

### Edge Cases

- What happens when the OAuth redirect URL is intercepted but the state parameter doesn't match?
- How does the system handle a token that becomes invalid mid-session (e.g., user revokes access on GitHub)?
- What happens when the GitHub API is completely unreachable (DNS failure, server down)?
- How does the app behave if the user denies OAuth permissions?
- What happens when the device has no internet connection at launch?
- How does the system handle partial or corrupted data in the keychain?
- What happens when GitHub returns PRs with missing or null fields?
- How does the app handle extremely long PR titles or repository names in the UI?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a native OAuth authentication flow using ASWebAuthenticationSession to obtain a GitHub access token
- **FR-002**: System MUST store the access token securely in the device Keychain for persistence across app launches
- **FR-003**: System MUST request only the minimal GitHub OAuth scopes necessary to read public and private PR data (scope: `repo` for private repo access, or `public_repo` if only public repos are needed)
- **FR-004**: System MUST validate the OAuth state parameter to prevent CSRF attacks during the authentication flow
- **FR-005**: System MUST fetch the authenticated user's identity using the GitHub API (`GET /user`) after successful authentication
- **FR-006**: System MUST query pull requests where the authenticated user's review is requested using GitHub's Search API with the query: `type:pr state:open review-requested:<username>`
- **FR-007**: System MUST display a loading state while authenticating or fetching PR data
- **FR-008**: System MUST display an empty state with appropriate messaging when no PRs require review
- **FR-009**: System MUST handle and display errors for: network failures, authentication failures, API rate limiting (403 with rate limit headers), invalid tokens (401), and unexpected API responses
- **FR-010**: System MUST provide a retry mechanism when PR loading fails due to transient errors
- **FR-011**: System MUST display each PR with: repository full name (owner/repo), PR title, author username, and last updated timestamp
- **FR-012**: System MUST open the selected PR's GitHub URL in Safari when the user taps a PR item
- **FR-013**: System MUST detect when a stored token is invalid (401 response) and automatically return the user to the login screen
- **FR-014**: System MUST provide a logout action that clears the stored token and returns to the login screen
- **FR-015**: System MUST skip the login screen and load the PR list directly when a valid token exists at launch
- **FR-016**: System MUST format the last updated timestamp in a human-readable relative format (e.g., "2 hours ago", "3 days ago")
- **FR-017**: System MUST handle PRs with missing optional fields gracefully (e.g., null descriptions, missing avatars)

### Key Entities

- **GitHubToken**: Represents an OAuth access token with its string value, creation timestamp, and OAuth scopes. Stored securely in Keychain.
- **AuthenticatedUser**: Represents the currently logged-in GitHub user with username (login), display name, and optional avatar URL. Used to personalize the experience and construct API queries.
- **PullRequest**: Represents a GitHub PR awaiting review. Contains repository owner, repository name, PR number, title, author username, author avatar URL, last updated timestamp, and web URL for opening in Safari. Sourced from GitHub Search API results.
- **PullRequestList**: Represents the collection of PRs displayed to the user, including fetch state (loading, loaded, error) and the list of PRs. Manages the entire screen state.
- **APIError**: Represents various error conditions: network unreachable, authentication failed, rate limited (with reset time), invalid response, and generic errors. Used to display appropriate error messages to users.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can authenticate with GitHub and see their first PR list within 30 seconds of tapping "Sign in with GitHub"
- **SC-002**: Users returning to the app see their PR list within 3 seconds of launch without re-authenticating
- **SC-003**: 95% of users successfully complete the OAuth flow on their first attempt without errors
- **SC-004**: PR list displays all required information (repo name, title, author, timestamp) clearly and is scrollable with no performance degradation for lists up to 100 items
- **SC-005**: Users can successfully open any PR in Safari with a single tap, reaching the GitHub page within 2 seconds
- **SC-006**: When network errors occur, 90% of users understand what went wrong from the error message and know they can retry
- **SC-007**: Users can log out and back in with a different GitHub account without any residual data from the previous session
- **SC-008**: App handles token expiration gracefully without crashes—users are automatically returned to login screen when token becomes invalid
- **SC-009**: App successfully displays an appropriate empty state when users have zero PRs awaiting review

## API Integration Details

### GitHub OAuth Flow

**Endpoints Used**:
- **Authorization URL**: `https://github.com/login/oauth/authorize`
  - **Parameters**: `client_id`, `redirect_uri`, `scope`, `state` (CSRF token)
  - **Scopes Required**: `repo` (for access to private repository PRs) or `public_repo` (if only public PRs are needed)
  - **Response**: Authorization code via redirect to custom URL scheme (e.g., `gitreviewit://oauth-callback?code=...&state=...`)

- **Token Exchange**: `POST https://github.com/login/oauth/access_token`
  - **Request Body**: `client_id`, `client_secret`, `code`, `redirect_uri`
  - **Response**: `{ "access_token": "...", "token_type": "bearer", "scope": "..." }`
  - **Expected Errors**: `400` (invalid code), `401` (invalid credentials)

**Security Notes**:
- Must generate and validate a unique state parameter for each OAuth flow to prevent CSRF
- Access token must be stored in Keychain with appropriate accessibility settings
- Client secret must be handled carefully; consider using GitHub Device Flow or a lightweight backend proxy if embedding secret in app is unacceptable

### GitHub API Endpoints

**Get Current User**:
- **Endpoint**: `GET https://api.github.com/user`
- **Headers**: `Authorization: Bearer <token>`, `Accept: application/vnd.github+json`
- **Response**: `{ "login": "username", "name": "Display Name", "avatar_url": "...", ... }`
- **Expected Errors**: `401` (invalid or expired token), `403` (rate limited)

**Search Pull Requests**:
- **Endpoint**: `GET https://api.github.com/search/issues`
- **Query Parameters**: `q=type:pr state:open review-requested:<username>`, `sort=updated`, `order=desc`, `per_page=50`
- **Headers**: `Authorization: Bearer <token>`, `Accept: application/vnd.github+json`
- **Response**:
  ```json
  {
    "total_count": 5,
    "items": [
      {
        "number": 123,
        "title": "Add feature X",
        "html_url": "https://github.com/owner/repo/pull/123",
        "updated_at": "2025-12-20T10:30:00Z",
        "user": {
          "login": "author-username",
          "avatar_url": "https://avatars.githubusercontent.com/..."
        },
        "repository_url": "https://api.github.com/repos/owner/repo"
      }
    ]
  }
  ```
- **Expected Errors**: `401` (invalid token), `403` (rate limited), `422` (invalid query syntax)

**Parse Repository Owner/Name**:
- Extract from `repository_url` field (e.g., `https://api.github.com/repos/owner/repo` → `owner/repo`)

**Rate Limiting**:
- GitHub allows 5000 requests/hour for authenticated users
- Rate limit headers: `X-RateLimit-Remaining`, `X-RateLimit-Reset`
- When rate limited, display reset time to user (convert Unix timestamp to local time)

**Error Handling Behavior**:
- **401 Unauthorized**: Clear stored token, return to login screen
- **403 Rate Limited**: Display message with reset time, disable retry until reset
- **Network Error**: Display generic connectivity error, enable immediate retry
- **Decoding Error**: Display generic "unexpected response" error, log details for debugging
- **Empty Results**: Display empty state ("No PRs awaiting your review"), not an error

## Architecture & Implementation Guidance

### Proposed Module Structure

```
GitReviewIt/
├── App/
│   ├── GitReviewItApp.swift          // App entry point, environment setup
│   └── AppState.swift                // Top-level observable state (auth status, routing)
├── Features/
│   ├── Authentication/
│   │   ├── Views/
│   │   │   └── LoginView.swift       // Login screen UI
│   │   ├── AuthenticationController.swift  // @Observable state container for auth
│   │   └── Models/
│   │       └── GitHubToken.swift     // Token model
│   └── PullRequestList/
│       ├── Views/
│       │   ├── PullRequestListView.swift    // Main PR list screen
│       │   ├── PullRequestRow.swift         // Individual PR row component
│       │   └── EmptyStateView.swift         // Empty state when no PRs
│       ├── PullRequestListController.swift  // @Observable state container
│       └── Models/
│           ├── PullRequest.swift            // PR model
│           └── AuthenticatedUser.swift      // User model
├── Services/
│   ├── Authentication/
│   │   ├── GitHubAuthProvider.swift         // Protocol + implementation
│   │   └── OAuthCoordinator.swift           // Handles ASWebAuthenticationSession
│   ├── API/
│   │   ├── GitHubAPIClient.swift            // Protocol + URLSession implementation
│   │   └── Models/
│   │       ├── GitHubAPIError.swift         // API error types
│   │       └── SearchResponse.swift         // API response models
│   └── Storage/
│       ├── TokenStore.swift                 // Protocol + Keychain implementation
│       └── KeychainHelper.swift             // Low-level Keychain wrapper
└── Utilities/
    ├── Extensions/
    │   └── Date+RelativeFormat.swift        // "2 hours ago" formatting
    └── Constants.swift                      // OAuth config, API base URLs
```

### Protocol Boundaries for Testing

**GitHubAuthProviding**:
```swift
protocol GitHubAuthProviding {
    func authenticate() async throws -> GitHubToken
}
```

**GitHubAPIProviding**:
```swift
protocol GitHubAPIProviding {
    func getCurrentUser(token: String) async throws -> AuthenticatedUser
    func searchPullRequests(username: String, token: String) async throws -> [PullRequest]
}
```

**TokenStoring**:
```swift
protocol TokenStoring {
    func save(_ token: GitHubToken) throws
    func load() throws -> GitHubToken?
    func delete() throws
}
```

### State Management Pattern

- Each feature has an `@Observable` controller class that owns all state and business logic
- Views initialize controllers using `@State` (view-owned lifecycle)
- Controllers depend on protocol-based services injected via initializer
- Controllers expose state as public properties and actions as public methods
- Views observe controllers and call action methods in response to user interactions

**Example Controller**:
```swift
@Observable
final class PullRequestListController {
    private let apiClient: GitHubAPIProviding
    private let tokenStore: TokenStoring
    
    var pullRequests: [PullRequest] = []
    var isLoading: Bool = false
    var error: APIError?
    
    init(apiClient: GitHubAPIProviding, tokenStore: TokenStoring) {
        self.apiClient = apiClient
        self.tokenStore = tokenStore
    }
    
    func loadPullRequests() async { ... }
    func retry() async { ... }
}
```

### Testing Strategy

**Integration-Style Tests** (preferred):
- Test complete flows through controllers and domain logic
- Mock only the network/storage boundaries (URLSession, Keychain)
- Use deterministic fixtures for API responses
- Each test validates a user story end-to-end

**Example Tests**:
1. **First Launch Flow**: AppState initializes → no token → shows login → auth succeeds → token stored → navigates to PR list → PRs loaded
2. **Returning User Flow**: AppState initializes → token present → skips login → PRs loaded → displays in list
3. **Invalid Token Flow**: PR list loads → API returns 401 → token cleared → navigates to login
4. **Rate Limit Flow**: PR list loads → API returns 403 with rate limit headers → error displayed with reset time
5. **Empty PR List**: PR list loads → API returns zero items → empty state displayed
6. **Logout Flow**: User on PR list → logout called → token cleared → navigates to login

**What to Mock**:
- URLSession (using URLProtocol or protocol-based transport)
- Keychain operations (using in-memory test implementation)
- ASWebAuthenticationSession (using protocol wrapper)

**What NOT to Mock**:
- Controllers (test real implementations)
- Models (use real instances)
- Internal service collaborations (test integration)

### Implementation Phases

**Phase 1: Authentication Foundation** (1-2 PRs)
- Implement `TokenStore` with Keychain backing
- Implement `OAuthCoordinator` with ASWebAuthenticationSession
- Create `AuthenticationController` with login/logout actions
- Create `LoginView` with basic UI
- Add tests for token storage and auth flow

**Phase 2: API Integration** (1-2 PRs)
- Implement `GitHubAPIClient` with URLSession
- Add `getCurrentUser` endpoint support
- Add `searchPullRequests` endpoint support
- Add error handling and rate limit detection
- Add tests for API client with fixtures

**Phase 3: PR List Feature** (1-2 PRs)
- Implement `PullRequestListController`
- Create `PullRequestListView` with loading/empty/error states
- Create `PullRequestRow` component
- Add relative date formatting utility
- Add tests for controller state management

**Phase 4: App Integration** (1 PR)
- Create `AppState` to manage auth status and routing
- Connect login flow to PR list flow
- Add automatic token validation on launch
- Add logout action to PR list
- Add end-to-end integration tests

**Phase 5: Polish & Edge Cases** (1 PR)
- Improve error messages and retry UX
- Handle edge cases (missing fields, long text)
- Add loading animations
- Add accessibility labels
- Perform manual QA pass

## Assumptions

- **GitHub OAuth Client**: Assumes a GitHub OAuth App is registered with appropriate redirect URI (`gitreviewit://oauth-callback` or custom scheme)
- **Client Secret Handling**: Assumes client secret can be embedded in the app (acceptable for demo/MVP) or will use GitHub Device Flow (which doesn't require a secret)
- **Scope Decision**: Assumes `repo` scope is acceptable to users for accessing private repo PRs. If user concerns arise, can be scoped down to `public_repo` for public-only access
- **Token Lifetime**: Assumes GitHub tokens do not expire automatically (they remain valid until revoked), so no refresh token flow is needed
- **PR Definition**: Assumes "PRs needing review" means PRs where the user is explicitly requested as a reviewer (via `review-requested:<username>` query). Does not include PRs where user is in a requested team or assigned
- **Single Account**: Assumes single GitHub account per app instance. Multi-account switching is out of scope for MVP
- **Platform**: Assumes iOS/macOS using SwiftUI. If macOS-specific considerations exist (menu bar, multiple windows), they are out of scope for MVP
- **Pagination**: Assumes fetching the first 50 PRs is sufficient for MVP. Pagination can be added later if needed
- **Offline Support**: Assumes no offline caching of PRs. App requires network connectivity to display data
- **Notifications**: Assumes no push notifications or background refresh. Users must open the app to see updated PR lists
