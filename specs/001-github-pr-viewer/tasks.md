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

- [X] T001 Create project directory structure per plan.md in app/GitReviewItApp/
- [X] T002 ~~DELETED: URL scheme not needed for PAT authentication~~
- [X] T003 Create app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/ directory structure (Networking/, Storage/)
- [X] T004 Create app/GitReviewItApp/Sources/GitReviewItApp/Features/ directory structure (Authentication/, PullRequests/)
- [X] T005 Create app/GitReviewItApp/Sources/GitReviewItApp/Shared/ directory structure (Views/, Models/)
- [X] T006 Create app/GitReviewItApp/Tests/GitReviewItAppTests/ directory structure (IntegrationTests/, TestDoubles/, Fixtures/)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Error Types & Models

- [X] T007 [P] Create APIError enum in app/GitReviewItApp/Sources/GitReviewItApp/Shared/Models/APIError.swift
- [X] T008 [P] Create LoadingState generic enum in app/GitReviewItApp/Sources/GitReviewItApp/Shared/Models/LoadingState.swift
- [X] T009 [P] [REWORK] Rename to CredentialStorageError enum in app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Storage/CredentialStorage.swift
- [X] T010 ~~DELETED: OAuthError not needed for PAT authentication~~
- [X] T011 [P] Create HTTPError enum in app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/HTTPClient.swift

### Protocol Definitions

- [X] T012 [P] Define HTTPClient protocol in app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/HTTPClient.swift
- [X] T013 [P] [REWORK] Rename to CredentialStorage protocol in app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Storage/CredentialStorage.swift (stores token + baseURL)
- [X] T014 ~~DELETED: OAuthManager not needed for PAT authentication~~
- [X] T015 [P] Define GitHubAPI protocol in app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/GitHubAPI.swift

### Domain Models

- [X] T016 [P] [REWORK] Rename to GitHubCredentials struct (token: String, baseURL: String) in app/GitReviewItApp/Sources/GitReviewItApp/Features/Authentication/Models/GitHubCredentials.swift
- [X] T017 [P] Create AuthenticatedUser struct in app/GitReviewItApp/Sources/GitReviewItApp/Features/Authentication/Models/AuthenticatedUser.swift
- [X] T018 [P] Create PullRequest struct in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Models/PullRequest.swift

### Production Implementations

- [X] T019 [P] Implement URLSessionHTTPClient conforming to HTTPClient in app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/HTTPClient.swift
- [X] T020 [P] [REWORK] Rename to KeychainCredentialStorage conforming to CredentialStorage in app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Storage/CredentialStorage.swift (stores token + baseURL as JSON)
- [X] T021 ~~DELETED: ASWebAuthenticationSessionOAuthManager not needed for PAT authentication~~
- [X] T022 [REWORK] Implement GitHubAPIClient conforming to GitHubAPI with baseURL parameter support in app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/GitHubAPI.swift
- [X] T023 ~~DELETED: GitHubOAuthConfig not needed for PAT authentication~~

### Test Doubles

- [X] T024 [P] Create MockHTTPClient conforming to HTTPClient in app/GitReviewItApp/Tests/GitReviewItAppTests/TestDoubles/MockHTTPClient.swift
- [X] T025 [P] Create MockCredentialStorage conforming to CredentialStorage in app/GitReviewItApp/Tests/GitReviewItAppTests/TestDoubles/MockCredentialStorage.swift
- [X] T026 ~~DELETED: MockOAuthManager not needed for PAT authentication~~
- [X] T027 [P] Create MockGitHubAPI conforming to GitHubAPI in app/GitReviewItApp/Tests/GitReviewItAppTests/TestDoubles/MockGitHubAPI.swift

### Test Fixtures

- [X] T028 [P] Create user-response.json fixture in app/GitReviewItApp/Tests/GitReviewItAppTests/Fixtures/user-response.json
- [X] T029 [P] Create prs-response.json fixture in app/GitReviewItApp/Tests/GitReviewItAppTests/Fixtures/prs-response.json
- [X] T030 [P] Create error-responses.json fixture in app/GitReviewItApp/Tests/GitReviewItAppTests/Fixtures/error-responses.json

