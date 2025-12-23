# Developer Quickstart Guide: PR Filtering

**Feature**: PR Filtering  
**Date**: December 23, 2025  
**Purpose**: Onboarding guide for developers implementing PR filtering feature

## Overview

This feature adds filtering capabilities to the existing PR list:
- **Fuzzy search**: Transient search across PR title, repository, and author
- **Structured filters**: Persistent filters by organization, repository, and team
- **Graceful degradation**: Teams unavailable → other filters still work
- **Offline-first**: All filtering operates on local PR data

## Prerequisites

- Existing PR list feature implemented (feature 001-github-pr-viewer)
- Familiarity with SwiftUI and Observation framework
- Understanding of unidirectional data flow pattern
- Knowledge of async/await and Swift Concurrency

## Architecture Quick Reference

```
PullRequestListView (SwiftUI)
    ↓ owns via @State
PullRequestListContainer (@Observable)
    ├─ loadingState: LoadingState<[PullRequest]>
    ├─ filterState: FilterState
    └─ filteredPullRequests (computed property)
           │
           ├─ applies FilterEngine
           └─ returns filtered PRs

FilterState (@Observable)
    ├─ configuration: FilterConfiguration (persisted)
    ├─ metadata: FilterMetadata (derived from PRs)
    ├─ searchQuery: String (transient)
    └─ dependencies: FilterPersistence, FuzzyMatcher

FilterEngine (pure logic)
    ├─ apply structured filters (org → repo → team)
    └─ apply fuzzy search (ranked results)
```

## Implementation Sequence

Follow this order to minimize coupling and enable incremental testing:

### Phase 1: Foundation (Pure Logic, No UI)

1. **StringSimilarity utility** (`Shared/Utilities/StringSimilarity.swift`)
   - Implement Levenshtein distance algorithm
   - Add prefix/substring scoring helpers
   - Unit test with known distance pairs

2. **FuzzyMatcher** (`Features/PullRequests/Services/FuzzyMatcher.swift`)
   - Implement fuzzy matching logic with weighted scores
   - Use StringSimilarity for scoring
   - Unit test ranking and tie-breaking

3. **FilterEngine** (`Features/PullRequests/Services/FilterEngine.swift`)
   - Implement two-stage filtering pipeline
   - Inject FuzzyMatcher as dependency
   - Unit test each filter type independently + combinations

### Phase 2: Models & Persistence

4. **FilterConfiguration model** (`Features/PullRequests/Models/FilterConfiguration.swift`)
   - Define struct with Codable conformance
   - Add `empty` static property for defaults
   - Unit test Codable round-trip

5. **FilterMetadata model** (`Features/PullRequests/Models/FilterMetadata.swift`)
   - Define struct with computed properties
   - Add static `from([PullRequest])` derivation method
   - Unit test derivation logic

6. **Team model** (`Shared/Models/Team.swift`)
   - Define struct with Codable conformance
   - Add mapping from TeamDTO (API response)
   - Unit test Codable and mapping

7. **FilterPersistence protocol + implementation** (`Features/PullRequests/Services/FilterPersistence.swift`)
   - Define protocol
   - Implement UserDefaultsFilterPersistence
   - Unit test save/load/clear operations

### Phase 3: State Management

8. **FilterState** (`Features/PullRequests/State/FilterState.swift`)
   - Create @Observable class
   - Implement all intent methods
   - Add debouncing for search query
   - Integration test persistence + debouncing

9. **Extend PullRequestListContainer** (`Features/PullRequests/State/PullRequestListContainer.swift`)
   - Add filterState property
   - Add filteredPullRequests computed property
   - Call FilterEngine to compute filtered results
   - Integration test filtering scenarios

10. **Extend GitHubAPI** (`Infrastructure/Networking/GitHubAPI.swift`)
    - Add fetchTeams method to protocol
    - Implement in GitHubAPIClient
    - Add TeamDTO response models
    - Unit test API response decoding

### Phase 4: UI Components

11. **FilterChipsView** (`Features/PullRequests/Views/FilterChipsView.swift`)
    - Display active filters as dismissible chips
    - Bind to filterState.configuration
    - Handle chip dismissal (remove individual filter)
    - Visual testing via Xcode Previews

12. **FilterSheet** (`Features/PullRequests/Views/FilterSheet.swift`)
    - Present as sheet with checkable lists
    - Three sections: Organizations, Repositories, Teams
    - Apply/Cancel buttons
    - Bind to filterState for selections
    - Visual testing via Xcode Previews

