# Data Model: GitHub PR Review Viewer

**Feature**: 001-github-pr-viewer  
**Date**: December 20, 2025  
**Status**: Complete

## Purpose

This document defines all domain entities, value objects, and state models for the GitHub PR Review Viewer. All types are derived from functional requirements and user scenarios.

---

## Domain Models

### GitHubToken

**Purpose**: Represents an OAuth access token for authenticating with GitHub API.

**Type**: Value type (struct)

**Properties**:
| Name | Type | Optional | Description |
|------|------|----------|-------------|
| `value` | String | No | The raw OAuth token string |
| `createdAt` | Date | No | Timestamp when token was obtained |
| `scopes` | Set<String> | No | OAuth scopes granted (e.g., "repo") |

**Validation Rules**:
- `value` must not be empty
- `createdAt` must not be in the future
- `scopes` must not be empty

**Usage Context**:
- Created during OAuth flow completion
- Stored in Keychain via TokenStorage protocol
- Attached to all GitHub API requests as Bearer token

**Swift Definition**:
```swift
struct GitHubToken: Codable, Equatable {
    let value: String
    let createdAt: Date
    let scopes: Set<String>
    
    init(value: String, createdAt: Date = Date(), scopes: Set<String>) {
        precondition(!value.isEmpty, "Token value cannot be empty")
        precondition(createdAt <= Date(), "Token creation date cannot be in future")
        precondition(!scopes.isEmpty, "Token must have at least one scope")
        
        self.value = value
        self.createdAt = createdAt
        self.scopes = scopes
    }
}
```

---

### AuthenticatedUser

**Purpose**: Represents the currently logged-in GitHub user.

**Type**: Value type (struct)

