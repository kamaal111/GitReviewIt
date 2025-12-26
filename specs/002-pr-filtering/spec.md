# Feature Specification: PR Filtering

**Feature Branch**: `002-pr-filtering`  
**Created**: December 23, 2025  
**Status**: Completed  
**Input**: User description: "Add filtering capabilities to the PR list experience: fuzzy search over PRs, persistent structured filters by organization, repository, and team"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fuzzy Search PRs (Priority: P1)

As a user reviewing multiple PRs, I want to quickly find specific PRs by typing parts of the title, repository name, or author name, so that I can locate relevant PRs without scrolling through the entire list.

**Why this priority**: Searching is the most immediate need for users with many PRs. It provides instant value and reduces the time to find a specific PR from minutes to seconds.

**Independent Test**: Can be fully tested by entering various search queries and verifying that matching PRs appear in ranked order based on match quality. Delivers immediate value even without structured filters.

**Acceptance Scenarios**:

1. **Given** I have 50 PRs in my list, **When** I type "fix bug" in the search box, **Then** all PRs with "fix" or "bug" in their title appear, ranked by match quality
2. **Given** I have PRs from multiple repositories, **When** I type "api-service", **Then** PRs from repositories containing "api-service" appear at the top
3. **Given** I search for "john", **When** PRs authored by "johnsmith" exist, **Then** those PRs appear ranked by how well "john" matches the author name
4. **Given** I have a search query entered, **When** I clear the search box, **Then** all PRs reappear immediately
5. **Given** I have entered a search query, **When** I close and reopen the app, **Then** the search box is empty and all PRs are visible
6. **Given** I search for text that matches no PRs, **When** viewing the results, **Then** I see a clear message indicating "No PRs match your search" (not "No PRs available")

---

### User Story 2 - Filter by Organization and Repository (Priority: P2)

As a user who reviews PRs across multiple organizations and repositories, I want to filter PRs by organization or repository, so that I can focus on work from specific teams or projects without distractions.

**Why this priority**: Organization and repository filters provide essential segmentation for users working across multiple projects. These filters use data already available in the PR list (no additional API calls).

**Independent Test**: Can be fully tested by selecting organization or repository filters and verifying that only matching PRs appear. Persists across app restarts, demonstrating data retention without requiring team filtering.

**Acceptance Scenarios**:

1. **Given** I have PRs from organizations "CompanyA" and "CompanyB", **When** I select "CompanyA" from the organization filter, **Then** only PRs from "CompanyA" are visible
2. **Given** I have PRs from repositories "app-frontend" and "api-backend", **When** I select "app-frontend" from the repository filter, **Then** only PRs from "app-frontend" are visible
3. **Given** I have selected organization "CompanyA" and repository "api-backend", **When** both filters are active, **Then** only PRs from "CompanyA/api-backend" are visible
4. **Given** I have active organization and repository filters, **When** I close and reopen the app, **Then** my filters are still active and the filtered PR list appears
5. **Given** I have filtered PRs by repository, **When** I clear the repository filter, **Then** all PRs (or PRs matching remaining filters) reappear
6. **Given** all PRs are filtered out by my current selections, **When** viewing the empty list, **Then** I see "No PRs match your current filters" with an option to clear filters

---

### User Story 3 - Filter by Team (Priority: P3)

As a user who works with GitHub teams, I want to filter PRs by the team responsible for the repository, so that I can focus on reviews relevant to specific team boundaries or responsibilities.

**Why this priority**: Team filtering adds organizational flexibility but depends on GitHub API permissions and may not be available to all users. It's valuable but not essential for core filtering functionality.

**Independent Test**: Can be fully tested by selecting team filters (when available) and verifying correct filtering. Also tests graceful degradation when team data is unavailable due to permissions or API limitations.

**Acceptance Scenarios**:

1. **Given** I have PRs from repositories owned by teams "Backend Team" and "Frontend Team", **When** I select "Backend Team" from the team filter, **Then** only PRs from repositories owned by "Backend Team" are visible
2. **Given** team filtering is available, **When** I combine team filters with organization or repository filters, **Then** only PRs matching all active filters appear
3. **Given** I do not have permissions to access team information, **When** I view the filter options, **Then** the team filter is clearly marked as unavailable with an explanation (e.g., "Team filtering unavailable - requires additional permissions")
4. **Given** the GitHub API fails to return team information, **When** I view the filter options, **Then** the team filter shows an error state but other filters remain functional
5. **Given** team filtering is unavailable, **When** I use organization and repository filters, **Then** those filters continue to work correctly
6. **Given** I have selected a team filter and saved it, **When** I relaunch the app and team data is no longer available, **Then** the team filter is automatically cleared and I see a notice explaining why

