# Tasks: PR Status Insights

**Feature Branch**: `004-pr-status-insights`
**Spec**: [specs/004-pr-status-insights/spec.md](specs/004-pr-status-insights/spec.md)
**Plan**: [specs/004-pr-status-insights/plan.md](specs/004-pr-status-insights/plan.md)

## Phase 1: Setup & Foundational

*No specific setup tasks required. Project structure is ready.*

## Phase 2: User Story 1 - View PR Draft Status (P1)

**Goal**: Users can identify Draft PRs in the list.

- [X] T001 [US1] Update `PullRequest` model with `isDraft` property in `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Models/PullRequest.swift`
- [X] T002 [US1] Update `SearchIssueItem` to decode `draft` field in `app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/GitHubAPI.swift`
- [X] T003 [US1] Update `mapSearchIssueToPullRequest` to map draft status in `app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/GitHubAPI.swift`
- [X] T004 [US1] Update `MockGitHubAPI` to support draft status in `app/GitReviewItApp/Tests/GitReviewItAppTests/TestDoubles/MockGitHubAPI.swift`
- [X] T005 [US1] Add integration test for draft status in `app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/PullRequestListTests.swift`
- [X] T006 [US1] Update `PullRequestRow` to display draft badge in `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PullRequestRow.swift`

## Phase 3: User Story 2 - View CI/Checks Summary (P1)

**Goal**: Users can see if CI checks are passing, failing, or pending.

- [ ] T007 [US2] Create `PRCheckStatus` enum in `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Models/PRPreviewMetadata.swift`
- [ ] T008 [US2] Create `CheckRunsResponse` model in `app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/CheckRunsResponse.swift`
- [ ] T009 [US2] Add `fetchCheckRuns` method to `GitHubAPI` protocol in `app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/GitHubAPI.swift`
- [ ] T010 [US2] Implement `fetchCheckRuns` in `GitHubAPIClient` in `app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/GitHubAPI.swift`
- [ ] T011 [US2] Update `PRPreviewMetadata` to include `checkStatus` in `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Models/PRPreviewMetadata.swift`
- [ ] T012 [US2] Update `PRDetailsResponse` to decode `head.sha` in `app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/PRDetailsResponse.swift`
- [ ] T013 [US2] Update `fetchPRDetails` to fetch check runs in parallel in `app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/GitHubAPI.swift`
- [ ] T014 [US2] Update `MockGitHubAPI` to support check runs in `app/GitReviewItApp/Tests/GitReviewItAppTests/TestDoubles/MockGitHubAPI.swift`
- [ ] T015 [US2] Add integration tests for check statuses in `app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/PRPreviewMetadataIntegrationTests.swift`
- [ ] T016 [US2] Update `PullRequestRow` to display check status in `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PullRequestRow.swift`

## Phase 4: User Story 3 - View Mergeability Status (P1)

**Goal**: Users can see if a PR has merge conflicts.

- [X] T017 [US3] Create `PRMergeStatus` enum in `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Models/PRPreviewMetadata.swift`
- [X] T018 [US3] Update `PRPreviewMetadata` to include `mergeStatus` in `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Models/PRPreviewMetadata.swift`
- [X] T019 [US3] Update `PRDetailsResponse` to decode `mergeable` fields in `app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/PRDetailsResponse.swift`
- [X] T020 [US3] Update `toPRPreviewMetadata` mapping logic in `app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/PRDetailsResponse.swift`
- [X] T021 [US3] Add integration tests for merge status in `app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/PRPreviewMetadataIntegrationTests.swift`
- [X] T022 [US3] Update `PullRequestRow` to display merge status in `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PullRequestRow.swift`

## Phase 5: User Story 4 - Graceful Degradation (P2)

**Goal**: App remains functional even if status insights fail to load.

- [ ] T023 [US4] Verify graceful degradation in `fetchPRDetails` error handling in `app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/GitHubAPI.swift`
- [ ] T024 [US4] Add test for partial failure (checks fail, details succeed) in `app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/PRPreviewMetadataIntegrationTests.swift`
- [ ] T025 [US4] Ensure UI handles "Unknown" states gracefully in `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PullRequestRow.swift`

## Phase 6: Polish & Cross-Cutting

- [ ] T026 Verify VoiceOver labels for all new status indicators in `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PullRequestRow.swift`

## Dependencies

1.  **US1 (Draft)**: Independent. Can be done first.
2.  **US2 (Checks)**: Independent of US1/US3.
3.  **US3 (Mergeability)**: Independent of US1/US2.
4.  **US4 (Degradation)**: Depends on US2/US3 implementation.

## Parallel Execution

- **US1, US2, and US3** can be implemented in parallel as they touch different parts of the API response and models (mostly).
- **US2 and US3** both modify `PRPreviewMetadata` and `PullRequestRow`, so merge conflicts are possible but manageable.

## Implementation Strategy

1.  **MVP**: Implement US1 (Draft) first as it's the simplest and high value.
2.  **Enhancement**: Implement US3 (Mergeability) next as it uses existing API calls.
3.  **Complex**: Implement US2 (Checks) last as it requires new API calls and parallel fetching logic.
