# Implementation Plan: Pull Request Preview Metadata

**Branch**: `003-pr-preview-metadata` | **Date**: December 25, 2025 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/003-pr-preview-metadata/spec.md`

## Summary

Enhance the PR list view with preview metadata (change size, comments, reviewers, labels) to enable quick triage without opening individual PRs. The feature leverages GitHub's Search Issues API (already returns comments/labels) and adds per-PR calls to the Pull Requests API for change statistics and reviewer information. For reviewers, the implementation fetches both `requested_reviewers` (from PR Details API) and completed reviews (from PR Reviews API) to show the complete picture, since GitHub removes users from `requested_reviewers` once they submit a review. Implementation follows phased loading: immediate display of "cheap" metadata from Search API, followed by progressive enrichment with additional data fetched asynchronously.

## Technical Context

**Language/Version**: Swift 6.0 (strict concurrency enabled)  
**UI Framework**: SwiftUI with Observation framework (`@Observable`, `@State`)  
**Primary Dependencies**: None (stdlib + Foundation only)  
**Storage**: Keychain (for credentials via Security.framework), UserDefaults (for filter preferences)  
**Testing**: Swift Testing (`@Test` attribute with backtick function names)  
**Target Platform**: macOS 14.0+  
**Architecture**: Unidirectional data flow - Views send intent → State containers (`@Observable`) → View updates  
**Deployment Target**: macOS 14.0  
**Performance Goals**: PR list load <3s for 50 PRs including preview metadata; UI remains responsive during metadata enrichment  
**Constraints**: No backend; all data from GitHub REST API v3; support GitHub Enterprise (custom base URLs); no OAuth (Personal Access Token only)  
**Scale/Scope**: Displays up to ~100 PRs concurrently; metadata fetching must respect GitHub rate limits (5000 req/hour authenticated)

### Current Implementation Context

**Existing PR Fetching**:
- `GitHubAPI` protocol defines high-level GitHub operations
- `GitHubAPIClient` implements protocol using `HTTPClient`  
- `fetchReviewRequests()` performs parallel GitHub Search API calls:
  - `type:pr+state:open+review-requested:<user>`
  - `type:pr+state:open+assignee:<user>`
  - `type:pr+state:open+reviewed-by:<user>`
  - `type:pr+state:open+team-review-requested:<team>` (for each team)
- Search results deduplicated by PR ID before returning
- Search API response already includes: `comments` (int), `labels` (array)
- Search API does NOT include: additions, deletions, changed_files, requested_reviewers, review states
- Note: GitHub's `requested_reviewers` only shows people who haven't reviewed yet; completed reviews require separate API call

**Current Models**:
- `PullRequest`: `repositoryOwner`, `repositoryName`, `number`, `title`, `authorLogin`, `authorAvatarURL`, `updatedAt`, `htmlURL`
- `PullRequestListContainer`: `@Observable` state container owning `LoadingState<[PullRequest]>`, manages loading/retry/filtering
- `PullRequestRow`: SwiftUI view displaying repo name, title, author with avatar, relative time
- `FilterState`: Manages search query and filter configuration (already applied to PRs)

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

**Notes**: All principles satisfied. No violations to justify.

## Project Structure

### Documentation (this feature)

```text
specs/003-pr-preview-metadata/
├── plan.md              # This file
├── research.md          # Phase 0 output (API research)
├── data-model.md        # Phase 1 output (model design)
├── quickstart.md        # Phase 1 output (quick reference)
├── contracts/           # Phase 1 output (protocol contracts)
│   └── protocols.md
└── checklists/
    └── requirements.md  # Specification quality checklist
```

### Source Code (repository root)

```text
app/GitReviewItApp/Sources/GitReviewItApp/
├── Features/
│   └── PullRequests/
│       ├── Models/
│       │   ├── PullRequest.swift                    # MODIFY: Add preview metadata fields
│       │   ├── PRPreviewMetadata.swift              # NEW: Preview metadata value object
│       │   └── PreviewDataAvailability.swift        # NEW: Data availability state enum
│       ├── State/
│       │   ├── PullRequestListContainer.swift       # MODIFY: Add metadata enrichment logic
│       │   └── PreviewMetadataService.swift         # NEW: Metadata fetching service
│       ├── Views/
│       │   ├── PullRequestRow.swift                 # MODIFY: Display preview metadata
│       │   └── PreviewMetadataView.swift            # NEW: Metadata display subview
│       └── Services/
│           └── FilterEngine.swift                   # NO CHANGE: Filtering unaffected
├── Infrastructure/
│   └── Networking/
│       ├── GitHubAPI.swift                          # MODIFY: Add fetchPRDetails method
│       └── GitHubAPIClient.swift                    # MODIFY: Implement fetchPRDetails
└── Shared/
    └── Models/
        └── LoadingState.swift                       # NO CHANGE: Reuse existing

