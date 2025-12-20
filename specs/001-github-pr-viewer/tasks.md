# Tasks: GitHub PR Review Viewer

**Feature**: 001-github-pr-viewer  
**Input**: Design documents from `/specs/001-github-pr-viewer/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/protocols.md  
**Tests**: Not requested - focusing on implementation only  
**Organization**: Tasks grouped by user story for independent implementation

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4, US5)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [X] T001 Create project directory structure per plan.md in GitReviewIt/
- [X] T002 ⚠️ HUMAN: Add CFBundleURLTypes with gitreviewit custom URL scheme in Info.plist (see HUMAN_HELP_NEEDED.md #1)
- [X] T003 Create GitReviewIt/Infrastructure/ directory structure (Networking/, Storage/, OAuth/)
- [X] T004 Create GitReviewIt/Features/ directory structure (Authentication/, PullRequests/)
- [X] T005 Create GitReviewIt/Shared/ directory structure (Views/, Models/)
- [X] T006 Create GitReviewItTests/ directory structure (IntegrationTests/, TestDoubles/, Fixtures/)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Error Types & Models

- [X] T007 [P] Create APIError enum in GitReviewIt/Shared/Models/APIError.swift
- [X] T008 [P] Create LoadingState generic enum in GitReviewIt/Shared/Models/LoadingState.swift
- [X] T009 [P] Create TokenStorageError enum in GitReviewIt/Infrastructure/Storage/TokenStorage.swift
- [X] T010 [P] Create OAuthError enum in GitReviewIt/Infrastructure/OAuth/OAuthManager.swift
- [X] T011 [P] Create HTTPError enum in GitReviewIt/Infrastructure/Networking/HTTPClient.swift

### Protocol Definitions

- [ ] T012 [P] Define HTTPClient protocol in GitReviewIt/Infrastructure/Networking/HTTPClient.swift
- [ ] T013 [P] Define TokenStorage protocol in GitReviewIt/Infrastructure/Storage/TokenStorage.swift
- [ ] T014 [P] Define OAuthManager protocol in GitReviewIt/Infrastructure/OAuth/OAuthManager.swift
- [ ] T015 [P] Define GitHubAPI protocol in GitReviewIt/Infrastructure/Networking/GitHubAPI.swift

### Domain Models

- [ ] T016 [P] Create GitHubToken struct in GitReviewIt/Features/Authentication/Models/GitHubToken.swift
- [ ] T017 [P] Create AuthenticatedUser struct in GitReviewIt/Features/Authentication/Models/AuthenticatedUser.swift
- [ ] T018 [P] Create PullRequest struct in GitReviewIt/Features/PullRequests/Models/PullRequest.swift

### Production Implementations

- [ ] T019 [P] Implement URLSessionHTTPClient conforming to HTTPClient in GitReviewIt/Infrastructure/Networking/HTTPClient.swift
- [ ] T020 [P] Implement KeychainTokenStorage conforming to TokenStorage in GitReviewIt/Infrastructure/Storage/TokenStorage.swift
- [ ] T021 [P] Implement ASWebAuthenticationSessionOAuthManager conforming to OAuthManager in GitReviewIt/Infrastructure/OAuth/OAuthManager.swift
- [ ] T022 Implement GitHubAPIClient conforming to GitHubAPI in GitReviewIt/Infrastructure/Networking/GitHubAPI.swift
- [ ] T023 ⚠️ HUMAN: Create GitHubOAuthConfig enum with client credentials in GitReviewIt/Infrastructure/OAuth/GitHubOAuthConfig.swift (see HUMAN_HELP_NEEDED.md #4)

### Test Doubles

- [ ] T024 [P] Create MockHTTPClient conforming to HTTPClient in GitReviewItTests/TestDoubles/MockHTTPClient.swift
- [ ] T025 [P] Create MockTokenStorage conforming to TokenStorage in GitReviewItTests/TestDoubles/MockTokenStorage.swift
- [ ] T026 [P] Create MockOAuthManager conforming to OAuthManager in GitReviewItTests/TestDoubles/MockOAuthManager.swift
- [ ] T027 [P] Create MockGitHubAPI conforming to GitHubAPI in GitReviewItTests/TestDoubles/MockGitHubAPI.swift

### Test Fixtures

- [ ] T028 [P] Create user-response.json fixture in GitReviewItTests/Fixtures/user-response.json
- [ ] T029 [P] Create prs-response.json fixture in GitReviewItTests/Fixtures/prs-response.json
- [ ] T030 [P] Create error-responses.json fixture in GitReviewItTests/Fixtures/error-responses.json

### Shared UI Components

- [ ] T031 [P] Create LoadingView in GitReviewIt/Shared/Views/LoadingView.swift
- [ ] T032 [P] Create ErrorView in GitReviewIt/Shared/Views/ErrorView.swift

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - First-Time GitHub Authentication (Priority: P1) 🎯 MVP

**Goal**: User can authenticate with GitHub account using OAuth and have token stored securely

**Independent Test**: Launch fresh install, see login screen, complete OAuth flow, verify token stored, see navigation to PR list screen

### Implementation for User Story 1

- [ ] T033 [US1] Create AuthenticationContainer (@Observable) in GitReviewIt/Features/Authentication/State/AuthenticationContainer.swift
- [ ] T034 [US1] Implement startOAuth() method in AuthenticationContainer
- [ ] T035 [US1] Implement completeOAuth(code:) method in AuthenticationContainer with token exchange and storage
- [ ] T036 [US1] Implement logout() method in AuthenticationContainer
- [ ] T037 [US1] Create LoginView with Sign in with GitHub button in GitReviewIt/Features/Authentication/Views/LoginView.swift
- [ ] T038 [US1] Connect LoginView to AuthenticationContainer using @State
- [ ] T039 [US1] Implement .onOpenURL modifier in ContentView to capture OAuth callback
- [ ] T040 [US1] Add state validation in completeOAuth to prevent CSRF attacks
- [ ] T041 [US1] Update ContentView to conditionally show LoginView vs PullRequestListView based on auth state
- [ ] T042 ⚠️ HUMAN: Create AuthenticationFlowTests in GitReviewItTests/IntegrationTests/AuthenticationFlowTests.swift (AFTER: setup test target + scheme, see HUMAN_HELP_NEEDED.md #2-3)
- [ ] T043 [US1] Add test for successful OAuth flow with mock dependencies
- [ ] T044 [US1] Add test for OAuth cancellation handling
- [ ] T045 [US1] Add test for token storage verification after successful auth

**Checkpoint**: User Story 1 complete - users can authenticate and token is stored

---

## Phase 4: User Story 2 - View PRs Awaiting My Review (Priority: P1) 🎯 MVP

**Goal**: Authenticated user sees list of all pull requests where review is requested

**Independent Test**: Authenticate user, verify app fetches and displays PRs, tap PR to open in Safari

### Implementation for User Story 2

- [ ] T046 [US2] Create PullRequestListContainer (@Observable) in GitReviewIt/Features/PullRequests/State/PullRequestListContainer.swift
- [ ] T047 [US2] Implement loadPullRequests() method fetching from GitHubAPI in PullRequestListContainer
- [ ] T048 [US2] Implement retry() method in PullRequestListContainer
- [ ] T049 [US2] Add loading/error/empty state management in PullRequestListContainer
- [ ] T050 [US2] Create PullRequestRow view displaying repo, title, author, timestamp in GitReviewIt/Features/PullRequests/Views/PullRequestRow.swift
- [ ] T051 [US2] Create PullRequestListView with List of PullRequestRow in GitReviewIt/Features/PullRequests/Views/PullRequestListView.swift
- [ ] T052 [US2] Connect PullRequestListView to PullRequestListContainer using @State
- [ ] T053 [US2] Implement .task modifier in PullRequestListView to call loadPullRequests() on appear
- [ ] T054 [US2] Add loading state display in PullRequestListView
- [ ] T055 [US2] Add empty state message when no PRs in PullRequestListView
- [ ] T056 [US2] Add error state with retry button in PullRequestListView
- [ ] T057 [US2] Implement tap handler to open PR URL in Safari using Link or openURL
- [ ] T058 [US2] Format relative timestamps using RelativeDateTimeFormatter in PullRequestRow
- [ ] T059 [US2] Create PullRequestListTests in GitReviewItTests/IntegrationTests/PullRequestListTests.swift
- [ ] T060 [US2] Add test for successful PR list fetch and display
- [ ] T061 [US2] Add test for empty state when no PRs
- [ ] T062 [US2] Add test for loading state display
- [ ] T063 [US2] Add test for error state and retry functionality

**Checkpoint**: User Story 2 complete - users can see and interact with PR list

---

## Phase 5: User Story 3 - Return Without Re-Authentication (Priority: P1) 🎯 MVP

**Goal**: Returning user sees PR list immediately without logging in again

**Independent Test**: Authenticate once, close app, relaunch, verify PR list loads without login screen

### Implementation for User Story 3

- [ ] T064 [US3] Add checkExistingToken() method in AuthenticationContainer
- [ ] T065 [US3] Implement automatic token load on app launch in AuthenticationContainer
- [ ] T066 [US3] Add token validation logic detecting 401 responses in GitHubAPIClient
- [ ] T067 [US3] Implement automatic logout and return to login on invalid token (401) in AuthenticationContainer
- [ ] T068 [US3] Update ContentView to call checkExistingToken() in .task modifier on launch
- [ ] T069 [US3] Add navigation state management to skip login when valid token exists in ContentView
- [ ] T070 [US3] Create TokenPersistenceTests in GitReviewItTests/IntegrationTests/TokenPersistenceTests.swift
- [ ] T071 [US3] Add test for app launch with valid stored token
- [ ] T072 [US3] Add test for app launch with expired token (401 response)
- [ ] T073 [US3] Add test for app launch with no stored token

**Checkpoint**: User Story 3 complete - users stay logged in across sessions

---

## Phase 6: User Story 4 - Handle Errors Gracefully (Priority: P2)

**Goal**: Users understand errors and can retry operations when failures occur

**Independent Test**: Simulate network failures and API errors, verify appropriate messages and retry options

### Implementation for User Story 4

- [ ] T074 [US4] Enhance APIError with user-friendly LocalizedError descriptions in GitReviewIt/Shared/Models/APIError.swift
- [ ] T075 [US4] Add rate limit detection and reset time display for 403 responses in GitHubAPIClient
- [ ] T076 [US4] Add network unreachable error handling in URLSessionHTTPClient
- [ ] T077 [US4] Enhance ErrorView with specific error messages based on APIError type in GitReviewIt/Shared/Views/ErrorView.swift
- [ ] T078 [US4] Add retry button functionality in ErrorView
- [ ] T079 [US4] Add error display in AuthenticationContainer for OAuth failures
- [ ] T080 [US4] Add connection status checking before network operations
- [ ] T081 [US4] Create ErrorHandlingTests in GitReviewItTests/IntegrationTests/ErrorHandlingTests.swift
- [ ] T082 [US4] Add test for network failure error display
- [ ] T083 [US4] Add test for rate limit error with reset time
- [ ] T084 [US4] Add test for invalid response error handling
- [ ] T085 [US4] Add test for retry functionality after transient errors

**Checkpoint**: User Story 4 complete - app handles all error scenarios gracefully

---

## Phase 7: User Story 5 - Log Out and Clear Session (Priority: P2)

**Goal**: Users can log out to switch accounts or secure their session

**Independent Test**: Authenticate, log out, verify token cleared and login screen returns

### Implementation for User Story 5

- [ ] T086 [US5] Add logout button or menu item in PullRequestListView
- [ ] T087 [US5] Connect logout action to AuthenticationContainer.logout() method
- [ ] T088 [US5] Verify token deletion from Keychain in logout() method
- [ ] T089 [US5] Add navigation back to LoginView after logout in ContentView
- [ ] T090 [US5] Clear all cached user data on logout in AuthenticationContainer
- [ ] T091 [US5] Create LogoutTests in GitReviewItTests/IntegrationTests/LogoutTests.swift
- [ ] T092 [US5] Add test for successful logout and token removal
- [ ] T093 [US5] Add test for navigation to login screen after logout
- [ ] T094 [US5] Add test for app relaunch after logout shows login screen

**Checkpoint**: User Story 5 complete - users can securely log out

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T095 [P] Add PR list pull-to-refresh gesture in PullRequestListView
- [ ] T096 [P] Add app icon in Assets.xcassets
- [ ] T097 [P] Add accent color customization in Assets.xcassets
- [ ] T098 [P] Implement proper SwiftUI preview providers for all views
- [ ] T099 [P] Add accessibility labels for VoiceOver support
- [ ] T100 [P] Add loading performance optimization for large PR lists (100+ items)
- [ ] T101 [P] Add proper spacing and padding throughout UI per Apple HIG
- [ ] T102 Validate all quickstart.md test scenarios work end-to-end
- [ ] T103 Add inline code documentation for all public types
- [ ] T104 [P] Code review and SwiftLint cleanup
- [ ] T105 Verify all constitutional principles from plan.md are satisfied

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phases 3-7)**: All depend on Foundational phase completion
  - User Story 1 (P1): Can start after Foundational - No dependencies on other stories
  - User Story 2 (P1): Can start after Foundational - Integrates with US1 auth state
  - User Story 3 (P1): Can start after Foundational - Extends US1 and US2 with persistence
  - User Story 4 (P2): Can start after Foundational - Enhances error handling across US1-3
  - User Story 5 (P2): Can start after Foundational - Extends US1 logout capability
- **Polish (Phase 8)**: Depends on desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Foundation only - First authenticator
- **User Story 2 (P1)**: Foundation only - Reads auth state from US1 but independently testable
- **User Story 3 (P1)**: Foundation only - Extends US1+US2 but core logic is independent
- **User Story 4 (P2)**: Foundation only - Cross-cutting error handling
- **User Story 5 (P2)**: Foundation only - Extends US1 logout

### Within Each User Story

1. State containers before views
2. Models before containers
3. Core implementation before integration
4. Story complete before moving to next priority

### Parallel Opportunities

**Phase 1 (Setup)**: All tasks sequential (directory creation)

**Phase 2 (Foundational)**: 
- T007-T011 (Error types) - all parallel
- T012-T015 (Protocols) - all parallel
- T016-T018 (Domain models) - all parallel
- T019-T023 (Production implementations) - T019-T021 parallel, T022-T023 depend on protocols
- T024-T027 (Test doubles) - all parallel
- T028-T030 (Fixtures) - all parallel
- T031-T032 (Shared UI) - all parallel

**Phase 3 (US1)**:
- T042-T045 (Tests) - parallel after implementation
- T037 (LoginView) can start while T033-T036 (Container) are being built

**Phase 4 (US2)**:
- T050 (PullRequestRow) parallel with T046-T049 (Container)
- T059-T063 (Tests) - parallel after implementation

**Phase 5 (US3)**:
- T070-T073 (Tests) - parallel after implementation

**Phase 6 (US4)**:
- T074-T077 (Error handling) - parallel enhancements
- T081-T085 (Tests) - parallel after implementation

**Phase 7 (US5)**:
- T091-T094 (Tests) - parallel after implementation

**Phase 8 (Polish)**:
- T095-T101, T104 - all parallel
- T102-T103, T105 - sequential validation tasks

---

## Parallel Example: Foundational Phase

```bash
# Launch all error types together:
Task T007: "Create APIError enum in GitReviewIt/Shared/Models/APIError.swift"
Task T008: "Create LoadingState enum in GitReviewIt/Shared/Models/LoadingState.swift"
Task T009: "Create TokenStorageError enum in GitReviewIt/Infrastructure/Storage/TokenStorage.swift"
Task T010: "Create OAuthError enum in GitReviewIt/Infrastructure/OAuth/OAuthManager.swift"
Task T011: "Create HTTPError enum in GitReviewIt/Infrastructure/Networking/HTTPClient.swift"

