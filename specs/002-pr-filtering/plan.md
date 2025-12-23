# Implementation Plan: PR Filtering

**Branch**: `002-pr-filtering` | **Date**: December 23, 2025 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-pr-filtering/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Add filtering capabilities to the PR list to enable users to quickly find relevant PRs. This includes transient fuzzy search (PR title, repository, author) with ranked results, and persistent structured filters (organization, repository, team) that survive app restarts. All filtering operates client-side on the locally available PR dataset, with graceful degradation when team data is unavailable.

**Technical Approach**: Implement a composable filtering pipeline that applies structured filters first, then fuzzy search, producing ranked deterministic output. Use UserDefaults for filter persistence, implement fuzzy matching using Levenshtein distance + prefix matching, and debounce search input. Team metadata fetched from GitHub Teams API when `read:org` scope is available.

## Technical Context

**Language/Version**: Swift 6.0 with strict concurrency checking  
**UI Framework**: SwiftUI with Observation framework (`@Observable`, `@State`)  
**Primary Dependencies**: None (stdlib only)  
**Storage**: UserDefaults for filter persistence; Keychain already used for credentials  
**Testing**: Swift Testing (using `@Test` attribute with backtick function names)  
**Target Platform**: macOS 14.0+  
**Architecture**: Unidirectional data flow with view-owned state containers  
**Deployment Target**: macOS 14.0  
**Performance Goals**: Filtering operations complete within 500ms for datasets up to 500 PRs; search results appear instantly (<100ms) with debouncing  
**Constraints**: Client-side only (no backend); offline-first filtering; graceful degradation for team API failures  
**Scale/Scope**: ~10-500 PRs per user; ~5-20 orgs; ~10-100 repos; ~5-50 teams

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

**Constitution Compliance Summary**: ✅ All principles satisfied. No violations. Feature follows existing architecture patterns (Observable state containers, protocol-based dependencies, view-owned state). Filtering is pure logic (testable without SwiftUI), persistence uses standard UserDefaults, team API access gracefully degrades.

## Project Structure

### Documentation (this feature)

```text
specs/002-pr-filtering/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── protocols.md     # Protocol definitions for filtering services
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
app/GitReviewItApp/Sources/GitReviewItApp/
├── Features/
│   └── PullRequests/  [EXISTING, TO BE EXTENDED]
│       ├── Views/
│       │   ├── PullRequestListView.swift           [TO MODIFY - add search + filters UI]
│       │   ├── PullRequestRow.swift                [EXISTING]
│       │   ├── FilterSheet.swift                   [TO CREATE - filter selection UI]
│       │   └── FilterChipsView.swift               [TO CREATE - active filter display]
│       ├── State/
│       │   ├── PullRequestListContainer.swift      [TO MODIFY - add filtering logic]
│       │   └── FilterState.swift                   [TO CREATE - filter configuration state]
│       ├── Models/
│       │   ├── PullRequest.swift                   [EXISTING]
│       │   ├── FilterConfiguration.swift           [TO CREATE - persistent filter model]
│       │   └── FilterMetadata.swift                [TO CREATE - available orgs/repos/teams]
│       └── Services/
│           ├── FilterEngine.swift                  [TO CREATE - filtering pipeline]
│           ├── FuzzyMatcher.swift                  [TO CREATE - fuzzy search logic]
│           └── FilterPersistence.swift             [TO CREATE - UserDefaults wrapper]
├── Infrastructure/
│   ├── Networking/
│   │   └── GitHubAPI.swift                         [TO MODIFY - add fetchTeams method]
│   └── Storage/
│       └── CredentialStorage.swift                  [EXISTING]
└── Shared/
    ├── Models/
    │   ├── Team.swift                               [TO CREATE - GitHub team model]
    │   ├── APIError.swift                           [EXISTING]
    │   └── LoadingState.swift                       [EXISTING]
    └── Utilities/
        └── StringSimilarity.swift                   [TO CREATE - Levenshtein distance]

app/GitReviewItApp/Tests/GitReviewItAppTests/
├── UnitTests/
│   ├── FilterEngineTests.swift                      [TO CREATE]
│   ├── FuzzyMatcherTests.swift                      [TO CREATE]
│   ├── FilterPersistenceTests.swift                 [TO CREATE]
│   └── StringSimilarityTests.swift                  [TO CREATE]
├── IntegrationTests/
│   ├── PRFilteringTests.swift                       [TO CREATE - full filtering scenarios]
│   └── FilterRestoreTests.swift                     [TO CREATE - persistence scenarios]
└── Fixtures/
    ├── teams-response.json                          [EXISTING]
    └── prs-with-varied-data.json                    [TO CREATE - diverse PR dataset]
```

