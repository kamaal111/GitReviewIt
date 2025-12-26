# Feature Specification: GitHub PR Review Viewer

**Feature Branch**: `001-github-pr-viewer`  
**Created**: December 20, 2025  
**Status**: Completed  
**Input**: User description: "Build an Apple-platform SwiftUI app that provides a convenient way to view all GitHub Pull Requests the user needs to review"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - First-Time GitHub Authentication (Priority: P1)

As a developer who wants to review PRs, I need to authenticate with my GitHub account so the app can access my review requests.

**Why this priority**: Without authentication, no other features can work. This is the foundational capability that enables all value.

**Independent Test**: Can be fully tested by launching a fresh install, seeing the login prompt, entering a Personal Access Token (and optional GitHub Enterprise URL), and verifying credentials are stored. Delivers value by establishing a secure connection to GitHub or GitHub Enterprise.

**Acceptance Scenarios**:

1. **Given** the app is launched for the first time with no stored credentials, **When** the user views the first screen, **Then** a login screen is displayed with fields for Personal Access Token and optional API base URL
2. **Given** the user doesn't have a Personal Access Token, **When** viewing the login screen, **Then** a "Need a token?" help link is visible that opens GitHub's token creation page (https://github.com/settings/tokens) in the browser
3. **Given** the user enters a valid Personal Access Token, **When** credentials are validated successfully, **Then** the credentials are stored securely in Keychain
4. **Given** authentication succeeds, **When** the credentials are stored, **Then** the app navigates to the PR review list screen
5. **Given** authentication fails (invalid token or unreachable server), **When** validation completes, **Then** the user remains on the login screen with an appropriate error message
6. **Given** the user enters a custom GitHub Enterprise API base URL, **When** credentials are validated, **Then** the app connects to the specified GitHub Enterprise instance

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

1. **Given** credentials are stored from a previous session, **When** the app launches, **Then** the login screen is skipped and the PR list screen is shown
2. **Given** the app uses stored credentials, **When** the token is valid, **Then** PRs load successfully
3. **Given** stored credentials are used, **When** the token is invalid or expired (401 response), **Then** the app clears the credentials and returns to the login screen

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

- How does the system handle a token that becomes invalid mid-session (e.g., user revokes access on GitHub)?
- What happens when the GitHub API or GitHub Enterprise server is completely unreachable (DNS failure, server down)?
- How does the app behave when the user provides an invalid GitHub Enterprise base URL?
- What happens when switching between GitHub.com and GitHub Enterprise instances?
- What happens when the device has no internet connection at launch?
- How does the system handle partial or corrupted data in the keychain?
- What happens when GitHub returns PRs with missing or null fields?
- How does the app handle extremely long PR titles or repository names in the UI?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a credential entry interface for GitHub Personal Access Token and optional GitHub Enterprise API base URL
- **FR-002**: System MUST store credentials (token and base URL) securely in the device Keychain for persistence across app launches
- **FR-003**: System MUST support both GitHub.com (default: `https://api.github.com`) and GitHub Enterprise (custom base URL) with the same interface
- **FR-004**: System MUST validate credentials by attempting to fetch the user's identity using the GitHub API (`GET {baseURL}/user`) after credential entry
- **FR-005**: System MUST display clear error messages when credentials are invalid or the server is unreachable
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

- **GitHubCredentials**: Represents stored authentication credentials with Personal Access Token, GitHub instance API base URL (defaults to `https://api.github.com` for GitHub.com), and creation timestamp. Stored securely in Keychain. Supports both GitHub.com and GitHub Enterprise.
- **AuthenticatedUser**: Represents the currently logged-in GitHub user with username (login), display name, and optional avatar URL. Used to personalize the experience and construct API queries.
- **PullRequest**: Represents a GitHub PR awaiting review. Contains repository owner, repository name, PR number, title, author username, author avatar URL, last updated timestamp, and web URL for opening in browser. Sourced from GitHub Search API results.
- **PullRequestList**: Represents the collection of PRs displayed to the user, including fetch state (loading, loaded, error) and the list of PRs. Manages the entire screen state.
- **APIError**: Represents various error conditions: network unreachable, authentication failed, rate limited (with reset time), invalid response, and generic errors. Used to display appropriate error messages to users.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can authenticate with GitHub and see their first PR list within 30 seconds of entering their Personal Access Token
- **SC-002**: Users returning to the app see their PR list within 3 seconds of launch without re-authenticating
- **SC-003**: Users can successfully authenticate with both GitHub.com and GitHub Enterprise using the same credential entry interface
- **SC-004**: PR list displays all required information (repo name, title, author, timestamp) clearly and is scrollable with no performance degradation for lists up to 100 items
- **SC-005**: Users can successfully open any PR in Safari with a single tap, reaching the GitHub page within 2 seconds
- **SC-006**: When network errors occur, 90% of users understand what went wrong from the error message and know they can retry
- **SC-007**: Users can log out and back in with a different GitHub account without any residual data from the previous session
- **SC-008**: App handles token expiration gracefully without crashes—users are automatically returned to login screen when token becomes invalid
- **SC-009**: App successfully displays an appropriate empty state when users have zero PRs awaiting review

## API Integration Details

### GitHub Personal Access Token Authentication

**Credential Format**:
- **Personal Access Token**: GitHub or GitHub Enterprise PAT with `repo` scope (or `public_repo` for public-only)
  - Format: `ghp_...` (GitHub.com) or `gho_...` (GitHub Enterprise)
  - Created at: `https://github.com/settings/tokens` or `https://your-enterprise.com/settings/tokens`
- **API Base URL** (optional): 
  - GitHub.com: `https://api.github.com` (default)
  - GitHub Enterprise: `https://github.company.com/api/v3` or custom URL

**Credential Validation Flow**:
1. User provides Personal Access Token and optional base URL (defaults to `https://api.github.com`)
2. App validates base URL is HTTPS
3. App attempts `GET {baseURL}/user` with token in Authorization header
4. If 200 OK → credentials valid, store in Keychain
5. If 401 → invalid token, show error
6. If network error → unreachable server, show error

**Security Notes**:
- Personal Access Token must be stored in Keychain with appropriate accessibility settings
- Base URL must be validated to use HTTPS (reject HTTP)
- No OAuth client ID or client secret required
- Works identically for GitHub.com and GitHub Enterprise

**GitHub Enterprise Support**:
- User can specify custom API base URL (e.g., `https://git.company.com/api/v3`)
- Same API endpoints work for both GitHub.com and Enterprise
- App supports any GitHub instance by storing base URL with credentials
- No separate OAuth app registration required per instance

### GitHub API Endpoints

**Get Current User**:
- **Endpoint**: `GET {baseURL}/user`
- **Headers**: `Authorization: Bearer <token>`, `Accept: application/vnd.github+json`
- **Response**: `{ "login": "username", "name": "Display Name", "avatar_url": "...", ... }`
- **Expected Errors**: `401` (invalid or expired token), `403` (rate limited)

**Search Pull Requests**:
- **Endpoint**: `GET {baseURL}/search/issues`
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

**Swift Package**: All code lives in `app/GitReviewItApp/Sources/GitReviewItApp/`

```
app/GitReviewItApp/Sources/GitReviewItApp/
├── App/
│   ├── GitReviewItApp.swift          // App entry point, environment setup
│   └── AppState.swift                // Top-level observable state (auth status, routing)
├── Features/
│   ├── Authentication/
│   │   ├── Views/
│   │   │   └── LoginView.swift       // Login screen UI with PAT entry
│   │   ├── AuthenticationController.swift  // @Observable state container for auth
│   │   └── Models/
│   │       ├── GitHubCredentials.swift     // Credentials model (token + baseURL)
│   │       └── AuthenticatedUser.swift     // User model
│   └── PullRequestList/
│       ├── Views/
│       │   ├── PullRequestListView.swift    // Main PR list screen
│       │   ├── PullRequestRow.swift         // Individual PR row component
│       │   └── EmptyStateView.swift         // Empty state when no PRs
│       ├── PullRequestListController.swift  // @Observable state container
│       └── Models/
│           └── PullRequest.swift            // PR model
├── Infrastructure/
│   ├── API/
│   │   ├── GitHubAPIClient.swift            // Protocol + URLSession implementation
│   │   └── Models/
│   │       ├── GitHubAPIError.swift         // API error types
│   │       └── SearchResponse.swift         // API response models
│   └── Storage/
│       ├── CredentialStore.swift            // Protocol + Keychain implementation
│       └── KeychainHelper.swift             // Low-level Keychain wrapper
└── Shared/
    ├── Extensions/
    │   └── Date+RelativeFormat.swift        // "2 hours ago" formatting
    └── Models/
        └── LoadingState.swift               // Generic loading state enum
```

**Tests**: All tests live in `app/GitReviewItApp/Tests/GitReviewItAppTests/`

### Protocol Boundaries for Testing

**GitHubAPIProviding**:
```swift
protocol GitHubAPIProviding {
    func fetchUser(token: String, baseURL: String) async throws -> AuthenticatedUser
    func searchPullRequests(username: String, token: String, baseURL: String) async throws -> [PullRequest]
}
```

**CredentialStoring**:
```swift
protocol CredentialStoring {
    func saveCredentials(token: String, baseURL: String) async throws
    func loadCredentials() async throws -> (token: String, baseURL: String)?
    func deleteCredentials() async throws
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
1. **First Launch Flow**: AppState initializes → no credentials → shows login → user enters PAT + baseURL → credentials validated → stored → navigates to PR list → PRs loaded
2. **Returning User Flow**: AppState initializes → credentials present → skips login → PRs loaded → displays in list
3. **Invalid Token Flow**: PR list loads → API returns 401 → credentials cleared → navigates to login
4. **Rate Limit Flow**: PR list loads → API returns 403 with rate limit headers → error displayed with reset time
5. **Empty PR List**: PR list loads → API returns zero items → empty state displayed
6. **Logout Flow**: User on PR list → logout called → credentials cleared → navigates to login
7. **GitHub Enterprise Flow**: User enters Enterprise base URL → credentials validated against Enterprise API → PRs fetched from Enterprise

**What to Mock**:
- URLSession (using URLProtocol or protocol-based transport)
- Keychain operations (using in-memory test implementation)

**What NOT to Mock**:
- Controllers (test real implementations)
- Models (use real instances)
- Internal service collaborations (test integration)

### Implementation Phases

**Phase 1: Authentication Foundation** (1-2 PRs)
- Implement `CredentialStore` with Keychain backing
- Create `AuthenticationController` with authenticate/logout actions
- Create `LoginView` with PAT entry and optional base URL fields
- Add tests for credential storage and validation flow

**Phase 2: API Integration** (1-2 PRs)
- Implement `GitHubAPIClient` with URLSession and baseURL parameter support
- Add `fetchUser` endpoint support (works with any baseURL)
- Add `searchPullRequests` endpoint support (works with any baseURL)
- Add error handling and rate limit detection
- Add tests for API client with fixtures for both GitHub.com and Enterprise

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

- **Authentication Method**: Uses GitHub Personal Access Tokens (PAT) - no OAuth client registration required, works seamlessly with GitHub Enterprise
- **Token Creation**: Assumes users can create PATs via GitHub settings (`github.com/settings/tokens` or Enterprise equivalent)
- **Scope Decision**: Assumes `repo` scope is acceptable to users for accessing private repo PRs. If user concerns arise, can be scoped down to `public_repo` for public-only access
- **Token Lifetime**: Assumes GitHub PATs do not expire automatically (they remain valid until revoked), so no refresh token flow is needed
- **GitHub Enterprise**: Assumes users know their GitHub Enterprise API base URL (typically `https://github.enterprise.com/api/v3`)
- **PR Definition**: Assumes "PRs needing review" means PRs where the user is explicitly requested as a reviewer (via `review-requested:<username>` query). Does not include PRs where user is in a requested team or assigned
- **Single Account**: Assumes single GitHub account per app instance. Multi-account switching is out of scope for MVP
- **Platform**: macOS-only using SwiftUI. iOS support can be added later with minimal changes
- **Pagination**: Assumes fetching the first 50 PRs is sufficient for MVP. Pagination can be added later if needed
- **Offline Support**: Assumes no offline caching of PRs. App requires network connectivity to display data
- **Notifications**: Assumes no push notifications or background refresh. Users must open the app to see updated PR lists
- **PR Definition**: Assumes "PRs needing review" means PRs where the user is explicitly requested as a reviewer (via `review-requested:<username>` query). Does not include PRs where user is in a requested team or assigned
- **Single Account**: Assumes single GitHub account per app instance. Multi-account switching is out of scope for MVP
- **Platform**: Assumes iOS/macOS using SwiftUI. If macOS-specific considerations exist (menu bar, multiple windows), they are out of scope for MVP
- **Pagination**: Assumes fetching the first 50 PRs is sufficient for MVP. Pagination can be added later if needed
- **Offline Support**: Assumes no offline caching of PRs. App requires network connectivity to display data
- **Notifications**: Assumes no push notifications or background refresh. Users must open the app to see updated PR lists