app/GitReviewItApp/Tests/GitReviewItAppTests/
├── Fixtures/
│   ├── pr-details-response.json                     # NEW: PR details API fixture
│   └── pr-details-with-varied-metadata.json         # NEW: Varied metadata scenarios
├── IntegrationTests/
│   ├── PRPreviewMetadataTests.swift                 # NEW: End-to-end metadata tests
│   └── PullRequestListTests.swift                   # MODIFY: Add metadata loading tests
├── TestDoubles/
│   └── MockGitHubAPI.swift                          # MODIFY: Add fetchPRDetails mock
└── TestHelpers.swift                                # MODIFY: Add metadata fixture helpers
```

**Structure Decision**: Feature-based organization under `Features/PullRequests/` maintains consistency with existing codebase. Preview metadata is tightly coupled to PR display, so co-locating in PullRequests feature keeps related code together. New infrastructure (metadata service, enriched API client) follows established patterns.

## Complexity Tracking

No constitutional violations. Feature adds straightforward data enrichment without introducing architectural complexity.

---

## Implementation Plan: PR-Sized Steps

### **PR #1: Data Models for Preview Metadata**

**Goal**: Create value types for preview metadata without API integration.

**User-Visible Outcome**: None (foundation work).

**Files to Create**:
- `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Models/PRPreviewMetadata.swift`
- `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Models/Reviewer.swift`
- `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Models/PRLabel.swift`

**Public Interfaces**:

```swift
struct PRPreviewMetadata: Equatable, Sendable {
    let additions: Int
    let deletions: Int
    let changedFiles: Int
    let requestedReviewers: [Reviewer]
}

struct Reviewer: Identifiable, Equatable, Sendable {
    let login: String
    let avatarURL: URL?
    var id: String { login }
}

struct PRLabel: Identifiable, Equatable, Sendable {
    let name: String
    let color: String  // 6-char hex code
    var id: String { name }
}
```

**Tests**:
- `PRPreviewMetadataTests.swift`:
  - `testInitWithValidValues`: Create metadata with typical values
  - `testInitPreconditionsForNegativeValues`: Verify preconditions catch negative counts
  - `testEqualityAndSendable`: Verify value semantics
- `ReviewerTests.swift`:
  - `testInitWithValidLogin`: Create reviewer
  - `testInitPreconditionForEmptyLogin`: Verify precondition
- `PRLabelTests.swift`:
  - `testInitWithValidColor`: Create label with 6-char hex
  - `testInitPreconditionForInvalidColor`: Verify color validation

**Acceptance Criteria**:
- [ ] All three models created with proper validation
- [ ] Models conform to Sendable (Swift 6 strict concurrency)
- [ ] All preconditions tested
- [ ] Models use value semantics (struct, Equatable)

---

### **PR #2: Extend PullRequest Model**

**Goal**: Add preview metadata fields to existing `PullRequest` struct.

**User-Visible Outcome**: None (model extension only).

**Files to Modify**:
- `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Models/PullRequest.swift`

**Changes**:
```swift
struct PullRequest: Identifiable, Equatable, Sendable {
    // Existing fields...
    
    // NEW: From Search API (always available)
    let commentCount: Int
    let labels: [PRLabel]
    
    // NEW: From PR Details API (loaded async)
    var previewMetadata: PRPreviewMetadata?
}
```

**Fixtures to Modify**:
- `prs-response.json`: Add `comments` and `labels` fields to all PR items
- `prs-with-varied-data.json`: Add varied comment counts and labels

**Tests to Update**:
- Update all existing tests that create `PullRequest` instances to include:
  - `commentCount: 0` (or appropriate value)
  - `labels: []` (or appropriate labels)
  - `previewMetadata: nil`

**Acceptance Criteria**:
- [ ] `PullRequest` model extended with new fields
- [ ] All existing tests updated and passing
- [ ] Fixtures include comment/label data
- [ ] No breaking changes to existing functionality

---

### **PR #3: GitHub API Protocol Extension**

**Goal**: Add `fetchPRDetails` method to `GitHubAPI` protocol.

**User-Visible Outcome**: None (protocol extension only).

**Files to Modify**:
- `app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/GitHubAPI.swift`
- `app/GitReviewItApp/Tests/GitReviewItAppTests/TestDoubles/MockGitHubAPI.swift`

**Protocol Extension**:
```swift
protocol GitHubAPI: Sendable {
    // Existing methods...
    