**Structure Decision**: Extend the existing feature-oriented organization under `Features/PullRequests/`. Filtering is a capability of the PR list feature, not a separate feature. Keep filtering logic colocated with PR list state and views for clarity and maintainability. Extract pure utility functions (fuzzy matching, string similarity) to `Shared/Utilities/` for reuse.

## Complexity Tracking

> **No violations to justify**. All Constitution principles are satisfied by this feature's design.

---

## Implementation Steps: PR-Sized Increments

The following steps break down implementation into small, reviewable PRs. Each step is independently testable and delivers incremental value.

---

### **Step 1: String Similarity Utilities**

**Goal**: Implement Levenshtein distance algorithm for fuzzy matching foundation.

**User-Visible Outcome**: None (internal utility).

**Files to Create**:
- `app/GitReviewItApp/Sources/GitReviewItApp/Shared/Utilities/StringSimilarity.swift`
- `app/GitReviewItApp/Tests/GitReviewItAppTests/UnitTests/StringSimilarityTests.swift`

**Public Interface**:
```swift
/// Calculate Levenshtein distance between two strings
func levenshteinDistance(_ str1: String, _ str2: String) -> Int

/// Calculate normalized similarity score (0.0 to 1.0)
func similarityScore(_ str1: String, _ str2: String) -> Double
```

**Main Logic**:
- Implement standard dynamic programming Levenshtein algorithm
- Add similarity score normalization: `1.0 - (distance / max(len1, len2))`
- Handle edge cases: empty strings, identical strings

**Tests**:
- `levenshteinDistance matches known values for standard test pairs`
- `levenshteinDistance returns 0 for identical strings`
- `levenshteinDistance returns length for completely different strings`
- `similarityScore returns 1.0 for identical strings`
- `similarityScore returns values between 0.0 and 1.0`

**Acceptance Criteria**:
- [ ] Levenshtein distance correctly computed for all test cases
- [ ] Similarity score normalized to 0.0-1.0 range
- [ ] Edge cases handled (empty strings, identical strings)
- [ ] All unit tests pass
- [ ] Performance acceptable for typical query lengths (<100 chars)

---

### **Step 2: Fuzzy Matcher Service**

**Goal**: Implement fuzzy matching logic with weighted scoring and ranking.

**User-Visible Outcome**: None (internal service).

**Files to Create**:
- `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Services/FuzzyMatcher.swift`
- `app/GitReviewItApp/Tests/GitReviewItAppTests/UnitTests/FuzzyMatcherTests.swift`

**Public Interface**:
```swift
protocol FuzzyMatcherProtocol {
    func match(query: String, in pullRequests: [PullRequest]) -> [PullRequest]
}

struct FuzzyMatcher: FuzzyMatcherProtocol {
    func match(query: String, in pullRequests: [PullRequest]) -> [PullRequest]
}
```

**Main Logic**:
- Match query against PR title (weight: 3.0), repository (weight: 2.0), author (weight: 1.5)
- Score types: exact match (1.0), prefix (0.9), substring (0.7), fuzzy (0.0-0.6)
- Return PRs sorted by score descending, then by PR number ascending (tie-breaking)
- Filter out PRs with zero score