13. **Extend PullRequestListView** (`Features/PullRequests/Views/PullRequestListView.swift`)
    - Add search bar above list
    - Add filter button in toolbar
    - Add FilterChipsView above list
    - Present FilterSheet on filter button tap
    - Bind to filterState for search query
    - Manual testing for complete flow

### Phase 5: Integration & Polish

14. **Integration tests** (`Tests/IntegrationTests/PRFilteringTests.swift`)
    - Test all user scenarios from spec
    - Verify persistence across container recreations
    - Verify graceful degradation (teams unavailable)
    - Verify combined filters + search

15. **Filter restore tests** (`Tests/IntegrationTests/FilterRestoreTests.swift`)
    - Test configuration persists and restores correctly
    - Test search query does NOT persist
    - Test invalid team slugs are ignored

16. **Performance validation**
    - Test with 500 PR dataset
    - Verify filtering completes <500ms
    - Verify search debounce works (no lag)

17. **Accessibility audit**
    - VoiceOver labels for all filter controls
    - Keyboard navigation for filter sheet
    - Clear empty state messages

18. **Documentation**
    - Update README with filter feature
    - Add inline comments for complex logic
    - Document FilterEngine algorithm

---

## Key Implementation Patterns

### Pattern 1: Two-Stage Filtering Pipeline

```swift
struct FilterEngine: FilterEngineProtocol {
    private let fuzzyMatcher: FuzzyMatcherProtocol
    
    func apply(
        configuration: FilterConfiguration,
        searchQuery: String,
        to pullRequests: [PullRequest],
        teamMetadata: [Team]
    ) -> [PullRequest] {
        var filtered = pullRequests
        
        // Stage 1: Structured filters (cheap Set operations)
        if !configuration.selectedOrganizations.isEmpty {
            filtered = filtered.filter { 
                configuration.selectedOrganizations.contains($0.repositoryOwner) 
            }
        }
        
        if !configuration.selectedRepositories.isEmpty {
            filtered = filtered.filter { 
                configuration.selectedRepositories.contains($0.repositoryFullName) 
            }
        }
        
        if !configuration.selectedTeams.isEmpty {
            let teamRepos = Set(teamMetadata
                .filter { configuration.selectedTeams.contains($0.slug) }
                .flatMap(\.repositories))
            filtered = filtered.filter { teamRepos.contains($0.repositoryFullName) }
        }
        
        // Stage 2: Fuzzy search (expensive Levenshtein distance)
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedQuery.isEmpty {
            filtered = fuzzyMatcher.match(query: trimmedQuery, in: filtered)
        }
        
        return filtered
    }
}
```

**Why this order?**: Structured filters reduce the dataset before expensive fuzzy search.

---

### Pattern 2: Debounced Search with Task Cancellation

```swift
@Observable
@MainActor
final class FilterState {
    private(set) var searchQuery: String = ""
    private var debounceTask: Task<Void, Never>?
    private let onSearchApplied: (String) -> Void
    
    func updateSearchQuery(_ newQuery: String) {
        // Update immediately for UI responsiveness
        searchQuery = newQuery
        
        // Cancel previous debounce
        debounceTask?.cancel()
        
        // Start new debounce
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            
            // Notify container to recompute filtered PRs
            onSearchApplied(newQuery)
        }
    }
}
```

**Why 300ms?**: Balances responsiveness (user sees typing) with performance (avoids excessive filtering).

---

### Pattern 3: Computed Filtered Results

```swift
@Observable
@MainActor
final class PullRequestListContainer {
    private(set) var loadingState: LoadingState<[PullRequest]> = .idle
    private(set) var filterState: FilterState
    private let filterEngine: FilterEngineProtocol
    
    /// Computed property: always reflects current filters + search
    var filteredPullRequests: [PullRequest] {
        guard case .loaded(let allPRs) = loadingState else { return [] }
        
        return filterEngine.apply(
            configuration: filterState.configuration,
            searchQuery: filterState.searchQuery,
            to: allPRs,
            teamMetadata: filterState.metadata.teams.value ?? []
        )
    }
}
```

**Why computed?**: Observation framework automatically triggers view updates when dependencies change.

---

### Pattern 4: Persistent Filters with Codable