---

### User Story 4 - Combine Search and Filters (Priority: P2)

As a power user, I want to combine fuzzy search with structured filters, so that I can narrow down PRs using both free-text search and specific organizational boundaries.

**Why this priority**: Combining search and filters is a natural extension once both features exist. It multiplies the value of each feature and supports complex workflows.

**Independent Test**: Can be fully tested by applying search queries along with organization, repository, or team filters, and verifying that both are applied correctly (intersection of results).

**Acceptance Scenarios**:

1. **Given** I have filtered PRs by organization "CompanyA", **When** I enter "bug fix" in the search box, **Then** only PRs from "CompanyA" matching "bug fix" appear
2. **Given** I have a search query "api" and repository filter "backend-service", **When** both are active, **Then** I see PRs from "backend-service" that match "api"
3. **Given** I have multiple filters and a search query active, **When** I clear the search query, **Then** the structured filters remain active
4. **Given** I have multiple filters and a search query active, **When** I clear all filters, **Then** the search query remains active and filters all PRs
5. **Given** search and filters result in zero PRs, **When** viewing the empty list, **Then** I see "No PRs match your search and filters" with options to adjust both

---

### Edge Cases

- What happens when a PR's organization, repository, or team information is missing or malformed?
  - System must treat missing data as "unknown" and allow filtering by "unknown" category
- What happens when the user applies filters that exclude all PRs?
  - System must clearly indicate "No PRs match your filters" and offer to clear filters
- What happens when the user searches for an empty string or only whitespace?
  - System must treat it as "no search" and show all PRs (respecting active filters)
- What happens when two PRs have identical match scores for a search query?
  - System must apply deterministic tie-breaking (e.g., by PR number, creation date, or alphabetically by title)
- What happens when the user is offline and tries to use filters?
  - Filters must continue to work on the locally available PR dataset
- What happens when new PRs are fetched while filters are active?
  - System must automatically apply active filters to newly fetched PRs
- What happens when persisted filters reference teams that no longer exist?
  - System must handle gracefully by clearing invalid team filters and notifying the user
- What happens when the user has hundreds of PRs and searches/filters?
  - System must remain responsive (results displayed within 500ms for typical volumes)

## Requirements *(mandatory)*

### Functional Requirements

#### Fuzzy Search

- **FR-001**: System MUST provide a search input that filters PRs using fuzzy matching
- **FR-002**: Fuzzy matching MUST consider at minimum: PR title, repository name or full identifier (org/repo), and PR author login
- **FR-003**: Search results MUST be ranked by match quality with deterministic tie-breaking rules
- **FR-004**: Search query MUST NOT persist across app launches (transient state only)
- **FR-005**: Search query MUST reset when the app is relaunched
- **FR-006**: Search MUST provide instant feedback as the user types (no explicit "search" button required)
- **FR-007**: Search MUST operate on the locally available PR dataset (no additional network requests)

#### Structured Filters

- **FR-008**: System MUST allow users to filter PRs by organization
- **FR-009**: System MUST allow users to filter PRs by repository
- **FR-010**: System MUST allow users to filter PRs by team (when team data is available)
- **FR-011**: Multiple filters MUST be combinable (e.g., organization AND repository AND team)
- **FR-012**: Structured filter selections MUST persist across app launches
- **FR-013**: On app relaunch, persisted filters MUST be automatically reapplied to the PR list
- **FR-014**: Users MUST be able to clear individual filters independently
- **FR-015**: Users MUST be able to reset all filters to the default unfiltered state with a single action
- **FR-016**: Filters MUST operate on the locally available PR dataset (no additional network requests for filtering)

#### Search and Filter Combination

- **FR-017**: Search and structured filters MUST be combinable (intersection of results)
- **FR-018**: Clearing search MUST NOT affect structured filters
- **FR-019**: Clearing structured filters MUST NOT affect the active search query
- **FR-020**: When both search and filters are active, both MUST be applied to produce the final result set

#### State and Feedback

- **FR-021**: System MUST clearly distinguish "No PRs available" from "No PRs match your current filters/search"
- **FR-022**: When filters exclude all PRs, system MUST display a message indicating the reason and offer to clear filters
- **FR-023**: When search produces no results, system MUST display a message indicating "No PRs match your search"
- **FR-024**: When team filtering is unavailable (permissions or API failure), system MUST clearly communicate this state to the user
- **FR-025**: When team filtering is unavailable, organization and repository filters MUST continue to function correctly