**Tests**:
- `match returns exact matches with highest score`
- `match returns prefix matches with high score`
- `match returns substring matches with medium score`
- `match handles typos with fuzzy scoring`
- `match filters out PRs with no match`
- `match tie-breaks by PR number when scores are equal`
- `match returns empty array for empty query`
- `match returns all PRs when query matches all`

**Acceptance Criteria**:
- [ ] Fuzzy matching scores PRs correctly by match quality
- [ ] Tie-breaking is deterministic (by PR number)
- [ ] Empty query returns all PRs
- [ ] Zero-score PRs are filtered out
- [ ] All unit tests pass

---

### **Step 3: Domain Models (FilterConfiguration, FilterMetadata, Team)**

**Goal**: Define data models for filters, metadata, and teams.

**User-Visible Outcome**: None (internal models).

**Files to Create**:
- `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Models/FilterConfiguration.swift`
- `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Models/FilterMetadata.swift`
- `app/GitReviewItApp/Sources/GitReviewItApp/Shared/Models/Team.swift`
- `app/GitReviewItApp/Tests/GitReviewItAppTests/UnitTests/FilterConfigurationTests.swift`
- `app/GitReviewItApp/Tests/GitReviewItAppTests/UnitTests/FilterMetadataTests.swift`

**Public Interfaces**:
```swift
struct FilterConfiguration: Codable, Equatable {
    let version: Int = 1
    var selectedOrganizations: Set<String>
    var selectedRepositories: Set<String>
    var selectedTeams: Set<String>
    
    static let empty: FilterConfiguration
}

struct FilterMetadata {
    let organizations: Set<String>
    let repositories: Set<String>
    let teams: LoadingState<[Team]>
    
    var areTeamsAvailable: Bool
    var sortedOrganizations: [String]
    var sortedRepositories: [String]
    
    static func from(pullRequests: [PullRequest]) -> FilterMetadata
}

struct Team: Codable, Equatable, Identifiable {
    let slug: String
    let name: String
    let organizationLogin: String
    let repositories: [String]
}
```

**Main Logic**:
- FilterConfiguration: Codable for persistence, empty default
- FilterMetadata: Derive orgs/repos from PR list, teams loaded separately
- Team: Map from GitHub API response

**Tests**:
- `FilterConfiguration Codable round-trip preserves all fields`
- `FilterConfiguration empty has all sets empty`
- `FilterMetadata derives organizations from PR list correctly`
- `FilterMetadata derives repositories from PR list correctly`
- `FilterMetadata sortedOrganizations returns alphabetically sorted list`
- `Team Codable round-trip preserves all fields`

**Acceptance Criteria**:
- [ ] FilterConfiguration encodes/decodes correctly
- [ ] FilterMetadata derives orgs/repos from PRs
- [ ] Team model maps from API response
- [ ] All unit tests pass

---

### **Step 4: Filter Engine Service**

**Goal**: Implement filtering pipeline (structured filters → fuzzy search).

**User-Visible Outcome**: None (internal service).

**Files to Create**:
- `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Services/FilterEngine.swift`
- `app/GitReviewItApp/Tests/GitReviewItAppTests/UnitTests/FilterEngineTests.swift`

**Public Interface**:
```swift
protocol FilterEngineProtocol {
    func apply(
        configuration: FilterConfiguration,
        searchQuery: String,
        to pullRequests: [PullRequest],
        teamMetadata: [Team]
    ) -> [PullRequest]
}

struct FilterEngine: FilterEngineProtocol {
    private let fuzzyMatcher: FuzzyMatcherProtocol
    
    init(fuzzyMatcher: FuzzyMatcherProtocol = FuzzyMatcher())
    
    func apply(...) -> [PullRequest]
}
```

**Main Logic**:
- Stage 1: Apply organization filter (if any)
- Stage 1: Apply repository filter (if any)
- Stage 1: Apply team filter (if any, map teams to repos)
- Stage 2: Apply fuzzy search (if query non-empty)
- Return filtered results