    func fetchPRDetails(
        owner: String,
        repo: String,
        number: Int,
        credentials: GitHubCredentials
    ) async throws -> PRPreviewMetadata
    
    func fetchPRReviews(
        owner: String,
        repo: String,
        number: Int,
        credentials: GitHubCredentials
    ) async throws -> [PRReviewResponse]
}
```

**Implementation Note**: `fetchPRDetails` implementation calls both:
1. `GET /repos/{owner}/{repo}/pulls/{number}` for PR details (includes `requested_reviewers`)
2. `GET /repos/{owner}/{repo}/pulls/{number}/reviews` for completed reviews
3. Merges the data in `PRDetailsResponse.toPRPreviewMetadata(reviews:)` method

**Mock Implementation**: Add mock support with configurability for both methods

**Acceptance Criteria**:
- [ ] Protocol method added with documentation
- [ ] Mock implementation complete
- [ ] No breaking changes

---

### **PR #4: API Response Decoding**

**Goal**: Create decoding structures for PR Details API response.

**Files to Create**:
- `app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/PRDetailsResponse.swift`
- `app/GitReviewItApp/Tests/GitReviewItAppTests/Fixtures/pr-details-response.json`
- `app/GitReviewItApp/Tests/GitReviewItAppTests/Fixtures/pr-details-minimal.json`
- `app/GitReviewItApp/Tests/GitReviewItAppTests/Fixtures/pr-details-large.json`

**Acceptance Criteria**:
- [ ] Response structure decodes all required fields
- [ ] Mapping to domain model correct
- [ ] All fixtures decode successfully

---

### **PR #5: Implement fetchPRDetails**

**Goal**: Implement PR Details API call in production client.

**Files to Modify**:
- `app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/GitHubAPIClient.swift`

**Acceptance Criteria**:
- [ ] Method implemented with error handling
- [ ] All success and error cases tested
- [ ] Rate limit detection works
- [ ] Enterprise GitHub supported

---

### **PR #6: Parse Comments & Labels from Search API**

**Goal**: Parse and populate comments and labels from existing Search API response fields.

**User-Visible Outcome**: Comments and labels appear immediately.

**Files to Modify**:
- `app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/GitHubAPIClient.swift`

**Acceptance Criteria**:
- [ ] Comments and labels populated from Search API
- [ ] Tests updated and passing
- [ ] Data displays correctly

---

### **PR #7: Metadata Enrichment Logic**

**Goal**: Implement async metadata enrichment.

**Files to Modify**:
- `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/State/PullRequestListContainer.swift`

**New Methods**: `enrichPreviewMetadata()`, `clearMetadataCache()`

**Acceptance Criteria**:
- [ ] Parallel enrichment works
- [ ] Individual failures isolated
- [ ] Cache prevents duplicates
- [ ] Tests verify all scenarios

---

### **PR #8: Display Preview Metadata**

**Goal**: Update UI to show preview metadata.

**User-Visible Outcome**: Metadata visible in PR list.

**Files to Modify**:
- `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PullRequestRow.swift`

**Files to Create**:
- `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PreviewMetadataView.swift`

**Acceptance Criteria**:
- [ ] Preview metadata displays correctly
- [ ] Progressive enhancement works
- [ ] Graceful degradation for missing data
- [ ] Accessibility labels present

---

### **PR #9: Integration Tests**

**Goal**: Comprehensive integration test coverage.

**Files to Create**:
- `app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/PRPreviewMetadataTests.swift`

**Acceptance Criteria**:
- [ ] All integration tests pass
- [ ] Fixtures cover edge cases
- [ ] Behavior-level verification

---

### **PR #10: Documentation & Polish**

**Goal**: Final documentation and quality checks.

**Acceptance Criteria**:
- [ ] All APIs documented
- [ ] OSLog statements added
- [ ] `just build` succeeds
- [ ] `just test` passes
- [ ] `just lint` succeeds
- [ ] Manual testing complete