#### Offline and Data Availability

- **FR-026**: All filtering operations MUST function when offline, using previously loaded PR data
- **FR-027**: When new PRs are fetched, active filters MUST be automatically applied to the updated dataset
- **FR-028**: System MUST handle missing or malformed organization, repository, or team data gracefully

#### Performance and Determinism

- **FR-029**: Filtering (search + structured filters) MUST remain responsive for typical PR volumes (hundreds of PRs)
- **FR-030**: Response time for applying filters MUST be under 500ms for datasets up to 500 PRs
- **FR-031**: Identical input (PR dataset + filters + search) MUST produce identical results every time (deterministic)

### Key Entities

- **Filter Configuration**: Represents the user's active filter selections (organization, repository, team). Persisted across app launches. Includes:
  - Selected organizations (zero or more)
  - Selected repositories (zero or more)
  - Selected teams (zero or more, may be unavailable)
  - Does NOT include the search query (transient)

- **Search Query**: Represents the user's current search text. Transient (not persisted). Applied in combination with structured filters.

- **Filtered PR List**: The result of applying the active search query and filter configuration to the available PR dataset. Dynamically computed, not stored.

- **Team Metadata**: Information about GitHub teams associated with repositories. May be unavailable due to permissions or API limitations. Sourced from GitHub API when accessible.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can locate a specific PR using search within 10 seconds, down from an average of 60+ seconds of manual scrolling
- **SC-002**: Filtering operations (search + structured filters) complete within 500ms for datasets containing up to 500 PRs
- **SC-003**: 90% of users successfully apply and persist at least one structured filter within their first session using the feature
- **SC-004**: Filter persistence works reliably across app launches with zero reported data loss incidents
- **SC-005**: System handles team filtering unavailability gracefully with zero crashes or functional degradation of other filters
- **SC-006**: Search ranking is deterministic: identical queries on identical datasets produce identical result ordering 100% of the time
- **SC-007**: Users can combine search with multiple structured filters, with all combinations functioning correctly and producing expected results
- **SC-008**: Offline filtering operates successfully on locally cached PR data without network connectivity
## Context & Background

### Current State

The GitReviewIt app currently provides:
- Native OAuth authentication with GitHub
- Secure token storage and reuse
- PR list fetching using GitHub's public API
- Display of PRs requiring the user's review
- Loading, error, and empty state handling
- No backend dependency (direct API calls from the app)

### Motivation

Users with active review responsibilities often manage dozens or hundreds of PRs across multiple organizations, repositories, and teams. Without filtering capabilities, finding relevant PRs requires extensive manual scrolling and mental filtering. This feature addresses that pain point by providing:

1. **Fuzzy search** for immediate, ad-hoc filtering by any PR attribute
2. **Structured filters** for persistent, repeatable workflows (e.g., "always show me PRs from CompanyA's backend-service repository")
3. **Offline support** ensuring filters work even without network connectivity

### Constraints

- Filtering operates on the locally available PR dataset; the existing PR fetch behavior is unchanged for this milestone
- Team-based filtering depends on GitHub API permissions and must degrade gracefully if unavailable
- Architecture and testing conventions must be respected (see AGENTS.md)
- No backend services; all operations remain client-side

## Assumptions

- GitHub API provides sufficient metadata in PR responses to extract organization and repository information
- Team information can be fetched from GitHub's Teams API when permissions allow
- Typical PR volumes are in the range of 10-500 PRs per user
- Users expect filters to persist across app launches (standard behavior for user preferences)
- Search queries are typically short (1-3 words) and do not require complex query syntax
- Match quality for fuzzy search can be determined using standard string similarity algorithms (e.g., Levenshtein distance, prefix matching)
- Users understand the distinction between transient search and persistent filters
- Offline operation is valuable because users may review PRs in low-connectivity environments or want instant filtering without network delays

## Dependencies

### GitHub API Capabilities

- **PR Metadata**: Organization and repository information must be available in PR list responses (already provided by current GitHub API)
- **Teams API**: Optional access to GitHub Teams API for team-based filtering
  - Requires `read:org` OAuth scope for organization team information
  - May fail due to insufficient permissions or API rate limits
  - Must gracefully degrade when unavailable

### OAuth Scopes

- **Current scopes**: Assumed to include `repo` (for PR access) and basic user information
- **Additional scope for team filtering**: `read:org` (to access organization team memberships)
  - If this scope is not granted, team filtering is unavailable
  - Users should be informed that granting `read:org` enables team filtering

