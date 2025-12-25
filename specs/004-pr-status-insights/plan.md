# Implementation Plan: PR Status Insights

**Branch**: `004-pr-status-insights` | **Date**: 2025-12-25 | **Spec**: [specs/004-pr-status-insights/spec.md](specs/004-pr-status-insights/spec.md)
**Input**: Feature specification from `/specs/004-pr-status-insights/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Enhance the PR list with "quick context" status insights: Draft status, Mergeability (clean/conflicts), and CI/Checks summary (passing/failing/pending). This will be implemented using existing GitHub REST APIs, leveraging the Search API for draft status and parallelizing check run fetches with existing detail fetches.

## Technical Context

**Language/Version**: Swift 6.0
**UI Framework**: SwiftUI (Observation)
**Primary Dependencies**: None (stdlib only)
**Storage**: N/A
**Testing**: Swift Testing
**Target Platform**: macOS 15+
**Architecture**: Unidirectional data flow
**Deployment Target**: macOS 14.0
**Performance Goals**: Responsive scrolling, parallel network requests
**Constraints**: SwiftUI-only, no backend
**Scale/Scope**: PR list items

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

## Project Structure

### Documentation (this feature)

```text
specs/004-pr-status-insights/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
```

### Source Code (repository root)

```text
app/GitReviewItApp/Sources/GitReviewItApp/
├── Features/
│   └── PullRequests/
│       ├── Views/
│       │   └── PullRequestRow.swift
│       ├── Models/
│       │   ├── PullRequest.swift
│       │   └── PRPreviewMetadata.swift
│       └── State/
│           └── PullRequestListContainer.swift
└── Infrastructure/
    └── Networking/
        ├── GitHubAPI.swift
        ├── PRDetailsResponse.swift
        └── CheckRunsResponse.swift (New)
```

**Structure Decision**: Feature-based organization within the existing `PullRequests` feature. Networking models live in `Infrastructure/Networking` as they map directly to API responses.

## Phase 0: Research

See `research.md` for details on API strategy and trade-offs.

## Phase 1: Design

See `data-model.md` for entity definitions.

## Phase 2: Implementation Steps

### Step 1: Draft Status (Search API)

**Goal**: Show "Draft" badge on PRs immediately upon list load.

1.  **Models**:
    - Update `PullRequest` struct: add `let isDraft: Bool`.
    - Update `SearchIssueItem` (private in `GitHubAPI.swift`): add `let draft: Bool?`.
2.  **Networking**:
    - Update `GitHubAPIClient.mapSearchIssueToPullRequest`: map `draft` to `isDraft` (default to `false`).
3.  **UI**:
    - Update `PullRequestRow`: Add "Draft" badge/icon.
    - Ensure accessibility label includes "Draft".
4.  **Tests**:
    - Update `MockGitHubAPI` to support draft status.
    - Add integration test: `Draft PRs are correctly marked`.

### Step 2: Mergeability (PR Details API)

**Goal**: Show "Merge Conflict" or "Clean" status after details load.

1.  **Models**:
    - Create `PRMergeStatus` enum (clean, conflicts, unknown).
    - Update `PRPreviewMetadata`: add `let mergeStatus: PRMergeStatus`.
    - Update `PRDetailsResponse`: add `mergeable: Bool?`, `mergeable_state: String`.
2.  **Networking**:
    - Update `PRDetailsResponse.toPRPreviewMetadata`: Map `mergeable` fields to `PRMergeStatus`.
        - `mergeable == true` -> `.clean`
        - `mergeable == false` -> `.conflicts`
        - `mergeable == nil` -> `.unknown`
3.  **UI**:
    - Update `PullRequestRow`: Show merge status indicator (e.g., checkmark or warning icon).
    - Handle "Unknown" state (show nothing or specific icon).
4.  **Tests**:
    - Integration test: `Mergeable PRs show clean status`.
    - Integration test: `Conflicting PRs show conflict status`.

### Step 3: Check Runs Networking

**Goal**: Fetch CI status from GitHub.

1.  **Models**:
    - Create `CheckRunsResponse` struct (decodes `total_count`, `check_runs` list).
    - Create `PRCheckStatus` enum (passing, failing, pending, unknown).
2.  **Networking**:
    - Add `fetchCheckRuns(owner:repo:ref:credentials:)` to `GitHubAPI` protocol and client.
    - Endpoint: `GET /repos/{owner}/{repo}/commits/{ref}/check-runs`.
3.  **Tests**:
    - Unit test `fetchCheckRuns` with mocked HTTP response.

### Step 4: Check Status Integration

**Goal**: Show CI status (Passing/Failing) in PR list.

1.  **Models**:
    - Update `PRPreviewMetadata`: add `let checkStatus: PRCheckStatus`.
    - Update `PRDetailsResponse`: add `head: Head` (to get SHA).
2.  **Networking**:
    - Update `GitHubAPIClient.fetchPRDetails`:
        - Extract `head.sha` from details response.
        - Call `fetchCheckRuns` in parallel with `fetchPRReviews`.
        - Aggregate check runs into `PRCheckStatus`.
            - Any `failure`, `timed_out`, `action_required` -> `.failing`
            - Any `in_progress`, `queued` -> `.pending`
            - All `success` -> `.passing`
            - Empty -> `.unknown` (or `.passing` if we assume no checks = good, but `.unknown` is safer).
3.  **UI**:
    - Update `PullRequestRow`: Show CI status icon/color.
4.  **Tests**:
    - Integration test: `PR with failing checks shows failure`.
    - Integration test: `PR with passing checks shows success`.

### Step 5: Polish & Accessibility

**Goal**: Ensure high quality user experience.

1.  **UI**:
    - Refine icons and colors for dark/light mode.
    - Verify VoiceOver labels ("Draft", "Merge Conflicts", "Checks Failing").
2.  **Edge Cases**:
    - Handle rate limits (graceful degradation to `.unknown`).
    - Handle large number of check runs (pagination? For now, just take first page summary).

## Acceptance Criteria

- [ ] Draft PRs are clearly visible in the list.
- [ ] PRs with merge conflicts are flagged.
- [ ] PRs with failing CI are flagged.
- [ ] PR list loads even if status checks fail (graceful degradation).
- [ ] Accessibility labels are correct.
- [ ] No regression in list scrolling performance.
