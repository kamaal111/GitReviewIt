# Feature Specification: Pull Request Preview Metadata

**Feature Branch**: `003-pr-preview-metadata`  
**Created**: December 25, 2025  
**Status**: Completed  
**Input**: User description: "Enhance each Pull Request entry with additional preview metadata so users can quickly assess review effort and context without opening the PR."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Quick Review Effort Assessment (Priority: P1)

As a developer reviewing multiple PRs, I want to see the size of changes (additions, deletions, files changed) at a glance in the PR list, so I can prioritize smaller reviews during short breaks and save larger ones for focused time blocks.

**Why this priority**: This is the most immediate value for time management. Developers commonly triage PRs by size before deciding which to review first. Change size data is typically available in standard PR list responses, making it the lowest-risk, highest-value starting point.

**Independent Test**: Can be fully tested by fetching PRs from GitHub and verifying that each list entry displays additions, deletions, and file count when available. Delivers immediate value by enabling size-based triage even without other metadata.

**Acceptance Scenarios**:

1. **Given** I am viewing the PR list, **When** a PR has change size data available, **Then** I see the number of additions, deletions, and total files changed for that PR.
2. **Given** I am viewing the PR list, **When** a PR's change size data is unavailable, **Then** I see a clear indicator that this information is not available (e.g., "—" or "N/A") rather than a blank or zero.
3. **Given** I am viewing the PR list with multiple PRs, **When** change sizes vary widely, **Then** each PR shows its correct, independent change metrics.

---

### User Story 2 - Discussion Activity Visibility (Priority: P2)

As a developer reviewing PRs, I want to see the total comment count for each PR in the list, so I can anticipate the level of discussion and potential complexity before opening the PR.

**Why this priority**: Comment counts help gauge the level of scrutiny or controversy around a PR. A PR with 50 comments likely needs more context than one with 2. This data may require additional API calls or be available in extended PR responses.

**Independent Test**: Can be fully tested by verifying that comment counts appear for PRs with discussions. Delivers value by surfacing active conversations even without other metadata fields.

**Acceptance Scenarios**:

1. **Given** I am viewing the PR list, **When** a PR has comments available, **Then** I see the total comment count displayed clearly.
2. **Given** I am viewing the PR list, **When** a PR has zero comments, **Then** I see "0" (not blank or "N/A") to distinguish from unavailable data.
3. **Given** I am viewing the PR list, **When** comment data cannot be fetched, **Then** I see an indicator that the data is unavailable, and the PR list still renders successfully.

---

### User Story 3 - Reviewer Context Awareness (Priority: P3)

As a developer managing review responsibilities, I want to see all reviewers for each PR (both those requested to review AND those who have already submitted reviews) in the list, so I can understand the full review context, see if I've already reviewed, identify if a review is shared or solely my responsibility, and coordinate accordingly.

**Why this priority**: Knowing all reviewers (not just pending requests) helps with workload distribution and coordination. GitHub's `requested_reviewers` field only contains people who haven't reviewed yet - once you submit a review, you're removed from that list. This implementation fetches both requested reviewers and completed reviews to show the complete picture.

**Independent Test**: Can be fully tested by displaying all reviewer names (requested + completed) with their review states when available. Delivers value by showing complete team coordination context even without other metadata.

**Acceptance Scenarios**:

1. **Given** I am viewing the PR list, **When** a PR has requested reviewers who haven't reviewed yet, **Then** I see their usernames/logins with a "requested" indicator.
2. **Given** I am viewing the PR list, **When** a PR has completed reviews, **Then** I see the reviewers' usernames/logins with their review state (approved, changes requested, or commented).
3. **Given** I am viewing the PR list, **When** I have submitted a review on a PR, **Then** I see myself in the reviewer list with my review state.
4. **Given** I am viewing the PR list, **When** a PR has only me as a reviewer (requested or completed), **Then** I clearly see that I am the sole reviewer.
5. **Given** I am viewing the PR list, **When** reviewer data is unavailable, **Then** I see an indicator of unavailability, and the PR list still functions.

---

### User Story 4 - Label-Based Categorization (Priority: P4)

As a developer reviewing PRs, I want to see labels/tags applied to each PR in the list, so I can quickly identify PRs by category (e.g., "bug", "feature", "urgent") without opening them.

**Why this priority**: Labels provide useful context but are often secondary to size and activity metrics for triage. Users can function effectively without labels, but they enhance categorization and prioritization.

**Independent Test**: Can be fully tested by displaying labels when present. Delivers value by showing PR categorization even without other metadata fields.

**Acceptance Scenarios**:

1. **Given** I am viewing the PR list, **When** a PR has labels applied, **Then** I see all labels displayed clearly.
2. **Given** I am viewing the PR list, **When** a PR has no labels, **Then** I see no label section (or a clear "no labels" indicator).
3. **Given** I am viewing the PR list, **When** label data is unavailable, **Then** the PR list still renders successfully without labels.

---

### Edge Cases

- What happens when GitHub API rate limits are hit while fetching preview metadata?
  - System must degrade gracefully, showing partial data and continuing to display the PR list.
  
