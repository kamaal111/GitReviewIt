# Data Model: Pull Request Preview Metadata

**Feature**: Pull Request Preview Metadata  
**Date**: December 25, 2025

## Overview

This document defines the data models for preview metadata enrichment. Models follow value semantics (structs), explicit optionality for async-loaded data, and clear semantic meaning for zero vs unavailable values.

---

## Core Entities

### PullRequest (Modified)

**Purpose**: Represents a GitHub PR with preview metadata for quick triage.

**Modifications**:
- Add `commentCount: Int` (from Search API - always available)
- Add `labels: [PRLabel]` (from Search API - always available)
- Add `previewMetadata: PRPreviewMetadata?` (from PR Details API - loaded async)

```swift
struct PullRequest: Identifiable, Equatable, Sendable, Decodable {
    // Existing fields
    let repositoryOwner: String
    let repositoryName: String
    let number: Int
    let title: String
    let authorLogin: String
    let authorAvatarURL: URL?
    let updatedAt: Date
    let htmlURL: URL
    
    // NEW: Preview metadata from Search API (always available)
    let commentCount: Int
    let labels: [PRLabel]
    
    // NEW: Preview metadata from PR Details API (loaded asynchronously)
    var previewMetadata: PRPreviewMetadata?
    
    // Computed properties
    var id: String { "\(repositoryOwner)/\(repositoryName)#\(number)" }
    var repositoryFullName: String { "\(repositoryOwner)/\(repositoryName)" }
}
```

**Invariants**:
- `commentCount >= 0`: Never negative
- `labels`: Empty array means no labels (not unavailable)
- `previewMetadata == nil`: Metadata not yet loaded
- `previewMetadata != nil`: Metadata loaded (fields may be zero but are known)

**Decoding Strategy**:
- Search API response maps to all fields except `previewMetadata` (set to `nil`)
- PR Details API response provides data for `PRPreviewMetadata` struct

---

### PRPreviewMetadata (New)

**Purpose**: Container for asynchronously-loaded preview data from PR Details API.

```swift
struct PRPreviewMetadata: Equatable, Sendable {
    let additions: Int
    let deletions: Int
    let changedFiles: Int
    let requestedReviewers: [Reviewer]
    
    init(
        additions: Int,
        deletions: Int,
        changedFiles: Int,
        requestedReviewers: [Reviewer]
    ) {
        precondition(additions >= 0, "additions must be non-negative")
        precondition(deletions >= 0, "deletions must be non-negative")
        precondition(changedFiles >= 0, "changedFiles must be non-negative")
        
        self.additions = additions
        self.deletions = deletions
        self.changedFiles = changedFiles
        self.requestedReviewers = requestedReviewers
    }
}
```

**Invariants**:
- All counts >= 0
- `requestedReviewers`: Empty array means no reviewers (not unavailable)
- Presence of struct indicates data was successfully fetched

**Semantics**:
- `additions == 0`: PR adds no lines (valid state, e.g., deletions-only PR)
- `requestedReviewers.isEmpty`: No reviewers assigned (valid state)

---

### Reviewer (New)

**Purpose**: Represents a reviewer for a PR, including their review state.

```swift
enum ReviewState: String, Sendable {
    case requested      // Requested to review but hasn't submitted yet
    case approved       // Submitted approval review
    case changesRequested // Requested changes
    case commented      // Left comments without approval/rejection
}

struct Reviewer: Identifiable, Equatable, Sendable {
    let login: String
    let avatarURL: URL?
    let state: ReviewState
    
    var id: String { login }
    
    init(login: String, avatarURL: URL?, state: ReviewState = .requested) {
        precondition(!login.isEmpty, "login must not be empty")
        self.login = login
        self.avatarURL = avatarURL
        self.state = state
    }
}

extension Reviewer: Decodable {
    enum CodingKeys: String, CodingKey {
        case login
        case avatarURL = "avatar_url"
        case state
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        login = try container.decode(String.self, forKey: .login)
        avatarURL = try container.decodeIfPresent(URL.self, forKey: .avatarURL)
        state = try container.decodeIfPresent(ReviewState.self, forKey: .state) ?? .requested
    }
}
```

