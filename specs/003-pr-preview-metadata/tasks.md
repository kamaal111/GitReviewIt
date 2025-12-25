# Tasks: Pull Request Preview Metadata

**Input**: Design documents from `/specs/003-pr-preview-metadata/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/protocols.md  
**Branch**: 003-pr-preview-metadata

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

All foundational models and infrastructure that multiple user stories depend on.

- [X] T001 [P] Create PRLabel model (value type with validation) in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Models/PRLabel.swift
- [X] T002 [P] Create Reviewer model (value type with validation) in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Models/Reviewer.swift
- [X] T003 [P] Create PRPreviewMetadata model (container for async metadata) in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Models/PRPreviewMetadata.swift
- [X] T004 [P] Add unit tests for PRLabel validation in app/GitReviewItApp/Tests/GitReviewItAppTests/UnitTests/PRLabelTests.swift
- [X] T005 [P] Add unit tests for Reviewer validation in app/GitReviewItApp/Tests/GitReviewItAppTests/UnitTests/ReviewerTests.swift
- [X] T006 [P] Add unit tests for PRPreviewMetadata invariants in app/GitReviewItApp/Tests/GitReviewItAppTests/UnitTests/PRPreviewMetadataTests.swift

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T007 Extend PullRequest model with commentCount, labels, and previewMetadata fields in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Models/PullRequest.swift
- [X] T008 [P] Create PRDetailsResponse decoding structure in app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/PRDetailsResponse.swift
- [X] T009 [P] Add fetchPRDetails method to GitHubAPI protocol in app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/GitHubAPI.swift
- [X] T010 [P] Add fixture pr-details-response.json to app/GitReviewItApp/Tests/GitReviewItAppTests/Fixtures/pr-details-response.json
- [X] T011 [P] Add fixture pr-details-minimal.json to app/GitReviewItApp/Tests/GitReviewItAppTests/Fixtures/pr-details-minimal.json
- [X] T012 [P] Add fixture pr-details-large.json (edge case: large PR) to app/GitReviewItApp/Tests/GitReviewItAppTests/Fixtures/pr-details-large.json
- [X] T013 [P] Update existing prs-response.json fixture to include comments and labels fields in app/GitReviewItApp/Tests/GitReviewItAppTests/Fixtures/prs-response.json
- [X] T014 [P] Update existing prs-with-varied-data.json fixture with varied comments/labels in app/GitReviewItApp/Tests/GitReviewItAppTests/Fixtures/prs-with-varied-data.json
- [X] T015 Implement fetchPRDetails in GitHubAPIClient with error handling and rate limit detection in app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/GitHubAPIClient.swift
- [X] T016 [P] Update MockGitHubAPI with fetchPRDetails mock implementation in app/GitReviewItApp/Tests/GitReviewItAppTests/TestDoubles/MockGitHubAPI.swift
- [X] T017 [P] Add TestHelpers method for loading PR details fixtures in app/GitReviewItApp/Tests/GitReviewItAppTests/TestHelpers.swift
- [X] T018 Update Search API response mapping to populate commentCount and labels in app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/GitHubAPIClient.swift
- [X] T019 Update all existing tests that create PullRequest instances to include new fields in app/GitReviewItApp/Tests/GitReviewItAppTests/UnitTests/PullRequestListTests.swift

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Quick Review Effort Assessment (Priority: P1) 🎯 MVP

**Goal**: Display change size data (additions, deletions, files changed) for each PR so developers can prioritize reviews by size

**Independent Test**: Fetch PRs from GitHub and verify that each list entry displays additions, deletions, and file count when available

### Implementation for User Story 1

- [X] T020 [US1] Add enrichPreviewMetadata method to PullRequestListContainer for parallel metadata fetching in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/State/PullRequestListContainer.swift
- [X] T021 [US1] Add metadata caching logic (metadataCache dictionary by PR ID) in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/State/PullRequestListContainer.swift
- [X] T022 [US1] Add clearMetadataCache method and integrate with loadPullRequests in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/State/PullRequestListContainer.swift
- [X] T023 [P] [US1] Create PreviewMetadataView SwiftUI component for displaying change stats in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PreviewMetadataView.swift
- [X] T024 [US1] Update PullRequestRow to display change size preview (additions/deletions/changed files) in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PullRequestRow.swift
- [X] T025 [P] [US1] Add integration test for metadata enrichment workflow in app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/PRPreviewMetadataTests.swift
- [X] T026 [P] [US1] Add unit tests for enrichPreviewMetadata success/failure scenarios in app/GitReviewItApp/Tests/GitReviewItAppTests/UnitTests/PullRequestListTests.swift
- [X] T027 [US1] Add graceful handling for unavailable change stats (display "—" when previewMetadata is nil) in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PreviewMetadataView.swift
- [X] T028 [P] [US1] Add accessibility labels for change size data (VoiceOver support) in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PreviewMetadataView.swift
- [X] T029 [P] [US1] Add OSLog statements for metadata enrichment operations in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/State/PullRequestListContainer.swift

**Checkpoint**: User Story 1 complete - change size data visible in PR list, independently testable

---

## Phase 4: User Story 2 - Discussion Activity Visibility (Priority: P2)

**Goal**: Display total comment count for each PR so developers can anticipate discussion complexity

**Independent Test**: Verify that comment counts appear for PRs with discussions and "0" appears for PRs with no comments

### Implementation for User Story 2

- [X] T030 [P] [US2] Update PreviewMetadataView to display comment count in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PreviewMetadataView.swift
- [X] T031 [P] [US2] Add logic to distinguish zero comments from unavailable data in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PreviewMetadataView.swift
- [X] T032 [P] [US2] Add accessibility label for comment count (VoiceOver support) in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PreviewMetadataView.swift
- [X] T033 [P] [US2] Add unit tests for comment count display (zero vs unavailable) in app/GitReviewItApp/Tests/GitReviewItAppTests/UnitTests/PreviewMetadataViewTests.swift
- [X] T034 [P] [US2] Add integration test verifying comment counts from Search API in app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/PRPreviewMetadataIntegrationTests.swift

**Checkpoint**: User Story 2 complete - comment counts visible, independently testable

---

## Phase 5: User Story 3 - Reviewer Context Awareness (Priority: P3)

**Goal**: Display assigned reviewers for each PR so developers understand review responsibility distribution

**Independent Test**: Verify that assigned reviewer names appear when available and distinguish sole vs shared responsibility

### Implementation for User Story 3

- [X] T035 [P] [US3] Update PreviewMetadataView to display requested reviewers list in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PreviewMetadataView.swift
- [X] T036 [P] [US3] Add reviewer avatar display (if avatarURL available) in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PreviewMetadataView.swift
- [X] T037 [P] [US3] Add logic to indicate when user is sole reviewer in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PreviewMetadataView.swift
- [X] T038 [P] [US3] Add accessibility labels for reviewer list (VoiceOver support) in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PreviewMetadataView.swift
- [X] T039 [P] [US3] Add unit tests for reviewer display (empty, single, multiple reviewers) in app/GitReviewItApp/Tests/GitReviewItAppTests/UnitTests/PreviewMetadataViewTests.swift
- [X] T040 [P] [US3] Add integration test verifying reviewer data from PR Details API in app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/PRPreviewMetadataTests.swift

**Checkpoint**: User Story 3 complete - reviewer information visible, independently testable

---

## Phase 6: User Story 4 - Label-Based Categorization (Priority: P4)

**Goal**: Display labels/tags for each PR so developers can quickly identify PRs by category (bug, feature, urgent)

**Independent Test**: Verify that labels appear when present and no label section appears when PR has no labels

### Implementation for User Story 4

- [X] T041 [P] [US4] Update PreviewMetadataView to display labels with color-coded backgrounds in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PreviewMetadataView.swift
- [X] T042 [P] [US4] Implement Color extension for hex color parsing (Color(hex:)) in app/GitReviewItApp/Sources/GitReviewItApp/Shared/Utilities/ColorExtensions.swift
- [X] T043 [P] [US4] Add text color selection logic (black/white based on background luminance) in app/GitReviewItApp/Sources/GitReviewItApp/Shared/Utilities/ColorExtensions.swift
- [X] T044 [P] [US4] Add accessibility labels for label list (VoiceOver support) in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PreviewMetadataView.swift
- [X] T045 [P] [US4] Add unit tests for label display (no labels, single label, multiple labels) in app/GitReviewItApp/Tests/GitReviewItAppTests/UnitTests/PreviewMetadataViewTests.swift
- [X] T046 [P] [US4] Add unit tests for hex color parsing and text color selection in app/GitReviewItApp/Tests/GitReviewItAppTests/UnitTests/ColorExtensionsTests.swift
- [X] T047 [P] [US4] Add integration test verifying label data from Search API in app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/PRPreviewMetadataTests.swift

**Checkpoint**: User Story 4 complete - labels visible with proper styling, independently testable

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories, final quality checks

- [ ] T048 [P] Add loading indicators for metadata enrichment while keeping list responsive in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PullRequestRow.swift
- [ ] T049 [P] Verify filtering functionality works with preview metadata enabled in app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/FilteringTests.swift
- [ ] T050 [P] Verify searching functionality works with preview metadata enabled in app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/SearchTests.swift
- [ ] T051 [P] Verify sorting functionality works with preview metadata enabled in app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/SortingTests.swift
- [ ] T052 [P] Add performance test for PR list load time with 50 PRs (<3s requirement) in app/GitReviewItApp/Tests/GitReviewItAppTests/PerformanceTests/PreviewMetadataPerformanceTests.swift
- [ ] T052 [P] Add error handling test for rate limit scenarios in app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/ErrorHandlingTests.swift
- [ ] T053 [P] Verify graceful degradation when individual PR metadata fails in app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/ErrorHandlingTests.swift
- [ ] T054 [P] Add documentation comments to all public APIs in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/
- [ ] T055 Run just build and verify project compiles successfully
- [ ] T056 Run just test and verify all tests pass
- [ ] T057 Run just lint and verify no style violations
- [ ] T058 Manual testing: Load PR list and verify all metadata displays correctly
- [ ] T059 Manual testing: Test with GitHub Enterprise custom base URL
- [ ] T060 Manual testing: Test rate limit handling by simulating limit exceeded
- [ ] T061 Manual testing: Test accessibility with VoiceOver enabled

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - User stories can proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3 → P4)
- **Polish (Phase 7)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - No dependencies on other stories (comments from Search API)
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Reuses PreviewMetadataView from US1 but independently testable
- **User Story 4 (P4)**: Can start after Foundational (Phase 2) - Reuses PreviewMetadataView from US1 but independently testable

### Within Each User Story

- PreviewMetadataView component can be built in parallel with state container updates
- Integration tests run after implementation tasks complete
- Accessibility and OSLog tasks can run in parallel with main implementation

### Parallel Opportunities

- **Phase 1 (Setup)**: All 6 tasks (T001-T006) can run in parallel - different model files
- **Phase 2 (Foundational)**: Tasks T008-T014, T016-T017 can run in parallel - different files
- **User Story 1**: Tasks T023, T025-T026, T028-T029 can run in parallel after T020-T022 complete
- **User Story 2**: All 5 tasks (T030-T034) can run in parallel
- **User Story 3**: All 6 tasks (T035-T040) can run in parallel
- **User Story 4**: Tasks T042-T043, T044-T047 can run in parallel after T041
- **Phase 7 (Polish)**: All tasks except T056-T062 can run in parallel

---

## Parallel Example: User Story 1

After completing state container tasks (T020-T022), launch these in parallel:

```bash
# Can all proceed simultaneously:
Task T023: Create PreviewMetadataView component
Task T025: Add integration test for metadata enrichment
Task T026: Add unit tests for enrichPreviewMetadata
Task T028: Add accessibility labels for change size data
Task T029: Add OSLog statements for metadata enrichment
```

---

## Parallel Example: User Story 2

All User Story 2 tasks can run simultaneously (different aspects of same feature):

```bash
Task T030: Update PreviewMetadataView to display comment count
Task T031: Add zero vs unavailable logic
Task T032: Add accessibility label for comments
Task T033: Add unit tests for comment display
Task T034: Add integration test for comments from Search API
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (models and tests)
2. Complete Phase 2: Foundational (API integration and PullRequest model extension)
3. Complete Phase 3: User Story 1 (change size display)
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready - developers can now triage by PR size

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP - size-based triage!)
3. Add User Story 2 → Test independently → Deploy/Demo (adds comment counts)
4. Add User Story 3 → Test independently → Deploy/Demo (adds reviewer context)
5. Add User Story 4 → Test independently → Deploy/Demo (adds label categorization)
6. Polish → Final quality checks and optimization