**Tests**:
- `apply filters by organization correctly`
- `apply filters by repository correctly`
- `apply filters by team correctly`
- `apply combines multiple structured filters (AND logic)`
- `apply applies fuzzy search after structured filters`
- `apply returns all PRs when no filters active`
- `apply returns empty array when all PRs filtered out`
- `apply handles empty team metadata gracefully`

**Acceptance Criteria**:
- [ ] Structured filters apply correctly (org, repo, team)
- [ ] Multiple filters combine with AND logic
- [ ] Fuzzy search applies after structured filters
- [ ] Empty configuration/query passes all PRs through
- [ ] All unit tests pass

---

### **Step 5: Filter Persistence Service**

**Goal**: Implement persistence for filter configuration using UserDefaults.

**User-Visible Outcome**: None (internal service).

**Files to Create**:
- `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Services/FilterPersistence.swift`
- `app/GitReviewItApp/Tests/GitReviewItAppTests/UnitTests/FilterPersistenceTests.swift`

**Public Interface**:
```swift
protocol FilterPersistence: Sendable {
    func save(_ configuration: FilterConfiguration) async throws
    func load() async throws -> FilterConfiguration?
    func clear() async throws
}

final class UserDefaultsFilterPersistence: FilterPersistence {
    init(defaults: UserDefaults = .standard)
}
```

**Main Logic**:
- Save: Encode FilterConfiguration to JSON, store in UserDefaults
- Load: Retrieve JSON from UserDefaults, decode to FilterConfiguration
- Clear: Remove key from UserDefaults
- Handle missing data (return nil), corrupted data (throw error)

**Tests**:
- `save and load round-trip preserves configuration`
- `load returns nil when no configuration saved`
- `load throws error for corrupted data`
- `clear removes configuration from storage`

**Acceptance Criteria**:
- [ ] Save/load round-trip works correctly
- [ ] Missing data returns nil (not error)
- [ ] Corrupted data throws error
- [ ] Clear removes data
- [ ] All unit tests pass

---

### **Step 6: FilterState Container**

**Goal**: Create observable state container for filter configuration, metadata, and search.

**User-Visible Outcome**: None (state management, no UI changes yet).

**Files to Create**:
- `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/State/FilterState.swift`
- `app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/FilterStateTests.swift`

**Public Interface**:
```swift
@Observable
@MainActor
final class FilterState {
    private(set) var configuration: FilterConfiguration
    private(set) var metadata: FilterMetadata
    private(set) var searchQuery: String
    var isShowingFilterSheet: Bool
    
    init(persistence: FilterPersistence)
    
    func loadPersistedConfiguration() async
    func updateFilterConfiguration(_ config: FilterConfiguration) async
    func clearAllFilters() async
    func updateSearchQuery(_ query: String)
    func clearSearchQuery()
    func updateMetadata(from: [PullRequest])
}
```

**Main Logic**:
- Initialize with empty configuration and metadata
- loadPersistedConfiguration: Load from persistence on init
- updateFilterConfiguration: Update + persist immediately
- updateSearchQuery: Debounce with 300ms delay using Task cancellation
- updateMetadata: Derive orgs/repos from PR list

**Tests**:
- `loadPersistedConfiguration restores saved configuration`
- `updateFilterConfiguration persists immediately`
- `clearAllFilters resets to empty and persists`
- `updateSearchQuery debounces with 300ms delay`
- `clearSearchQuery resets to empty string`
- `updateMetadata derives orgs and repos from PRs`

**Acceptance Criteria**:
- [ ] Configuration persists across FilterState instances
- [ ] Search query debouncing works (300ms)
- [ ] Metadata derives correctly from PR list
- [ ] All integration tests pass

---

### **Step 7: Extend GitHubAPI with fetchTeams**

**Goal**: Add team fetching capability to GitHub API client.

**User-Visible Outcome**: None (API extension).

**Files to Modify**:
- `app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/GitHubAPI.swift` (add method to protocol)
- `app/GitReviewItApp/Sources/GitReviewItApp/Infrastructure/Networking/GitHubAPIClient.swift` (implement method)
- `app/GitReviewItApp/Tests/GitReviewItAppTests/UnitTests/GitHubAPIClientTests.swift` (add tests)