**Properties**:
| Name | Type | Optional | Description |
|------|------|----------|-------------|
| `login` | String | No | GitHub username (e.g., "octocat") |
| `name` | String | Yes | Display name (may be nil if user hasn't set one) |
| `avatarURL` | URL | Yes | URL to user's profile avatar image |

**Validation Rules**:
- `login` must not be empty
- `login` must match GitHub username rules (alphanumeric + hyphens, no spaces)

**Usage Context**:
- Fetched from `/user` endpoint after OAuth success
- Used to construct PR search query (`review-requested:<login>`)
- May be displayed in UI for personalization (future enhancement)

**Swift Definition**:
```swift
struct AuthenticatedUser: Codable, Equatable {
    let login: String
    let name: String?
    let avatarURL: URL?
    
    enum CodingKeys: String, CodingKey {
        case login
        case name
        case avatarURL = "avatar_url"
    }
    
    init(login: String, name: String? = nil, avatarURL: URL? = nil) {
        precondition(!login.isEmpty, "Login cannot be empty")
        self.login = login
        self.name = name
        self.avatarURL = avatarURL
    }
}
```

---

### PullRequest

**Purpose**: Represents a GitHub pull request awaiting the user's review.

**Type**: Value type (struct)

**Properties**:
| Name | Type | Optional | Description |
|------|------|----------|-------------|
| `repositoryOwner` | String | No | Repository owner username (e.g., "apple") |
| `repositoryName` | String | No | Repository name (e.g., "swift") |
| `number` | Int | No | PR number within repository |
| `title` | String | No | PR title |
| `authorLogin` | String | No | Username of PR author |
| `authorAvatarURL` | URL | Yes | Avatar URL for PR author |
| `updatedAt` | Date | No | Last update timestamp |
| `htmlURL` | URL | No | GitHub web URL for opening PR |

**Computed Properties**:
| Name | Type | Description |
|------|------|-------------|
| `repositoryFullName` | String | "owner/repo" format for display |
| `relativeUpdateTime` | String | Human-readable relative time (e.g., "2 hours ago") |

**Validation Rules**:
- `repositoryOwner` must not be empty
- `repositoryName` must not be empty
- `number` must be positive
- `title` must not be empty
- `authorLogin` must not be empty
- `updatedAt` must not be in the future

**Usage Context**:
- Parsed from GitHub Search API response
- Displayed in list view
- Tapped to open `htmlURL` in Safari

**Swift Definition**:
```swift
struct PullRequest: Identifiable, Codable, Equatable {
    let id: String  // Computed from owner/repo/number
    let repositoryOwner: String
    let repositoryName: String
    let number: Int
    let title: String
    let authorLogin: String
    let authorAvatarURL: URL?
    let updatedAt: Date
    let htmlURL: URL
    
    var repositoryFullName: String {
        "\(repositoryOwner)/\(repositoryName)"
    }
    
    // RelativeUpdateTime computed via DateFormatter or RelativeDateTimeFormatter
    
    enum CodingKeys: String, CodingKey {
        case number, title
        case authorLogin = "author_login"
        case authorAvatarURL = "author_avatar_url"
        case updatedAt = "updated_at"
        case htmlURL = "html_url"
        // repositoryOwner/Name parsed from repository_url
    }
    
    init(repositoryOwner: String, repositoryName: String, number: Int, title: String, 
         authorLogin: String, authorAvatarURL: URL?, updatedAt: Date, htmlURL: URL) {
        precondition(!repositoryOwner.isEmpty, "Repository owner cannot be empty")
        precondition(!repositoryName.isEmpty, "Repository name cannot be empty")
        precondition(number > 0, "PR number must be positive")
        precondition(!title.isEmpty, "PR title cannot be empty")
        precondition(!authorLogin.isEmpty, "Author login cannot be empty")
        precondition(updatedAt <= Date(), "Updated date cannot be in future")
        
        self.id = "\(repositoryOwner)/\(repositoryName)#\(number)"
        self.repositoryOwner = repositoryOwner
        self.repositoryName = repositoryName
        self.number = number
        self.title = title
        self.authorLogin = authorLogin
        self.authorAvatarURL = authorAvatarURL
        self.updatedAt = updatedAt
        self.htmlURL = htmlURL
    }
}
```

---

## Error Types

### APIError

**Purpose**: Represents all possible API and networking failures.

**Type**: Enum conforming to Error, LocalizedError

**Cases**:
| Case | Associated Values | Description |
|------|-------------------|-------------|
| `networkUnavailable` | None | Device has no internet connection |
| `unauthorized` | None | Token is invalid or expired (401) |
| `rateLimited` | `resetDate: Date` | GitHub rate limit exceeded (403) |
| `invalidResponse` | `statusCode: Int` | Unexpected HTTP status or malformed JSON |
| `serverError` | `statusCode: Int` | GitHub service error (5xx) |
| `unknown` | `Error` | Unexpected error (wraps underlying error) |

**User-Facing Messages**:
- `networkUnavailable`: "No internet connection. Please check your network."
- `unauthorized`: "Your session has expired. Please log in again."
- `rateLimited`: "GitHub rate limit exceeded. Resets at \(resetDate formatted)."
- `invalidResponse`: "Received unexpected response from GitHub."
- `serverError`: "GitHub is temporarily unavailable. Please try again later."
- `unknown`: "An unexpected error occurred. Please try again."

**Swift Definition**:
```swift
enum APIError: Error, LocalizedError {
    case networkUnavailable
    case unauthorized
    case rateLimited(resetDate: Date)
    case invalidResponse(statusCode: Int)
    case serverError(statusCode: Int)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection. Please check your network."
        case .unauthorized:
            return "Your session has expired. Please log in again."
        case .rateLimited(let resetDate):
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return "GitHub rate limit exceeded. Resets at \(formatter.string(from: resetDate))."
        case .invalidResponse:
            return "Received unexpected response from GitHub."
        case .serverError:
            return "GitHub is temporarily unavailable. Please try again later."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .unauthorized:
            return nil  // Automatic logout, no action needed
        case .rateLimited:
            return "Wait for the rate limit to reset."
        case .invalidResponse, .serverError, .unknown:
            return "Try again in a few moments."
        }
    }
}
```

---

## State Models

### AuthenticationState

**Purpose**: Represents the current authentication status of the app.

**Type**: Enum

**Cases**:
| Case | Description |
|------|-------------|
| `unauthenticated` | User is not logged in; login screen should be shown |
| `authenticating` | OAuth flow is in progress |
| `authenticated` | User is logged in with valid token |

**State Transitions**:
```
unauthenticated → authenticating → authenticated
                ↖                 ↙
                  (logout / 401)
```

**Swift Definition**:
```swift
enum AuthenticationState: Equatable {
    case unauthenticated
    case authenticating
    case authenticated
}
```

---

### LoadingState<T>

**Purpose**: Generic state wrapper for async operations with loading/success/error states.

**Type**: Generic enum

**Cases**:
| Case | Associated Values | Description |
|------|-------------------|-------------|
| `idle` | None | Operation hasn't started |
| `loading` | None | Operation in progress |
| `loaded` | `T` | Operation succeeded with data |
| `failed` | `APIError` | Operation failed with error |

**Swift Definition**:
```swift
enum LoadingState<T: Equatable>: Equatable {
    case idle
    case loading
    case loaded(T)
    case failed(APIError)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var data: T? {
        if case .loaded(let value) = self { return value }
        return nil
    }
    
    var error: APIError? {
        if case .failed(let error) = self { return error }
        return nil
    }
}
```

**Usage Example**:
```swift
@Observable
final class PullRequestListContainer {
    private(set) var loadingState: LoadingState<[PullRequest]> = .idle
    
    func loadPullRequests() async {
        loadingState = .loading
        do {
            let prs = try await apiClient.fetchReviewRequests()
            loadingState = .loaded(prs)
        } catch let error as APIError {
            loadingState = .failed(error)
        }
    }
}
```

---

## Relationships

```
                                   ┌──────────────────┐
                                   │  GitHubToken     │
                                   │  (stored in      │
                                   │   Keychain)      │
                                   └────────┬─────────┘
                                            │
                                            │ obtained during
                                            │
                                   ┌────────▼─────────┐
┌──────────────────┐               │ AuthenticatedUser│
│ PullRequest      │◄──────────────┤  (fetched with   │
│  - owner/repo    │  used to      │   token)         │
│  - number        │  construct    └──────────────────┘
│  - title         │  search query
│  - author        │
│  - updatedAt     │
└──────────────────┘

┌──────────────────────────────────────────────────────┐
│         LoadingState<[PullRequest]>                  │
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐    │
│  │ idle   │→ │loading │→ │loaded  │  │failed  │    │
│  └────────┘  └────────┘  └────────┘  └───┬────┘    │
│                                           │          │
│                                      ┌────▼────┐    │
│                                      │APIError │    │
│                                      └─────────┘    │
└──────────────────────────────────────────────────────┘
```

---

## Persistence Strategy

| Entity | Storage Mechanism | Lifetime | Sync Strategy |
|--------|-------------------|----------|---------------|
| GitHubToken | Keychain (kSecClassGenericPassword) | Until logout or token revocation | Not synced across devices |
| AuthenticatedUser | In-memory only (re-fetched at launch) | Current session | N/A |
| PullRequest | In-memory only (re-fetched on demand) | Current screen | N/A |
| APIError | Transient (displayed in UI, cleared on retry) | Until retry or success | N/A |

**Rationale**:
- Token must persist across launches → Keychain
- User/PR data is dynamic and changes frequently → fetch fresh each session
- No local caching needed for MVP (always show live data)

---

## Summary

All domain entities are defined with clear responsibilities, validation rules, and relationships. Models are immutable value types (structs) where possible. State is managed through explicit enums (AuthenticationState, LoadingState). Error handling is typed and user-facing messages are defined.

Ready to proceed to API contract generation.