```swift
struct FilterConfiguration: Codable, Equatable {
    let version: Int = 1
    var selectedOrganizations: Set<String>
    var selectedRepositories: Set<String>
    var selectedTeams: Set<String>
    
    static let empty = FilterConfiguration(
        selectedOrganizations: [],
        selectedRepositories: [],
        selectedTeams: []
    )
}

final class UserDefaultsFilterPersistence: FilterPersistence {
    private let defaults: UserDefaults
    private let key = "com.gitreviewit.filter.configuration"
    
    func save(_ configuration: FilterConfiguration) async throws {
        let data = try JSONEncoder().encode(configuration)
        defaults.set(data, forKey: key)
    }
    
    func load() async throws -> FilterConfiguration? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(FilterConfiguration.self, from: data)
    }
}
```

**Why UserDefaults?**: Standard macOS persistence for user preferences; automatic sandboxing.

---

### Pattern 5: Graceful Team Filtering Degradation

```swift
func fetchTeams(api: GitHubAPI, credentials: GitHubCredentials) async {
    do {
        let teams = try await api.fetchTeams(credentials: credentials)
        filterState.metadata = FilterMetadata(
            organizations: metadata.organizations,
            repositories: metadata.repositories,
            teams: .loaded(teams)
        )
    } catch APIError.forbidden {
        // User lacks read:org scope
        filterState.metadata = FilterMetadata(
            organizations: metadata.organizations,
            repositories: metadata.repositories,
            teams: .failed(.forbidden)
        )
    } catch {
        // Network or other error
        filterState.metadata = FilterMetadata(
            organizations: metadata.organizations,
            repositories: metadata.repositories,
            teams: .failed(.unknown(error))
        )
    }
}
```

**UI Handling**:
```swift
if case .failed(.forbidden) = filterState.metadata.teams {
    Text("Team filtering unavailable - requires read:org permission")
        .foregroundStyle(.secondary)
}
```

---

### Pattern 6: FilterChipsView (Active Filters Display)

```swift
struct FilterChipsView: View {
    let configuration: FilterConfiguration
    let onRemove: (FilterType, String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(configuration.selectedOrganizations), id: \.self) { org in
                    FilterChip(
                        icon: "building.2",
                        label: org,
                        onRemove: { onRemove(.organization, org) }
                    )
                }
                
                ForEach(Array(configuration.selectedRepositories), id: \.self) { repo in
                    FilterChip(
                        icon: "shippingbox",
                        label: repo,
                        onRemove: { onRemove(.repository, repo) }
                    )
                }
                
                ForEach(Array(configuration.selectedTeams), id: \.self) { team in
                    FilterChip(
                        icon: "person.3",
                        label: team,
                        onRemove: { onRemove(.team, team) }
                    )
                }
            }
        }
    }
}

struct FilterChip: View {
    let icon: String
    let label: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(label)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(16)
    }
}
```

---

### Pattern 7: FilterSheet with Checkable Lists

```swift
struct FilterSheet: View {
    @Binding var configuration: FilterConfiguration
    let metadata: FilterMetadata
    let onApply: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Organizations") {
                    ForEach(metadata.sortedOrganizations, id: \.self) { org in
                        Toggle(org, isOn: Binding(
                            get: { configuration.selectedOrganizations.contains(org) },
                            set: { isSelected in
                                if isSelected {
                                    configuration.selectedOrganizations.insert(org)
                                } else {
                                    configuration.selectedOrganizations.remove(org)
                                }
                            }
                        ))
                    }
                }
                
                Section("Repositories") {
                    ForEach(metadata.sortedRepositories, id: \.self) { repo in
                        Toggle(repo, isOn: Binding(
                            get: { configuration.selectedRepositories.contains(repo) },
                            set: { isSelected in
                                if isSelected {
                                    configuration.selectedRepositories.insert(repo)
                                } else {
                                    configuration.selectedRepositories.remove(repo)
                                }
                            }
                        ))
                    }
                }
                
                Section("Teams") {
                    switch metadata.teams {
                    case .loaded(let teams):
                        ForEach(teams, id: \.slug) { team in
                            Toggle(team.name, isOn: Binding(
                                get: { configuration.selectedTeams.contains(team.slug) },
                                set: { isSelected in
                                    if isSelected {
                                        configuration.selectedTeams.insert(team.slug)
                                    } else {
                                        configuration.selectedTeams.remove(team.slug)
                                    }
                                }
                            ))
                        }
                    case .failed(.forbidden):
                        Text("Team filtering unavailable - requires read:org permission")
                            .foregroundStyle(.secondary)
                    case .failed:
                        Text("Failed to load teams")
                            .foregroundStyle(.secondary)
                    default:
                        ProgressView()
                    }
                }
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply", action: onApply)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Clear All") {
                        configuration = .empty
                    }
                }
            }
        }
    }
}
```

---

## Testing Strategy

### Unit Tests (Fast, Isolated)