**Files to Create**:
- `app/GitReviewItApp/Tests/GitReviewItAppTests/Fixtures/teams-full-response.json` (new fixture with repo data)

**New Method**:
```swift
protocol GitHubAPI {
    func fetchTeams(credentials: GitHubCredentials) async throws -> [Team]
}
```

**Main Logic**:
- GET {baseURL}/user/teams
- Parse TeamDTO response
- For each team, fetch repositories from team repositories_url
- Map to Team domain model
- Handle 403 (missing read:org scope) gracefully

**Tests**:
- `fetchTeams returns teams on success`
- `fetchTeams throws unauthorized on 401`
- `fetchTeams throws forbidden on 403`
- `fetchTeams returns empty array when user has no teams`

**Acceptance Criteria**:
- [ ] fetchTeams method added to protocol and implemented
- [ ] Teams fetched and mapped to domain model correctly
- [ ] 403 error handled (missing read:org scope)
- [ ] All unit tests pass

---

### **Step 8: Integrate FilterState into PullRequestListContainer**

**Goal**: Add filtering capability to PR list container.

**User-Visible Outcome**: None (state management, no UI changes yet).

**Files to Modify**:
- `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/State/PullRequestListContainer.swift`

**Files to Create**:
- `app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/PRFilteringTests.swift`

**Changes to PullRequestListContainer**:
```swift
@Observable
@MainActor
final class PullRequestListContainer {
    private(set) var loadingState: LoadingState<[PullRequest]> = .idle
    private(set) var filterState: FilterState
    private let filterEngine: FilterEngineProtocol
    
    var filteredPullRequests: [PullRequest] {
        guard case .loaded(let allPRs) = loadingState else { return [] }
        return filterEngine.apply(
            configuration: filterState.configuration,
            searchQuery: filterState.searchQuery,
            to: allPRs,
            teamMetadata: filterState.metadata.teams.value ?? []
        )
    }
    
    // Call when PRs load
    private func updateFilterMetadata() {
        guard case .loaded(let prs) = loadingState else { return }
        filterState.updateMetadata(from: prs)
    }
}
```

**Main Logic**:
- Add filterState property
- Add filterEngine dependency
- Compute filteredPullRequests using filterEngine
- Update filter metadata when PRs load

**Tests**:
- `filteredPullRequests applies organization filter`
- `filteredPullRequests applies repository filter`
- `filteredPullRequests applies search query`
- `filteredPullRequests combines filters and search`
- `filteredPullRequests returns all PRs when no filters active`

**Acceptance Criteria**:
- [ ] filterState integrated into container
- [ ] filteredPullRequests computed correctly
- [ ] Filter metadata updates when PRs load
- [ ] All integration tests pass

---

### **Step 9: FilterChipsView UI Component**

**Goal**: Create view to display active filters as dismissible chips.

**User-Visible Outcome**: Active filters appear above PR list.

**Files to Create**:
- `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/FilterChipsView.swift`

**Public Interface**:
```swift
struct FilterChipsView: View {
    let configuration: FilterConfiguration
    let onRemoveOrganization: (String) -> Void
    let onRemoveRepository: (String) -> Void
    let onRemoveTeam: (String) -> Void
    
    var body: some View { ... }
}
```

**Main Logic**:
- Horizontal ScrollView with chips
- Each chip shows icon + label + X button
- Tapping X calls appropriate onRemove closure
- Chips hidden when configuration is empty

**Acceptance Criteria**:
- [ ] Chips display for active filters
- [ ] X button removes individual filter
- [ ] View hidden when no filters active
- [ ] Accessible with VoiceOver
- [ ] Visual testing via Xcode Previews

---

### **Step 10: FilterSheet UI Component**

**Goal**: Create sheet for selecting filters (organizations, repositories, teams).

**User-Visible Outcome**: Users can open filter sheet and select filters.

**Files to Create**:
- `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/FilterSheet.swift`