### Fallback Behavior

- If `read:org` is not granted: Team filter is hidden or marked as unavailable with an explanation
- If Teams API fails or returns errors: Team filter shows error state; other filters remain functional
- If team metadata is missing for some repositories: Those repositories are categorized as "Unknown team" or filtered out of team-based results

## Out of Scope

The following are explicitly out of scope for this feature:

- Changing the PR fetch behavior or API endpoints used
- Adding new PR metadata beyond what is currently available (e.g., PR labels, reviewers)
- Advanced search syntax (e.g., boolean operators, field-specific queries like `author:john`)
- Saved filter presets or named filter configurations (e.g., "Work PRs", "Personal PRs")
- Filter sharing between devices or users
- Sorting PRs by arbitrary fields (sorting is addressed by search ranking only)
- Filtering by PR state (open/closed/merged) - out of scope since the app only shows PRs requiring review
- Server-side filtering or search (all operations are client-side)
- Exporting or sharing filtered PR lists

## Risks & Mitigations

### Risk: Team API Permissions

**Risk**: Users may not have `read:org` permissions, making team filtering unavailable.

**Mitigation**:
- Design team filtering as optional from the start
- Provide clear messaging when team filtering is unavailable
- Ensure organization and repository filters work independently of team data
- Consider a feature flag or user setting to request `read:org` scope if desired

### Risk: Performance Degradation with Large Datasets

**Risk**: Filtering and search may become slow with very large PR datasets (1000+ PRs).

**Mitigation**:
- Optimize fuzzy search algorithms for performance (e.g., indexed search, early termination)
- Use efficient filtering techniques (e.g., set intersection, pre-computed indices)
- Test with realistic large datasets during development
- Monitor performance metrics and optimize as needed

### Risk: Filter Persistence Corruption

**Risk**: Persisted filter data could become corrupted or incompatible with future app versions.

**Mitigation**:
- Use versioned data schemas for persistence
- Implement validation and migration logic for persisted filters
- Provide a "reset to defaults" option to recover from corruption
- Log errors to help diagnose and fix persistence issues

### Risk: Search Ranking Subjectivity

**Risk**: Users may disagree with search result rankings or find them unpredictable.

**Mitigation**:
- Use well-established fuzzy matching algorithms with clear, documented ranking rules
- Ensure deterministic tie-breaking so results are predictable
- Collect user feedback and iterate on ranking logic if needed
- Consider surfacing ranking scores or match highlights in the UI (out of scope for this spec, but noted for future)

## Testing Strategy

Testing must focus on behavior, not implementation details. Prefer integration-style tests that validate end-to-end functionality. Only network boundaries may be mocked or stubbed.

### Key Test Areas

1. **Fuzzy Search Correctness**
   - Verify that PRs matching search terms appear in results
   - Verify ranking order is correct for various search queries
   - Verify tie-breaking is deterministic
   - Verify search does not persist across app launches

2. **Structured Filter Correctness**
   - Verify organization filter includes/excludes correct PRs
   - Verify repository filter includes/excludes correct PRs
   - Verify team filter includes/excludes correct PRs (when available)
   - Verify filters persist across app launches
   - Verify filters are reapplied correctly after relaunch

3. **Search + Filter Combination**
   - Verify search and filters apply together correctly (intersection)
   - Verify clearing search does not affect filters
   - Verify clearing filters does not affect search
   - Verify multiple filters combine correctly

4. **Graceful Degradation**
   - Verify team filter unavailability is handled gracefully
   - Verify other filters work when team filtering is unavailable
   - Verify persisted team filters are cleared if teams become unavailable

5. **State Communication**
   - Verify "No PRs match your filters" message when filters exclude all PRs
   - Verify "No PRs match your search" message when search produces no results
   - Verify "Team filtering unavailable" message when team data is inaccessible

6. **Offline Operation**
   - Verify all filtering works offline with cached PR data
   - Verify new PRs are filtered correctly when fetched

7. **Performance**
   - Verify filtering completes within 500ms for datasets of 500 PRs
   - Verify filtering remains responsive for typical user interactions

### Test Data

- Use fixture data representing realistic PR datasets (varying organizations, repositories, teams, authors, titles)
- Include edge cases: missing data, malformed data, empty results
- Use datasets of varying sizes (10 PRs, 100 PRs, 500 PRs) to validate performance

### Mocking Strategy

- Mock only the network layer (GitHub API responses)
- Do not mock filtering, search, or persistence logic
- Use real instances of view models, services, and state management