### Shared UI Components

- [X] T031 [P] Create LoadingView in app/GitReviewItApp/Sources/GitReviewItApp/Shared/Views/LoadingView.swift
- [X] T032 [P] Create ErrorView in app/GitReviewItApp/Sources/GitReviewItApp/Shared/Views/ErrorView.swift

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - First-Time GitHub Authentication (Priority: P1) 🎯 MVP

**Goal**: User can authenticate with GitHub (including GitHub Enterprise) by entering Personal Access Token and optional API base URL

**Independent Test**: Launch fresh install, see login screen, enter PAT (and optional baseURL for GHE), verify credentials stored, see navigation to PR list screen

### Implementation for User Story 1

- [X] T033 [US1] Create AuthenticationContainer (@Observable) in app/GitReviewItApp/Sources/GitReviewItApp/Features/Authentication/State/AuthenticationContainer.swift
- [X] T034 [US1] Implement validateAndSaveCredentials(token:baseURL:) method in AuthenticationContainer (validates via GET /user, stores if valid)
- [X] T035 [US1] Implement logout() method in AuthenticationContainer
- [X] T036 [US1] Create LoginView with PAT TextField, optional baseURL TextField (default: https://api.github.com), "Need a token?" help link (opens https://github.com/settings/tokens), and Sign In button in app/GitReviewItApp/Sources/GitReviewItApp/Features/Authentication/Views/LoginView.swift
- [X] T037 [US1] Connect LoginView to AuthenticationContainer using @State
- [X] T038 [US1] Add input validation in LoginView (non-empty token, valid URL format for baseURL)
- [X] T039 [US1] Update ContentView to conditionally show LoginView vs PullRequestListView based on auth state
- [X] T040 [US1] Create AuthenticationFlowTests in app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/AuthenticationFlowTests.swift
- [X] T041 [US1] Add test for successful PAT validation and credential storage
- [X] T042 [US1] Add test for invalid PAT handling (401 response)
- [X] T043 [US1] Add test for GitHub Enterprise custom baseURL authentication

**Checkpoint**: User Story 1 complete - users can authenticate with PAT (including GitHub Enterprise) and credentials are stored

---

## Phase 4: User Story 2 - View PRs Awaiting My Review (Priority: P1) 🎯 MVP

**Goal**: Authenticated user sees list of all pull requests where review is requested

**Independent Test**: Authenticate user, verify app fetches and displays PRs (respecting baseURL for GHE), tap PR to open in Safari

### Implementation for User Story 2

- [X] T046 [US2] Create PullRequestListContainer (@Observable) in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/State/PullRequestListContainer.swift
- [X] T047 [US2] Implement loadPullRequests() method fetching from GitHubAPI (using stored token + baseURL) in PullRequestListContainer
- [X] T048 [US2] Implement retry() method in PullRequestListContainer
- [X] T049 [US2] Add loading/error/empty state management in PullRequestListContainer
- [X] T050 [US2] Create PullRequestRow view displaying repo, title, author, timestamp in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PullRequestRow.swift
- [X] T051 [US2] Create PullRequestListView with List of PullRequestRow in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PullRequestListView.swift
- [X] T052 [US2] Connect PullRequestListView to PullRequestListContainer using @State
- [X] T053 [US2] Implement .task modifier in PullRequestListView to call loadPullRequests() on appear
- [X] T054 [US2] Add loading state display in PullRequestListView
- [X] T055 [US2] Add empty state message when no PRs in PullRequestListView
- [X] T056 [US2] Add error state with retry button in PullRequestListView
- [X] T057 [US2] Implement tap handler to open PR URL in Safari using Link or openURL
- [X] T058 [US2] Format relative timestamps using RelativeDateTimeFormatter in PullRequestRow
- [X] T059 [US2] Create PullRequestListTests in app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/PullRequestListTests.swift
- [X] T060 [US2] Add test for successful PR list fetch and display
- [X] T061 [US2] Add test for empty state when no PRs
- [X] T062 [US2] Add test for loading state display
- [X] T063 [US2] Add test for error state and retry functionality

**Checkpoint**: User Story 2 complete - users can see and interact with PR list

---

## Phase 5: User Story 3 - Return Without Re-Authentication (Priority: P1) 🎯 MVP

**Goal**: Returning user sees PR list immediately without logging in again

**Independent Test**: Authenticate once, close app, relaunch, verify PR list loads without login screen

### Implementation for User Story 3

- [X] T064 [US3] Add checkExistingCredentials() method in AuthenticationContainer
- [X] T065 [US3] Implement automatic credential load on app launch in AuthenticationContainer
- [X] T066 [US3] Add credential validation logic detecting 401 responses in GitHubAPIClient
- [X] T067 [US3] Implement automatic logout and return to login on invalid credentials (401) in AuthenticationContainer
- [X] T068 [US3] Update ContentView to call checkExistingCredentials() in .task modifier on launch
- [X] T069 [US3] Add navigation state management to skip login when valid credentials exist in ContentView
- [X] T070 [US3] Create CredentialPersistenceTests in app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/CredentialPersistenceTests.swift
- [X] T071 [US3] Add test for app launch with valid stored credentials
- [X] T072 [US3] Add test for app launch with expired PAT (401 response)
- [X] T073 [US3] Add test for app launch with no stored credentials

**Checkpoint**: User Story 3 complete - users stay logged in across sessions

---

## Phase 6: User Story 4 - Handle Errors Gracefully (Priority: P2)

**Goal**: Users understand errors and can retry operations when failures occur

**Independent Test**: Simulate network failures and API errors, verify appropriate messages and retry options

### Implementation for User Story 4

- [ ] T074 [US4] Enhance APIError with user-friendly LocalizedError descriptions in app/GitReviewItApp/Sources/GitReviewItApp/Shared/Models/APIError.swift
- [ ] T075 [US4] Add rate limit detection and reset time display for 403 responses in GitHubAPIClient
- [ ] T076 [US4] Add network unreachable error handling in URLSessionHTTPClient
- [ ] T077 [US4] Enhance ErrorView with specific error messages based on APIError type in app/GitReviewItApp/Sources/GitReviewItApp/Shared/Views/ErrorView.swift
- [ ] T078 [US4] Add retry button functionality in ErrorView
- [ ] T079 [US4] Add error display in AuthenticationContainer for PAT validation failures
- [ ] T080 [US4] Add connection status checking before network operations
- [ ] T081 [US4] Create ErrorHandlingTests in app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/ErrorHandlingTests.swift
- [ ] T082 [US4] Add test for network failure error display
- [ ] T083 [US4] Add test for rate limit error with reset time
- [ ] T084 [US4] Add test for invalid response error handling
- [ ] T085 [US4] Add test for retry functionality after transient errors

**Checkpoint**: User Story 4 complete - app handles all error scenarios gracefully

---

## Phase 7: User Story 5 - Log Out and Clear Session (Priority: P2)

**Goal**: Users can log out to switch accounts or secure their session

**Independent Test**: Authenticate, log out, verify credentials cleared and login screen returns

### Implementation for User Story 5

- [ ] T086 [US5] Add logout button or menu item in PullRequestListView
- [ ] T087 [US5] Connect logout action to AuthenticationContainer.logout() method
- [ ] T088 [US5] Verify credential deletion from Keychain in logout() method
- [ ] T089 [US5] Add navigation back to LoginView after logout in ContentView
- [ ] T090 [US5] Clear all cached user data on logout in AuthenticationContainer
- [ ] T091 [US5] Create LogoutTests in app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/LogoutTests.swift
- [ ] T092 [US5] Add test for successful logout and credential removal
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
Task T007: "Create APIError enum in app/GitReviewItApp/Sources/GitReviewItApp/Shared/Models/APIError.swift"
Task T008: "Create LoadingState enum in app/GitReviewItApp/Sources/GitReviewItApp/Shared/Models/LoadingState.swift"
Task T009: "Create CredentialStorageError enum in app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Storage/CredentialStorage.swift"
Task T011: "Create HTTPError enum in app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/HTTPClient.swift"

# Then launch all protocol definitions together:
Task T012: "Define HTTPClient protocol in app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/HTTPClient.swift"
Task T013: "Define CredentialStorage protocol in app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Storage/CredentialStorage.swift"
Task T015: "Define GitHubAPI protocol in app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/GitHubAPI.swift"

# Then launch all domain models together:
Task T016: "Create GitHubCredentials struct in app/GitReviewItApp/Sources/GitReviewItApp/Features/Authentication/Models/GitHubCredentials.swift"
Task T017: "Create AuthenticatedUser struct in app/GitReviewItApp/Sources/GitReviewItApp/Features/Authentication/Models/AuthenticatedUser.swift"
Task T018: "Create PullRequest struct in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Models/PullRequest.swift"
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

- **Total Tasks**: 100 tasks across 8 phases (5 OAuth tasks deleted)
- **MVP Tasks (P1)**: 68 tasks (Phases 1-5)
- **Enhancement Tasks (P2)**: 21 tasks (Phases 6-7)
- **Polish Tasks**: 11 tasks (Phase 8)
- **Tests Included**: Integration tests for each user story (not unit tests per spec)
- **Parallel Tasks**: ~40 tasks marked with [P] for concurrent execution
- **User Stories**: 5 independent stories, 3 in MVP (P1)
- **Authentication**: Personal Access Token (PAT) with GitHub Enterprise support (custom baseURL)

### Task Count by User Story

- **Setup (Phase 1)**: 5 tasks (URL scheme task deleted)
- **Foundational (Phase 2)**: 22 tasks (OAuth tasks deleted, BLOCKING - must complete first)
- **User Story 1 (P1)**: 11 tasks - PAT Authentication (simplified from OAuth)
- **User Story 2 (P1)**: 18 tasks - PR List Display
- **User Story 3 (P1)**: 10 tasks - Session Persistence
- **User Story 4 (P2)**: 12 tasks - Error Handling
- **User Story 5 (P2)**: 9 tasks - Logout
- **Polish (Phase 8)**: 11 tasks - Cross-cutting improvements

### Independent Test Criteria

- **US1**: Can authenticate with GitHub (including GitHub Enterprise) using PAT, credentials stored, navigates to PR list
- **US2**: Can fetch and display PRs (respecting baseURL for GHE), tap to open in Safari, see loading/empty/error states
- **US3**: Can relaunch app and see PR list without re-auth
- **US4**: Can see appropriate error messages and retry failed operations
- **US5**: Can log out, verify credentials cleared, see login screen

### Suggested MVP Scope

**Phase 1 + Phase 2 + Phase 3 + Phase 4 + Phase 5** (Tasks T001-T073)

This delivers the core value: authenticate with GitHub (including GitHub Enterprise) using PAT and view PRs awaiting review, with session persistence. Error handling (US4) and logout (US5) can follow in subsequent releases.

---

## Format Validation

✅ All tasks follow required checklist format:
- `- [ ]` checkbox prefix
- `[TaskID]` sequential numbering (T001-T100, OAuth tasks deleted/marked)
- `[P]` marker for parallelizable tasks (~40 tasks)
- `[Story]` label for user story tasks (US1-US5)
- `[REWORK]` marker for completed tasks needing modification
- Description with exact file path in app/GitReviewItApp/

✅ All user stories independently testable:
- Each story has clear goal and test criteria
- Foundational phase creates shared infrastructure
- Stories can be implemented and validated in priority order
- Integration points clearly identified
- GitHub Enterprise supported via baseURL parameter

✅ Tasks organized for incremental delivery:
- MVP = Phases 1-5 (68 tasks)
- Each phase has completion checkpoint
- Parallel execution opportunities identified
- Dependencies clearly documented
- PAT authentication simplifies implementation (no OAuth complexity)