Each story adds incremental value without breaking previous stories.

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (Phases 1-2)
2. Once Foundational is done:
   - Developer A: User Story 1 (change size - P1)
   - Developer B: User Story 2 (comments - P2)
   - Developer C: User Story 3 (reviewers - P3)
   - Developer D: User Story 4 (labels - P4)
3. Stories complete and integrate independently
4. Team reconvenes for Phase 7 (polish)

---

## Summary

- **Total Tasks**: 62
- **Setup Phase**: 6 tasks (all parallelizable)
- **Foundational Phase**: 13 tasks (9 parallelizable)
- **User Story 1**: 10 tasks (7 parallelizable)
- **User Story 2**: 5 tasks (all parallelizable)
- **User Story 3**: 6 tasks (all parallelizable)
- **User Story 4**: 7 tasks (all parallelizable)
- **Polish Phase**: 15 tasks (12 parallelizable)

**Parallel Opportunities**: 51+ tasks can run in parallel given sufficient team capacity

**MVP Scope**: Phases 1-3 (User Story 1) = 29 tasks for size-based PR triage

**Format Validation**: ✅ All tasks follow checklist format (checkbox, ID, labels, file paths)

---

## Notes

- Each task includes exact file path for clarity
- [P] marker indicates task can run in parallel (different files, no blocking dependencies)
- [Story] label maps task to specific user story for traceability
- Tasks organized by user story to enable independent implementation and testing
- Commits should be made after each task or logical group
- Stop at any checkpoint to validate story independently
- All tasks specific enough for LLM execution without additional context