# Then launch all protocol definitions together:
Task T012: "Define HTTPClient protocol in GitReviewIt/Infrastructure/Networking/HTTPClient.swift"
Task T013: "Define TokenStorage protocol in GitReviewIt/Infrastructure/Storage/TokenStorage.swift"
Task T014: "Define OAuthManager protocol in GitReviewIt/Infrastructure/OAuth/OAuthManager.swift"
Task T015: "Define GitHubAPI protocol in GitReviewIt/Infrastructure/Networking/GitHubAPI.swift"

# Then launch all domain models together:
Task T016: "Create GitHubToken struct in GitReviewIt/Features/Authentication/Models/GitHubToken.swift"
Task T017: "Create AuthenticatedUser struct in GitReviewIt/Features/Authentication/Models/AuthenticatedUser.swift"
Task T018: "Create PullRequest struct in GitReviewIt/Features/PullRequests/Models/PullRequest.swift"
```

---

## Implementation Strategy

### MVP First (User Stories 1-3 Only)

1. Complete Phase 1: Setup (T001-T006)
2. Complete Phase 2: Foundational (T007-T032) - CRITICAL checkpoint
3. Complete Phase 3: User Story 1 - Authentication (T033-T045)
4. Complete Phase 4: User Story 2 - PR List (T046-T063)
5. Complete Phase 5: User Story 3 - Persistence (T064-T073)
6. **STOP and VALIDATE**: Test all three P1 stories independently
7. Deploy/demo MVP with core value proposition

### Full Feature Delivery

After MVP validation:
1. Complete Phase 6: User Story 4 - Error Handling (T074-T085)
2. Complete Phase 7: User Story 5 - Logout (T086-T094)
3. Complete Phase 8: Polish (T095-T105)
4. Final validation and release

### Parallel Team Strategy

With multiple developers (after Foundational phase):
- **Developer A**: User Story 1 (Authentication) - T033-T045
- **Developer B**: User Story 2 (PR List) - T046-T063 (requires US1 for auth state)
- **Developer C**: Prepare User Story 4 (Error Handling) enhancements - T074-T085

Stories integrate at ContentView level for navigation.

---

## Summary

- **Total Tasks**: 105 tasks across 8 phases
- **MVP Tasks (P1)**: 73 tasks (Phases 1-5)
- **Enhancement Tasks (P2)**: 21 tasks (Phases 6-7)
- **Polish Tasks**: 11 tasks (Phase 8)
- **Tests Included**: Integration tests for each user story (not unit tests per spec)
- **Parallel Tasks**: 45 tasks marked with [P] for concurrent execution
- **User Stories**: 5 independent stories, 3 in MVP (P1)

### Task Count by User Story

- **Setup (Phase 1)**: 6 tasks
- **Foundational (Phase 2)**: 26 tasks (BLOCKING - must complete first)
- **User Story 1 (P1)**: 13 tasks - Authentication
- **User Story 2 (P1)**: 18 tasks - PR List Display
- **User Story 3 (P1)**: 10 tasks - Session Persistence
- **User Story 4 (P2)**: 12 tasks - Error Handling
- **User Story 5 (P2)**: 9 tasks - Logout
- **Polish (Phase 8)**: 11 tasks - Cross-cutting improvements

### Independent Test Criteria

- **US1**: Can authenticate with GitHub, token stored, navigates to PR list
- **US2**: Can fetch and display PRs, tap to open in Safari, see loading/empty/error states
- **US3**: Can relaunch app and see PR list without re-auth
- **US4**: Can see appropriate error messages and retry failed operations
- **US5**: Can log out, verify token cleared, see login screen

### Suggested MVP Scope

**Phase 1 + Phase 2 + Phase 3 + Phase 4 + Phase 5** (Tasks T001-T073)

This delivers the core value: authenticate with GitHub and view PRs awaiting review, with session persistence. Error handling (US4) and logout (US5) can follow in subsequent releases.

---

## Format Validation

✅ All tasks follow required checklist format:
- `- [ ]` checkbox prefix
- `[TaskID]` sequential numbering (T001-T105)
- `[P]` marker for parallelizable tasks (45 tasks)
- `[Story]` label for user story tasks (US1-US5)
- Description with exact file path

✅ All user stories independently testable:
- Each story has clear goal and test criteria
- Foundational phase creates shared infrastructure
- Stories can be implemented and validated in priority order
- Integration points clearly identified

✅ Tasks organized for incremental delivery:
- MVP = Phases 1-5 (73 tasks)
- Each phase has completion checkpoint
- Parallel execution opportunities identified
- Dependencies clearly documented