**Public Interface**:
```swift
struct FilterSheet: View {
    @Binding var configuration: FilterConfiguration
    let metadata: FilterMetadata
    let onApply: () -> Void
    let onCancel: () -> Void
    
    var body: some View { ... }
}
```

**Main Logic**:
- NavigationStack with Form
- Three sections: Organizations, Repositories, Teams
- Toggle for each option (multi-select)
- Apply button saves and dismisses
- Cancel button dismisses without saving
- Clear All button resets all selections
- Teams section shows unavailable message if teams can't load

**Acceptance Criteria**:
- [ ] Filter sheet presents as sheet
- [ ] Organizations/repositories/teams displayed in sections
- [ ] Selections persist while sheet is open
- [ ] Apply button saves and dismisses
- [ ] Cancel button dismisses without saving
- [ ] Clear All button resets selections
- [ ] Teams unavailable message shown when appropriate
- [ ] Accessible with VoiceOver
- [ ] Visual testing via Xcode Previews

---

### **Step 11: Add Search Bar and Filter Button to PullRequestListView**

**Goal**: Add UI for search and filter controls to PR list view.

**User-Visible Outcome**: Users can search PRs and open filter sheet.

**Files to Modify**:
- `app/GitReviewItApp/Sources/GitReviewItApp/Features/PullRequests/Views/PullRequestListView.swift`

**Changes to PullRequestListView**:
```swift
struct PullRequestListView: View {
    @State private var container: PullRequestListContainer
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            TextField("Search pull requests", text: Binding(
                get: { container.filterState.searchQuery },
                set: { container.filterState.updateSearchQuery($0) }
            ))
            .textFieldStyle(.roundedBorder)
            .padding()
            
            // Filter chips
            if !container.filterState.configuration.isEmpty {
                FilterChipsView(
                    configuration: container.filterState.configuration,
                    onRemoveOrganization: { org in /* remove org */ },
                    onRemoveRepository: { repo in /* remove repo */ },
                    onRemoveTeam: { team in /* remove team */ }
                )
            }
            
            // Existing PR list (now using filteredPullRequests)
            List(container.filteredPullRequests) { pr in
                PullRequestRow(pullRequest: pr)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Filter") {
                    container.filterState.isShowingFilterSheet = true
                }
            }
        }
        .sheet(isPresented: $container.filterState.isShowingFilterSheet) {
            FilterSheet(...)
        }
    }
}
```

**Main Logic**:
- Add search TextField binding to filterState.searchQuery
- Add FilterChipsView above list
- Change List to use container.filteredPullRequests
- Add Filter button in toolbar
- Present FilterSheet as sheet

**Acceptance Criteria**:
- [ ] Search bar visible above list
- [ ] Search query updates as user types
- [ ] Filter chips appear when filters active
- [ ] Tapping chip removes that filter
- [ ] Filter button opens filter sheet
- [ ] PR list shows filtered results
- [ ] Empty state message when filters exclude all PRs
- [ ] Manual end-to-end testing complete

---

### **Step 12: Integration Tests for Full Filtering Scenarios**

**Goal**: Validate end-to-end filtering behavior with integration tests.

**User-Visible Outcome**: None (testing).

**Files to Create**:
- `app/GitReviewItApp/Tests/GitReviewItAppTests/IntegrationTests/FilterRestoreTests.swift`
- `app/GitReviewItApp/Tests/GitReviewItAppTests/Fixtures/prs-with-varied-data.json`

**Test Coverage**:
- Fuzzy search scenarios (exact, prefix, substring, typo)
- Structured filter scenarios (org, repo, team, combinations)
- Combined search + filter scenarios
- Persistence scenarios (save → relaunch → restore)
- Graceful degradation scenarios (teams unavailable)
- Empty state scenarios (no PRs match filters)

**Acceptance Criteria**:
- [ ] All user scenarios from spec covered by tests
- [ ] Persistence and restore tested
- [ ] Teams unavailable scenario tested
- [ ] Empty states tested
- [ ] All integration tests pass