- What happens when a PR exists but lacks permissions for certain metadata (e.g., reviewers)?
  - System must show available data and clearly indicate unavailable fields without failing.
  
- How does the system handle PRs with extremely large change counts (e.g., 10,000+ line changes)?
  - System must display these numbers accurately without truncation or overflow.
  
- What happens when comment counts include deleted comments?
  - System should reflect current total comment count as reported by GitHub's API.
  
- How does the system handle PRs with no assigned reviewers but marked as "review required"?
  - System must accurately reflect "no assigned reviewers" state.
  
- What happens when preview metadata fetching takes longer than expected?
  - System must show loading indicators for metadata while keeping PR list responsive.
  
- How does the system handle stale metadata when a PR is updated?
  - Preview metadata should reflect current state as reported by most recent API response.
  
- What happens when filtering or searching PRs with preview metadata enabled?
  - Filtering and searching must continue to work as before; metadata is purely additive to list entries.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display the number of file additions for each PR when this data is available.
- **FR-002**: System MUST display the number of file deletions for each PR when this data is available.
- **FR-003**: System MUST display the total number of files changed for each PR when this data is available.
- **FR-004**: System MUST display the total comment count for each PR as provided by GitHub API (includes both issue comments and review comments).
- **FR-005**: System MUST display the usernames/logins of all assigned reviewers for each PR when this data is available.
- **FR-006**: System MUST display all labels/tags applied to each PR when label data is available.
- **FR-007**: System MUST clearly indicate when preview metadata is unavailable (using "—", "N/A", or similar) to distinguish from zero values.
- **FR-008**: System MUST distinguish between zero values (e.g., 0 comments) and unavailable data to avoid user confusion.
- **FR-009**: System MUST continue to render the PR list successfully even when preview metadata fetching fails partially or completely.
- **FR-010**: System MUST maintain existing filtering functionality with preview metadata enabled.
- **FR-011**: System MUST maintain existing search functionality with preview metadata enabled.
- **FR-012**: System MUST maintain existing sorting functionality with preview metadata enabled.
- **FR-013**: System MUST handle data source limitations gracefully, showing partial preview data when full metadata cannot be retrieved.
- **FR-014**: System MUST handle permission restrictions gracefully, displaying available preview data and indicating unavailable fields without failing.
- **FR-015**: System MUST accurately display large change counts (10,000+ lines) without truncation or display issues.
- **FR-016**: System MUST show loading indicators for preview metadata while keeping the PR list responsive and interactive.
- **FR-017**: System MUST fetch preview metadata efficiently to avoid significantly degrading PR list responsiveness.
- **FR-018**: System MUST make preview metadata accessible to assistive technologies (screen readers, etc.).

### Dependencies and Assumptions

- **Assumption**: Change size data (additions, deletions, files changed) is retrievable for each PR from the data source.
- **Assumption**: Comment count data is retrievable or calculable for each PR.
- **Assumption**: Reviewer assignment information is retrievable for each PR.
- **Assumption**: Label/tag data is retrievable for each PR.
- **Dependency**: The feature depends on maintaining access to PR data from the remote data source.
- **Dependency**: The feature relies on the data source providing consistent metadata formats.
- **Assumption**: Users have appropriate read permissions for the repositories they are reviewing.
- **Assumption**: Preview metadata freshness matches the PR list refresh cycle (no separate real-time updates needed).

### Key Entities *(include if feature involves data)*

- **Pull Request Preview Metadata**: Supplementary information displayed for each PR in the list view, including:
  - Change size data (additions, deletions, files changed)
  - Discussion activity (total comment count)
  - Review context (assigned reviewer names/logins, review request states)
  - Categorization (labels/tags)
  - Data availability indicators (to distinguish unavailable from zero values)

- **Data Availability State**: The status of each metadata field, indicating whether data is:
  - Available and populated
  - Available but zero/empty
  - Unavailable due to API limitations
  - Unavailable due to permission restrictions
  - Loading/fetching in progress
  - Failed to fetch

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can identify the size of changes (additions, deletions, files) for any PR in the list without opening the PR detail view.
- **SC-002**: Users can identify the level of discussion activity (comment count) for any PR in the list without opening the PR.
- **SC-003**: Users can identify assigned reviewers for any PR in the list without opening the PR detail view.
- **SC-004**: Users can identify categorization labels for any PR in the list without opening the PR.
- **SC-005**: Users can view PR lists with up to 50 entries and access preview metadata within 3 seconds of opening the list.
- **SC-006**: Users can interact with the PR list (scroll, click, filter) immediately while preview metadata loads in the background.
- **SC-007**: When individual metadata fields fail to load, users can still see other available preview data and the complete PR list.
- **SC-008**: Users can distinguish between zero values (e.g., "0 comments") and unavailable data (e.g., "—") in 100% of cases.
- **SC-009**: Existing filtering, search, and sorting functionality continues to work without degradation when preview metadata is enabled.
- **SC-010**: Users can view 50 PRs with preview metadata per hour without encountering data retrieval errors under normal usage conditions.
- **SC-011**: All preview metadata text and values are accessible to screen readers and other assistive technologies.
- **SC-012**: Users can assess whether a PR requires immediate review based on preview metadata alone in 80% of triage decisions.