Test pure logic without SwiftUI or networking:

- **StringSimilarity**: Known distance pairs
- **FuzzyMatcher**: Match ranking, tie-breaking
- **FilterEngine**: Each filter type, combinations
- **FilterConfiguration**: Codable round-trip
- **FilterMetadata**: Derivation from PR lists
- **FilterPersistence**: Save/load/clear

### Integration Tests (Behavior-Focused)

Test collaborating components with mocked network:

- **FilterState + FilterPersistence**: Persistence/restore
- **PullRequestListContainer + FilterEngine**: Filtered results
- **Full scenarios**: Apply filters → persist → relaunch → verify restoration
- **Graceful degradation**: Teams unavailable → other filters work

### Manual Testing (UI Verification)

- Search debouncing feels responsive
- Filter sheet presents/dismisses correctly
- Filter chips display and dismiss correctly
- Empty states show correct messages
- VoiceOver announces controls correctly

---

## Common Pitfalls

### ❌ Don't: Mutate configuration directly in View

```swift
// WRONG
Button("Add CompanyA") {
    container.filterState.configuration.selectedOrganizations.insert("CompanyA")
}
```

### ✅ Do: Send intent to state container

```swift
// CORRECT
Button("Add CompanyA") {
    var newConfig = container.filterState.configuration
    newConfig.selectedOrganizations.insert("CompanyA")
    container.filterState.updateFilterConfiguration(newConfig)
}
```

---

### ❌ Don't: Implement filtering in View

```swift
// WRONG
var body: some View {
    List(container.pullRequests.filter { pr in
        pr.repositoryOwner == "CompanyA"
    }) { pr in
        PullRequestRow(pr: pr)
    }
}
```

### ✅ Do: Use computed filtered results from container

```swift
// CORRECT
var body: some View {
    List(container.filteredPullRequests) { pr in
        PullRequestRow(pr: pr)
    }
}
```

---

### ❌ Don't: Force-unwrap team metadata

```swift
// WRONG
let teamRepos = metadata.teams.value!.flatMap(\.repositories)
```

### ✅ Do: Use nil-coalescing for graceful fallback

```swift
// CORRECT
let teamRepos = (metadata.teams.value ?? []).flatMap(\.repositories)
```

---

## Performance Tips

1. **Debounce search input**: Prevents excessive filtering on every keystroke
2. **Structured filters first**: Reduces dataset before expensive fuzzy search
3. **Set-based lookups**: O(1) for org/repo filtering
4. **Early termination**: Stop Levenshtein distance if distance exceeds threshold
5. **Computed properties**: Avoid storing derived state; recompute on demand

---

## Debugging Tips

### Print filter pipeline stages

```swift
func apply(...) -> [PullRequest] {
    print("Input PRs: \(pullRequests.count)")
    
    var filtered = pullRequests
    print("After org filter: \(filtered.count)")
    
    // Apply repo filter
    print("After repo filter: \(filtered.count)")
    
    // Apply team filter
    print("After team filter: \(filtered.count)")
    
    // Apply search
    print("After search: \(filtered.count)")
    
    return filtered
}
```

### Verify persistence

```swift
func testPersistence() async throws {
    let persistence = UserDefaultsFilterPersistence()
    let config = FilterConfiguration.empty
    config.selectedOrganizations = ["CompanyA"]
    
    try await persistence.save(config)
    
    let loaded = try await persistence.load()
    print("Loaded config: \(loaded)")  // Should match saved config
}
```

### Check team API response

```swift
func testTeamsFetch() async throws {
    let api = GitHubAPIClient()
    let credentials = GitHubCredentials(...)
    
    do {
        let teams = try await api.fetchTeams(credentials: credentials)
        print("Fetched \(teams.count) teams: \(teams.map(\.slug))")
    } catch {
        print("Failed to fetch teams: \(error)")
    }
}
```

---

## Next Steps

1. **Implement Phase 1-3** (foundation, models, state) → testable without UI
2. **Run integration tests** → verify filtering logic
3. **Implement Phase 4** (UI) → visual verification via Previews
4. **Run manual tests** → end-to-end user flows
5. **Run `just test` and `just lint`** → verify all tests pass and code is clean
6. **Open PR** → request code review

---

## Resources

- [Spec](../spec.md): Requirements and acceptance criteria
- [Data Model](../data-model.md): Structures and relationships
- [Contracts](../contracts/protocols.md): Protocol definitions
- [Research](../research.md): Technical decisions and rationale
- [AGENTS.md](../../AGENTS.md): Repository-wide coding guidelines