---

### **Step 13: Performance Validation and Accessibility Audit**

**Goal**: Validate performance goals and accessibility compliance.

**User-Visible Outcome**: None (validation).

**Tasks**:
- Create test fixture with 500 PRs
- Measure filtering time (must be <500ms)
- Measure search debounce behavior
- Run VoiceOver and verify labels for all controls
- Test keyboard navigation in filter sheet
- Verify empty state messages are clear

**Acceptance Criteria**:
- [ ] Filtering completes <500ms for 500 PR dataset
- [ ] Search debouncing works smoothly (no lag)
- [ ] VoiceOver labels present and descriptive
- [ ] Keyboard navigation works in filter sheet
- [ ] Empty state messages are clear and actionable
- [ ] Performance and accessibility validated

---

### **Step 14: Documentation and Polish**

**Goal**: Complete documentation and final polish.

**User-Visible Outcome**: None (documentation).

**Tasks**:
- Add inline documentation to FilterEngine, FuzzyMatcher
- Update README with filter feature description
- Add screenshots of filter UI to docs
- Review all error messages for clarity
- Final manual testing pass

**Acceptance Criteria**:
- [ ] Inline documentation complete
- [ ] README updated with feature description
- [ ] Error messages reviewed and clear
- [ ] Final manual testing complete
- [ ] All tests pass (`just test`)
- [ ] Code style compliant (`just lint`)

---

## Testing Summary

### Unit Tests (Pure Logic)
- StringSimilarity: Levenshtein distance and scoring
- FuzzyMatcher: Match ranking and tie-breaking
- FilterEngine: Structured filters and combinations
- FilterConfiguration: Codable round-trip
- FilterMetadata: Derivation from PRs
- FilterPersistence: Save/load/clear operations

### Integration Tests (Collaborating Components)
- FilterState: Persistence, debouncing, metadata updates
- PullRequestListContainer: Filtered results computation
- PRFilteringTests: Full filtering scenarios
- FilterRestoreTests: Persistence across launches

### Manual Tests (UI Verification)
- Search debouncing feels responsive
- Filter sheet presents/dismisses correctly
- Filter chips display and remove correctly
- Empty states show correct messages
- VoiceOver announces controls correctly
- Keyboard navigation works

---

## Rollout Plan

### Incremental Delivery Strategy

**Phase 1: Foundation (Steps 1-5)** - ~2-3 days
- Pure logic, no UI changes
- Fully testable
- No user-visible impact
- Can merge to main incrementally

**Phase 2: State Integration (Steps 6-8)** - ~1-2 days
- Wire up state management
- Still no UI changes
- Integration tests validate behavior

**Phase 3: UI Components (Steps 9-11)** - ~2-3 days
- User-visible UI changes
- Search bar and filter controls appear
- Full feature functional

**Phase 4: Testing & Polish (Steps 12-14)** - ~1-2 days
- Comprehensive test coverage
- Performance validation
- Documentation

**Total Estimated Time**: ~6-10 days

---

## Risk Mitigation

### Risk: Performance degradation with large PR datasets

**Mitigation**: 
- Structured filters first (cheap Set operations)
- Fuzzy search on reduced dataset
- Performance validation with 500 PR test fixture

### Risk: Team API permissions missing

**Mitigation**:
- Graceful degradation built in from start
- Clear messaging when teams unavailable
- Other filters continue to work

### Risk: Filter persistence corruption

**Mitigation**:
- Versioned schema with migration path
- Handle corrupted data gracefully (reset to default)
- Clear All button provides manual recovery

---

## Dependencies

- Existing PR list feature (001-github-pr-viewer) must be complete
- No external library dependencies (stdlib only)
- GitHub API `/user/teams` endpoint (optional, graceful degradation)

---

## Success Metrics

- Filtering completes <500ms for 500 PRs ✅
- Search debouncing feels instant (<100ms perceived latency) ✅
- All constitution principles satisfied ✅
- Zero external dependencies added ✅
- 100% test coverage for core filtering logic ✅
