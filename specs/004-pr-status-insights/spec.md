# Feature Specification: PR Status Insights

**Feature Branch**: `004-pr-status-insights`
**Created**: 2025-12-25
**Status**: Completed
**Input**: User description: "Enhance PR list with status insights"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View PR Draft Status (Priority: P1)

As a reviewer, I want to see if a PR is in "Draft" state directly in the list, so I can prioritize review-ready PRs over works-in-progress.

**Why this priority**: Draft PRs often don't require immediate attention. Distinguishing them saves time.

**Independent Test**: Can be tested by creating a draft PR and a ready PR and verifying the UI distinction.

**Acceptance Scenarios**:

1. **Given** a list of PRs containing a Draft PR, **When** I view the list, **Then** the Draft PR is clearly labeled as "Draft".
2. **Given** a list of PRs containing a Ready PR, **When** I view the list, **Then** the Ready PR is NOT labeled as "Draft".

---

### User Story 2 - View CI/Checks Summary (Priority: P1)

As a reviewer, I want to see a summary of CI/Check statuses (Passing, Failing, Pending) in the PR list, so I can avoid reviewing PRs that are already broken.

**Why this priority**: Reviewing code that fails tests is often a waste of time.

**Independent Test**: Can be tested by mocking PRs with different check statuses.

**Acceptance Scenarios**:

1. **Given** a PR with all checks passing, **When** I view the list, **Then** the PR shows a "Passing" status indicator.
2. **Given** a PR with at least one failing check, **When** I view the list, **Then** the PR shows a "Failing" status indicator.
3. **Given** a PR with pending/running checks, **When** I view the list, **Then** the PR shows a "Pending" status indicator.
4. **Given** a PR where check status cannot be determined, **When** I view the list, **Then** the PR shows an "Unknown" status indicator.

---

### User Story 3 - View Mergeability Status (Priority: P1)

As a reviewer, I want to see if a PR has merge conflicts, so I can ask the author to resolve them before I review.

**Why this priority**: Merge conflicts can invalidate the code being reviewed.

**Independent Test**: Can be tested by mocking PRs with and without conflicts.

**Acceptance Scenarios**:

1. **Given** a PR with no merge conflicts, **When** I view the list, **Then** the PR shows a "Mergeable" or "Clean" indicator.
2. **Given** a PR with merge conflicts, **When** I view the list, **Then** the PR shows a "Conflicts" indicator.
3. **Given** a PR where mergeability is unknown, **When** I view the list, **Then** the PR shows an "Unknown" indicator.

---

### User Story 4 - Graceful Degradation (Priority: P2)

As a user, I want the PR list to load and function even if status insights fail to load, so I can still perform my work.

**Why this priority**: Reliability is key; a secondary feature shouldn't break the primary feature.

**Independent Test**: Can be tested by simulating network errors for the status insight requests while keeping the main PR fetch successful.

**Acceptance Scenarios**:

1. **Given** the status insight API calls fail, **When** I view the PR list, **Then** the list still displays the PRs.
2. **Given** the status insight API calls fail, **When** I view the PR list, **Then** the status indicators show "Unknown" or a neutral state.

### Edge Cases

- **Rate Limiting**: If fetching status for many PRs triggers rate limits, the app should handle this gracefully (e.g., show "Unknown" status) and not crash or block.
- **No Checks**: A PR might have no CI checks configured. This should be distinguished from "Unknown" if possible, or treated as "Passing" or "Neutral".
- **Mixed States**: A PR might be Draft AND have Failing checks. The UI should ideally show both or prioritize the most important signal.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display a visual indicator for "Draft" PRs.
- **FR-002**: System MUST display a summarized CI/Check status for each PR (Passing, Failing, Pending, Unknown).
- **FR-003**: System MUST display a mergeability signal for each PR (Clean, Conflicts, Unknown).
- **FR-004**: System MUST derive status insights from authoritative GitHub data.
- **FR-005**: System MUST NOT block the display of the PR list if status data is unavailable.
- **FR-006**: System MUST maintain existing filtering and fuzzy search capabilities.
- **FR-007**: System MUST handle "Unknown" states explicitly for both Checks and Mergeability.

### Non-Functional Requirements

- **NFR-001**: **Performance**: The PR list must remain responsive. Fetching status insights should ideally happen in parallel or be optimized to not significantly delay the initial list render.
- **NFR-002**: **Accessibility**: Status indicators must have VoiceOver labels (e.g., "Build Failing", "Merge Conflicts").
- **NFR-003**: **Reliability**: Partial failures in data fetching must be handled gracefully.

### Key Entities

- **PRStatus**: A composite object or struct containing:
    - `isDraft`: Boolean
    - `checkStatus`: Enum (passing, failing, pending, unknown)
    - `mergeStatus`: Enum (clean, conflicts, unknown)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can correctly identify Draft PRs in the list 100% of the time.
- **SC-002**: Users can correctly identify PRs with failing checks in the list 100% of the time.
- **SC-003**: Users can correctly identify PRs with merge conflicts in the list 100% of the time.
- **SC-004**: The PR list loads and displays content even if status fetching fails.

## Assumptions *(optional)*

- GitHub API provides the necessary fields (e.g., `mergeable`, `mergeable_state`, `commits` status) to derive these insights.
- The current authentication token has sufficient permissions (scopes) to read these statuses for the repositories the user has access to.
- We are using the existing networking infrastructure of the app.