**Invariants**:
- `login`: Never empty
- `avatarURL`: May be nil (user has no avatar or API didn't provide)
- `state`: Defaults to `.requested` for backward compatibility

**GitHub API Integration**:
- `requested_reviewers` from PR Details API → state = `.requested`
- Reviews from PR Reviews API → state mapped from review.state:
  - "APPROVED" → `.approved`
  - "CHANGES_REQUESTED" → `.changesRequested`
  - "COMMENTED" → `.commented`
- If a user has multiple reviews, the latest review (by `submitted_at`) determines their state

---

### PRLabel (New)

**Purpose**: Represents a label/tag applied to a PR.

```swift
struct PRLabel: Identifiable, Equatable, Sendable {
    let name: String
    let color: String
    
    var id: String { name }
    
    init(name: String, color: String) {
        precondition(!name.isEmpty, "name must not be empty")
        precondition(color.count == 6, "color must be 6-character hex code")
        self.name = name
        self.color = color
    }
}
```

**Invariants**:
- `name`: Never empty
- `color`: 6-character hex code (e.g., "d73a4a")

**Display**:
- Use `Color(hex: color)` for label background
- Choose text color (black/white) based on background luminance

---

## API Response Mapping

### Search Issues API → PullRequest

**Source**: Existing `SearchIssueItem` response

**Mapping**:
```swift
func mapSearchIssueToPullRequest(_ item: SearchIssueItem) -> PullRequest? {
    guard let (owner, name) = extractRepositoryInfo(from: item.repository_url) else {
        return nil
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
        commentCount: item.comments,                    // NEW
        labels: item.labels.map { mapLabel($0) },       // NEW
        previewMetadata: nil                            // NEW (loaded later)
    )
}

private func mapLabel(_ apiLabel: SearchIssueLabelItem) -> PRLabel {
    PRLabel(name: apiLabel.name, color: apiLabel.color)
}
```

---

### PR Details API → PRPreviewMetadata

**Source**: `GET /repos/{owner}/{repo}/pulls/{number}` response

**Mapping**:
```swift
func mapPRDetailsToPRPreviewMetadata(_ response: PRDetailsResponse) -> PRPreviewMetadata {
    PRPreviewMetadata(
        additions: response.additions,
        deletions: response.deletions,
        changedFiles: response.changed_files,
        requestedReviewers: response.requested_reviewers.map { reviewer in
            Reviewer(login: reviewer.login, avatarURL: reviewer.avatar_url, state: .requested)
        },
        completedReviewers: []  // Populated by merging with fetchPRReviews() results
    )
}
```

**Struct Definitions for Decoding**:
```swift
struct PRDetailsResponse: Decodable {
    let additions: Int
    let deletions: Int
    let changed_files: Int
    let requested_reviewers: [ReviewerResponse]
    let requested_teams: [TeamResponse]  // Future: Could include teams
    
    struct ReviewerResponse: Decodable {
        let login: String
        let avatar_url: URL?
    }
    
    struct TeamResponse: Decodable {
        let name: String
        let slug: String
    }
}

struct PRReviewResponse: Decodable {
    let user: UserResponse
    let state: String  // "APPROVED", "CHANGES_REQUESTED", "COMMENTED", "DISMISSED"
    let submitted_at: String  // ISO8601 timestamp
    
    struct UserResponse: Decodable {
        let login: String
        let avatar_url: URL?
    }
}
```

**Review Data Merging Logic**:
```swift
// In GitHubAPIClient.fetchPRDetails:
// 1. Fetch PR details (includes requested_reviewers)
// 2. Fetch PR reviews in parallel
// 3. Merge in PRDetailsResponse.toPRPreviewMetadata(reviews:)

// Merge algorithm:
// - Build map of latest review per user (by submitted_at timestamp)
// - Convert requested_reviewers to Reviewer with state = .requested
// - Convert completed reviews to Reviewer with mapped state:
//   * "APPROVED" -> .approved
//   * "CHANGES_REQUESTED" -> .changesRequested  
//   * "COMMENTED" -> .commented
// - User appears in EITHER requested OR completed, never both
```

---

## State Management

### PullRequestListContainer (Modified)

**New Responsibilities**:
- After loading PR list, enrich PRs with metadata asynchronously
- Cache enriched metadata by PR ID
- Isolate enrichment failures per PR

**New State**:
```swift
@Observable
@MainActor
final class PullRequestListContainer {
    // Existing
    private(set) var loadingState: LoadingState<[PullRequest]> = .idle
    private(set) var filterState: FilterState
    
    // NEW: Metadata enrichment state
    private(set) var isEnrichingMetadata = false
    private var metadataCache: [String: PRPreviewMetadata] = [:]
    
    // Dependencies
    private let githubAPI: GitHubAPI
    private let credentialStorage: CredentialStorage
    // ...
}
```

**New Intent Methods**:
```swift
/// Enriches PRs with preview metadata from PR Details API
/// Runs asynchronously after initial PR list load
/// Individual failures don't affect overall list
func enrichPreviewMetadata() async

/// Clears cached metadata (call on logout or manual refresh)
func clearMetadataCache()
```

**Invariants**:
- `isEnrichingMetadata == true`: Metadata fetch in progress
- `metadataCache[pr.id] != nil`: Metadata cached for that PR
- Cache cleared when `loadPullRequests()` called (fresh data)

---

## Data Flow

### Initial Load

```
User opens app
    → loadPullRequests()
    → Fetch Search API (comments + labels included)
    → Set loadingState = .loaded([PullRequest])
    → Display PR list (with comments/labels, no change stats yet)
    → enrichPreviewMetadata()
        → For each PR in parallel:
            → Fetch PR Details API
            → Update PR.previewMetadata
            → Cache in metadataCache
            → Notify view (Observation triggers re-render)
```

### Refresh

```
User pulls to refresh
    → loadPullRequests()
    → Clear metadataCache
    → (Same flow as initial load)
```

### Filtering/Searching

```
User types search query
    → filterState.searchQuery = "bug"
    → filteredPullRequests computed property runs
    → Returns PRs matching query (metadata preserved)
    → No additional API calls (metadata already loaded)
```

---

## Relationships

```
PullRequest
├── commentCount: Int                    // From Search API
├── labels: [PRLabel]                    // From Search API
└── previewMetadata: PRPreviewMetadata?  // From PR Details API
    ├── additions: Int
    ├── deletions: Int
    ├── changedFiles: Int
    └── requestedReviewers: [Reviewer]

PRLabel
├── name: String
└── color: String

Reviewer
├── login: String
└── avatarURL: URL?
```

---

## Validation Rules

### PullRequest
- ✅ `commentCount >= 0`
- ✅ `labels` may be empty (valid: PR has no labels)
- ✅ `previewMetadata == nil` (valid: not yet loaded)

### PRPreviewMetadata
- ✅ `additions >= 0`
- ✅ `deletions >= 0`
- ✅ `changedFiles >= 0`
- ✅ `requestedReviewers` may be empty (valid: no reviewers)

### Reviewer
- ✅ `login` not empty
- ✅ `avatarURL` may be nil (valid: no avatar)

### PRLabel
- ✅ `name` not empty
- ✅ `color` is 6-character hex (validated in init)

---

## Testing Fixtures

### Minimal PR (Zero Metadata)
```json
{
  "additions": 0,
  "deletions": 0,
  "changed_files": 0,
  "requested_reviewers": [],
  "labels": []
}
```

### Typical PR
```json
{
  "additions": 145,
  "deletions": 23,
  "changed_files": 7,
  "requested_reviewers": [
    {
      "login": "reviewer1",
      "avatar_url": "https://avatars.githubusercontent.com/u/123?v=4"
    }
  ],
  "labels": [
    {
      "name": "bug",
      "color": "d73a4a"
    }
  ]
}
```

### Large PR (Edge Case)
```json
{
  "additions": 12450,
  "deletions": 3280,
  "changed_files": 156,
  "requested_reviewers": [
    {"login": "reviewer1", "avatar_url": "..."},
    {"login": "reviewer2", "avatar_url": "..."},
    {"login": "reviewer3", "avatar_url": "..."}
  ]
}
```

---

## Migration Notes

**Breaking Changes**: None. Feature is additive.

**Existing PRs**: When deployed, existing `PullRequest` objects will initialize with:
- `commentCount = 0` (default until re-fetched)
- `labels = []` (default until re-fetched)
- `previewMetadata = nil` (loaded on next enrichment)

**Backward Compatibility**: Views must handle `nil` preview metadata gracefully (already required for async loading).
