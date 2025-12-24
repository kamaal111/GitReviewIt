# Tasks: PR Filtering

**Feature**: Add filtering capabilities to the PR list (fuzzy search + persistent structured filters)  
**Branch**: `002-pr-filtering`  
**Input**: [plan.md](plan.md), [spec.md](spec.md), [data-model.md](data-model.md), [contracts/protocols.md](contracts/protocols.md)

**Tests**: Not explicitly requested in spec - tests included as part of implementation tasks

**Organization**: Tasks grouped by user story to enable independent implementation and testing

---

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User story this task belongs to (US1, US2, US3, US4)
- File paths follow Swift Package structure under `app/GitReviewItApp/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and directory structure

- [x] T001 Verify branch 002-pr-filtering is checked out
- [x] T002 Verify existing PR list feature (001-github-pr-viewer) is complete and functional

**Checkpoint**: Infrastructure verified - foundational work can begin

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core utilities and protocols that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 [P] Create StringSimilarity utility with levenshteinDistance and similarityScore functions in app/GitReviewItApp/Sources/GitReviewItApp/Shared/Utilities/StringSimilarity.swift
- [x] T004 [P] Create StringSimilarity unit tests in app/GitReviewItApp/Tests/GitReviewItAppTests/UnitTests/StringSimilarityTests.swift
- [x] T005 [P] Define FilterPersistence protocol in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Services/FilterPersistence.swift
- [x] T006 [P] Define FuzzyMatcherProtocol in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Services/FuzzyMatcher.swift
- [x] T007 [P] Define FilterEngineProtocol in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Services/FilterEngine.swift
- [x] T008 [P] Create Team model in app/GitReviewItApp/Sources/GitReviewItApp/Shared/Models/Team.swift
- [x] T009 [P] Create FilterConfiguration model in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Models/FilterConfiguration.swift
- [x] T010 [P] Create FilterMetadata model with static from(pullRequests:) method in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Models/FilterMetadata.swift
- [x] T011 Run foundational tests to verify all protocols and models compile and pass unit tests

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Fuzzy Search PRs (Priority: P1) 🎯 MVP

**Goal**: Enable users to quickly find specific PRs by typing parts of the title, repository name, or author name with fuzzy matching and ranked results

**Independent Test**: Enter various search queries and verify matching PRs appear in ranked order. Search is transient (doesn't persist across launches). Delivers value without structured filters.

**Acceptance Criteria from Spec**:
- Search "fix bug" shows PRs with "fix" or "bug" in title, ranked by match quality
- Search "api-service" shows PRs from repositories containing "api-service" at top
- Search "john" shows PRs by "johnsmith" ranked by name match quality  
- Clear search box shows all PRs immediately
- Search doesn't persist on app relaunch
- Empty search results show "No PRs match your search"

### Implementation for User Story 1

- [x] T012 [P] [US1] Implement FuzzyMatcher service with match method (weighted scoring: title 3.0x, repo 2.0x, author 1.5x) in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Services/FuzzyMatcher.swift
- [x] T013 [P] [US1] Create FuzzyMatcher unit tests covering exact, prefix, substring, fuzzy matches, tie-breaking by PR number in app/GitReviewItApp/Tests/GitReviewItAppTests/UnitTests/FuzzyMatcherTests.swift
- [x] T014 [US1] Implement FilterEngine service with apply method (two-stage pipeline: structured filters then fuzzy search) in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Services/FilterEngine.swift
- [x] T015 [P] [US1] Create FilterEngine unit tests covering fuzzy search scenarios in app/GitReviewItApp/Tests/GitReviewItAppTests/UnitTests/FilterEngineTests.swift
- [x] T016 [US1] Create FilterState observable state container with searchQuery property and updateSearchQuery method (300ms debouncing) in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/State/FilterState.swift
- [x] T017 [US1] Integrate FilterState into PullRequestListContainer with filteredPullRequests computed property in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/State/PullRequestListContainer.swift
- [x] T018 [US1] Add search TextField to PullRequestListView bound to filterState.searchQuery in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PullRequestListView.swift
- [x] T019 [US1] Update PullRequestListView List to use container.filteredPullRequests instead of all PRs in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PullRequestListView.swift
- [x] T020 [US1] Add empty state message for zero search results in PullRequestListView
- [x] T021 [US1] Create integration tests for search debouncing and filtering in app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/FilterStateTests.swift
- [x] T022 [US1] Manual test: Verify search works, debouncing feels responsive, results ranked correctly, clear works, search doesn't persist on relaunch

**Checkpoint**: User Story 1 complete - fuzzy search fully functional and independently testable

---

## Phase 4: User Story 2 - Filter by Organization and Repository (Priority: P2)

**Goal**: Enable users to filter PRs by organization or repository with persistent selections that survive app restarts

**Independent Test**: Select organization or repository filters, verify only matching PRs appear. Close and reopen app, verify filters persist. Works without team filtering.

**Acceptance Criteria from Spec**:
- Select "CompanyA" from org filter shows only CompanyA PRs
- Select "app-frontend" from repo filter shows only app-frontend PRs
- Combine org "CompanyA" + repo "api-backend" shows only CompanyA/api-backend PRs
- Filters persist across app restarts
- Clear individual filters works
- Empty filter results show "No PRs match your current filters" with clear option

### Implementation for User Story 2

- [x] T023 [P] [US2] Implement UserDefaultsFilterPersistence service with save, load, clear methods in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Services/FilterPersistence.swift
- [x] T024 [P] [US2] Create FilterPersistence unit tests covering save/load round-trip, missing data, corrupted data in app/GitReviewItApp/Tests/GitReviewItAppTests/UnitTests/FilterPersistenceTests.swift
- [x] T025 [US2] Add organization and repository filtering logic to FilterEngine (Stage 1 of pipeline) in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Services/FilterEngine.swift
- [x] T026 [P] [US2] Add FilterEngine unit tests for organization filter, repository filter, combined filters in app/GitReviewItApp/Tests/GitReviewItAppTests/UnitTests/FilterEngineTests.swift
- [x] T027 [US2] Add configuration property and updateFilterConfiguration method to FilterState in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/State/FilterState.swift
- [x] T028 [US2] Add loadPersistedConfiguration and clearAllFilters methods to FilterState in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/State/FilterState.swift
- [x] T029 [US2] Initialize FilterState with persistence service and call loadPersistedConfiguration in PullRequestListContainer in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/State/PullRequestListContainer.swift
- [x] T030 [US2] Create FilterSheet view with organization and repository sections (multi-select toggles) in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/FilterSheet.swift
- [x] T031 [US2] Add Apply, Cancel, and Clear All buttons to FilterSheet in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/FilterSheet.swift
- [x] T032 [US2] Create FilterChipsView to display active filters as dismissible chips in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/FilterChipsView.swift
- [x] T033 [US2] Add Filter toolbar button to PullRequestListView that presents FilterSheet in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PullRequestListView.swift
- [x] T034 [US2] Add FilterChipsView above PR list in PullRequestListView (only visible when filters active) in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PullRequestListView.swift
- [x] T035 [US2] Add empty state message for zero filter results with "Clear Filters" action in PullRequestListView
- [x] T036 [US2] Create integration tests for filter persistence across launches in app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/FilterRestoreTests.swift
- [x] T037 [US2] Create integration tests for organization and repository filtering in app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/PRFilteringTests.swift
- [x] T038 [US2] Manual test: Verify filters work, persist across restarts, chips display/remove correctly, empty states show correct messages

**Checkpoint**: User Story 2 complete - organization and repository filtering fully functional with persistence

---

## Phase 5: User Story 3 - Filter by Team (Priority: P3)

**Goal**: Enable users to filter PRs by GitHub team with graceful degradation when team data unavailable due to permissions

**Independent Test**: Select team filters (when available) and verify correct filtering. Test graceful degradation when team API fails or permissions missing. Other filters continue working.

**Acceptance Criteria from Spec**:
- Select "Backend Team" from team filter shows only Backend Team repos' PRs
- Combine team filters with org/repo filters (all active filters apply)
- Team filter marked unavailable when missing permissions with explanation
- Team filter shows error state on API failure but other filters work
- When team data unavailable, org and repo filters continue working
- Saved team filter auto-cleared on relaunch if team data unavailable with notice

### Implementation for User Story 3

- [X] T039 [P] [US3] Extend GitHubAPI protocol with fetchTeams method in app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/GitHubAPI.swift
- [X] T040 [US3] Implement fetchTeams in GitHubAPIClient (GET /user/teams, handle 403 gracefully) in app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/GitHubAPIClient.swift
- [X] T041 [P] [US3] Create teams-full-response.json fixture with repository data in app/GitReviewItApp/Tests/GitReviewItAppTests/Fixtures/teams-full-response.json
- [X] T042 [P] [US3] Add fetchTeams unit tests covering success, 401, 403, empty teams in app/GitReviewItApp/Tests/GitReviewItAppTests/UnitTests/GitHubAPIClientTests.swift
- [X] T043 [US3] Add team filtering logic to FilterEngine (map teams to repos in Stage 1) in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Services/FilterEngine.swift
- [X] T044 [P] [US3] Add FilterEngine unit tests for team filter and empty team metadata in app/GitReviewItApp/Tests/GitReviewItAppTests/UnitTests/FilterEngineTests.swift
- [X] T045 [US3] Add metadata property with LoadingState teams to FilterState in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/State/FilterState.swift
- [X] T046 [US3] Add updateMetadata method to FilterState that calls FilterMetadata.from and fetches teams in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/State/FilterState.swift
- [X] T047 [US3] Call filterState.updateMetadata when PRs load in PullRequestListContainer in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/State/PullRequestListContainer.swift
- [X] T048 [US3] Add Teams section to FilterSheet with unavailable message when teams can't load in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/FilterSheet.swift
- [X] T049 [US3] Handle team filter validation on relaunch (clear invalid team filters, show notice) in FilterState
- [X] T050 [US3] Create integration tests for team filtering scenarios in app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/PRFilteringTests.swift
- [X] T051 [US3] Create integration tests for graceful degradation when teams unavailable in app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/PRFilteringTests.swift
- [X] T052 [US3] Manual test: Verify team filtering works, graceful degradation on 403, other filters continue working, unavailable message clear

**Checkpoint**: User Story 3 complete - team filtering functional with graceful degradation

---

## Phase 6: User Story 4 - Combine Search and Filters (Priority: P2)

**Goal**: Enable users to combine fuzzy search with structured filters for powerful filtering workflows (intersection of results)

**Independent Test**: Apply search queries along with org/repo/team filters and verify both apply correctly (AND logic). Clearing search leaves filters active, clearing filters leaves search active.

**Acceptance Criteria from Spec**:
- Filter by org "CompanyA" + search "bug fix" shows only CompanyA PRs matching "bug fix"
- Search "api" + repo filter "backend-service" shows only backend-service PRs matching "api"
- Clear search leaves structured filters active
- Clear filters leaves search query active
- Combined empty results show "No PRs match your search and filters" with adjustment options

### Implementation for User Story 4

- [x] T053 [US4] Verify FilterEngine.apply combines structured filters and fuzzy search correctly (already implemented in T014)
- [x] T054 [P] [US4] Add integration tests for combined search and filter scenarios in app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/PRFilteringTests.swift
- [x] T055 [US4] Update empty state message in PullRequestListView to distinguish "search and filters" vs "search only" vs "filters only" in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PullRequestListView.swift
- [x] T056 [US4] Add clearSearchQuery method to FilterState and wire to UI in app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/State/FilterState.swift (already implemented in T020)
- [x] T057 [US4] Manual test: Verify search + filter combinations work, clearing search leaves filters, clearing filters leaves search, empty states accurate

**Checkpoint**: User Story 4 complete - all filtering features integrated and working together

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements affecting multiple user stories

- [x] T058 [P] Create test fixture with 500 PRs in app/GitReviewItApp/Tests/GitReviewItAppTests/Fixtures/prs-with-varied-data.json
- [x] T059 Performance test: Measure filtering time with 500 PR dataset (must be <500ms)
- [x] T060 Performance test: Verify search debouncing works smoothly (no perceived lag)
- [x] T061 [P] Accessibility audit: Run VoiceOver and verify all filter controls have descriptive labels
- [x] T062 Accessibility audit: Test keyboard navigation in FilterSheet
- [x] T063 [P] Add inline documentation to FilterEngine, FuzzyMatcher, FilterState
- [x] T064 Update README.md with PR filtering feature description and screenshots
- [x] T065 Review all error messages for clarity and actionability
- [x] T066 Final manual testing pass: All user scenarios from spec.md
- [x] T067 Run just test to verify all tests pass
- [x] T068 Run just lint to verify code style compliance
- [x] T069 Validate quickstart.md implementation sequence matches actual implementation

**Checkpoint**: Feature complete, tested, documented, and ready for review

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational completion
  - US1 (Phase 3): Can start immediately after Foundational
  - US2 (Phase 4): Can start after Foundational (builds on US1 but independently testable)
  - US3 (Phase 5): Can start after Foundational (builds on US1+US2 but independently testable)
  - US4 (Phase 6): Requires US1 and US2 complete (validates integration)
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (P1)**: Independent - only depends on Foundational (T003-T011)
- **US2 (P2)**: Independent - only depends on Foundational (T003-T011)
- **US3 (P3)**: Independent - only depends on Foundational (T003-T011)
- **US4 (P2)**: Depends on US1 (T012-T022) and US2 (T023-T038) - validates their integration

### Parallel Execution Opportunities

**Within Foundational Phase** (T003-T010):
- All tasks can run in parallel (different files, no dependencies)

**Within US1** (T012-T022):
- T012 (FuzzyMatcher impl) || T013 (FuzzyMatcher tests) - parallel
- T015 (FilterEngine tests) can start once T014 (FilterEngine impl) is done

**Within US2** (T023-T038):
- T023 (FilterPersistence impl) || T024 (FilterPersistence tests) - parallel
- T026 (FilterEngine tests) can start once T025 (FilterEngine update) is done
- T030-T032 (FilterSheet creation) can happen in parallel with T027-T029 (FilterState updates)

**Within US3** (T039-T052):
- T039-T040 (GitHubAPI extension) || T041-T042 (tests + fixture) - parallel
- T043-T044 (FilterEngine team logic + tests) can happen in parallel
- T048 (FilterSheet team section) can happen independently

**Within Polish Phase** (T058-T069):
- T058 (fixture creation) || T061 (VoiceOver audit) || T063 (documentation) - all parallel

### MVP Recommendation

**Minimum Viable Product**: Phase 3 (User Story 1) only
- Delivers fuzzy search functionality
- Provides immediate value for finding PRs
- Fully functional without structured filters
- ~7 days estimated (Foundational + US1)

**Full Feature**: All phases
- Complete filtering solution
- ~10-14 days estimated total

---

## Execution Strategy

### Incremental Delivery

1. **Week 1**: Foundational + US1 (MVP)
   - T001-T022 (Setup + Foundational + Fuzzy Search)
   - Deliverable: Working fuzzy search
   - Value: Users can quickly find PRs by search

2. **Week 2**: US2 + US4
   - T023-T038 (Organization and Repository Filters)
   - T053-T057 (Combined Search + Filters)
   - Deliverable: Persistent structured filters + search integration
   - Value: Users can save filter preferences and combine with search

3. **Week 3**: US3 + Polish
   - T039-T052 (Team Filtering)
   - T058-T069 (Performance, Accessibility, Documentation)
   - Deliverable: Complete feature with team support
   - Value: Full organizational filtering with graceful degradation

### Testing Strategy

**Unit Tests** (Run after each implementation task):
- StringSimilarity (T004)
- FuzzyMatcher (T013, T015)
- FilterConfiguration, FilterMetadata (covered in T009-T010)
- FilterPersistence (T024)
- FilterEngine (T015, T026, T044)

**Integration Tests** (Run after phase completion):
- FilterState debouncing and persistence (T021, T036)
- PRFiltering scenarios (T037, T050, T051, T054)

**Manual Tests** (Run at checkpoints):
- US1 checkpoint (T022)
- US2 checkpoint (T038)
- US3 checkpoint (T052)
- US4 checkpoint (T057)
- Final testing (T066)

---

## Task Statistics

**Total Tasks**: 69
- Setup: 2 tasks
- Foundational: 9 tasks (8 parallelizable)
- User Story 1: 11 tasks (4 parallelizable)
- User Story 2: 16 tasks (6 parallelizable)
- User Story 3: 14 tasks (5 parallelizable)
- User Story 4: 5 tasks (1 parallelizable)
- Polish: 12 tasks (4 parallelizable)

**Parallel Opportunities**: 28 tasks can run in parallel (~41% of total)

**Independent User Stories**: US1, US2, US3 can all be developed in parallel after Foundational phase

**Estimated Timeline**:
- Sequential execution: ~14 days
- With parallelization: ~8-10 days
- MVP only (US1): ~5-7 days

---

## Risk Mitigation

### Risk: Performance degradation with large datasets
**Mitigation Tasks**: T059 (performance testing with 500 PRs)
**Monitoring**: T060 (debouncing smoothness)

### Risk: Team API permissions missing
**Mitigation Tasks**: T051 (graceful degradation tests)
**Design**: LoadingState pattern handles all team availability scenarios

### Risk: Filter persistence corruption
**Mitigation Tasks**: T024 (corrupted data handling), T036 (persistence tests)
**Design**: Versioned schema with graceful fallback to empty

### Risk: Accessibility compliance
**Mitigation Tasks**: T061 (VoiceOver), T062 (keyboard navigation)

---

## Success Validation

**Performance** (T059-T060):
- [ ] Filtering completes <500ms for 500 PRs
- [ ] Search debouncing feels instant (<100ms perceived latency)

**Functionality** (T022, T038, T052, T057):
- [ ] All user scenarios from spec.md pass manual testing
- [ ] Empty states display appropriate messages
- [ ] Filters persist correctly across launches

**Quality** (T067-T068):
- [ ] `just test` passes (all unit and integration tests)
- [ ] `just lint` passes (code style compliance)

**Accessibility** (T061-T062):
- [ ] VoiceOver labels present and descriptive
- [ ] Keyboard navigation works in all UI

**Documentation** (T063-T064):
- [ ] Inline documentation complete
- [ ] README updated with feature description
