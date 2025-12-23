# Research: PR Filtering

**Feature**: PR Filtering  
**Date**: December 23, 2025  
**Purpose**: Resolve unknowns from Technical Context and identify best practices for implementation

## Research Areas

### 1. Fuzzy Search Strategy for SwiftUI PR Lists

**Decision**: Use Levenshtein distance + prefix matching with weighted scoring

**Rationale**:
- Levenshtein distance handles typos and partial matches effectively
- Prefix matching gives higher scores to results that start with the query (user expectation)
- Weighted scoring allows us to prioritize PR title matches over author/repo matches
- Performance is acceptable for typical PR volumes (hundreds of items)
- No third-party dependencies required (implement in ~50-100 lines)

**Alternatives Considered**:
- ❌ Simple substring matching: Too naive, misses fuzzy/typo tolerance
- ❌ Full-text search libraries (e.g., third-party): Overkill for this use case, adds dependency
- ❌ Regex-based matching: Complex, poor UX for users unfamiliar with regex syntax

**Implementation Strategy**:
```swift
struct FuzzyMatcher {
    /// Matches query against PR attributes and returns ranked results
    /// - Parameters:
    ///   - query: Search query string (trimmed, lowercased internally)
    ///   - prs: Array of PRs to search
    /// - Returns: Array of (PR, score) tuples sorted by descending score
    func match(query: String, in prs: [PullRequest]) -> [(pr: PullRequest, score: Double)] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return prs.map { ($0, 1.0) } // No filter, all PRs match equally
        }
        
        let normalizedQuery = query.lowercased()
        var results: [(PullRequest, Double)] = []
        
        for pr in prs {
            var bestScore = 0.0
            
            // Title match (weight: 3.0)
            let titleScore = scoreMatch(query: normalizedQuery, text: pr.title.lowercased()) * 3.0
            bestScore = max(bestScore, titleScore)
            
            // Repository name match (weight: 2.0)
            let repoScore = scoreMatch(query: normalizedQuery, text: pr.repositoryFullName.lowercased()) * 2.0
            bestScore = max(bestScore, repoScore)
            
            // Author match (weight: 1.5)
            let authorScore = scoreMatch(query: normalizedQuery, text: pr.authorLogin.lowercased()) * 1.5
            bestScore = max(bestScore, authorScore)
            
            // Only include PRs with non-zero score
            if bestScore > 0 {
                results.append((pr, bestScore))
            }
        }
        
        // Sort by score descending, then by PR number ascending (deterministic tie-breaking)
        return results.sorted { lhs, rhs in
            if lhs.score == rhs.score {
                return lhs.pr.number < rhs.pr.number
            }
            return lhs.score > rhs.score
        }
    }
    
    /// Calculate score for a single text field
    private func scoreMatch(query: String, text: String) -> Double {
        // Exact match: 1.0
        if text == query { return 1.0 }
        
        // Prefix match: 0.9
        if text.hasPrefix(query) { return 0.9 }
        
        // Substring match: 0.7
        if text.contains(query) { return 0.7 }
        
        // Fuzzy match using Levenshtein distance: 0.0 to 0.6
        let distance = levenshteinDistance(query, text)
        let maxLength = max(query.count, text.count)
        let similarity = 1.0 - (Double(distance) / Double(maxLength))
        
        // Only return fuzzy score if similarity is above threshold (60%)
        return similarity > 0.6 ? similarity * 0.6 : 0.0
    }
}
```

**Tie-Breaking Strategy**: When two PRs have identical scores, sort by PR number ascending (oldest first). This is deterministic and matches GitHub's default ordering.

---

### 2. Search Input Debouncing in SwiftUI

**Decision**: Use Task with `.sleep` and cancellation for debouncing

**Rationale**:
- Native Swift Concurrency approach (no Combine dependency)
- Task cancellation automatically handles rapid input changes
- Simple to implement and reason about
- Aligns with existing async/await patterns in the app

**Alternatives Considered**:
- ❌ Combine's `.debounce`: Adds Combine dependency (violates principle VIII)
- ❌ Timer-based debouncing: More complex, requires manual cancellation logic
- ❌ No debouncing: Would trigger search on every keystroke (performance concern)

**Implementation Strategy**:
```swift
@Observable
@MainActor
final class FilterState {
    private(set) var searchQuery: String = ""
    private var debounceTask: Task<Void, Never>?
    
    /// Update search query with debouncing
    func updateSearchQuery(_ newQuery: String) {
        searchQuery = newQuery
        
        // Cancel previous debounce task
        debounceTask?.cancel()
        
        // Create new debounce task
        debounceTask = Task {
            // Wait 300ms before applying search
            try? await Task.sleep(for: .milliseconds(300))
            
            guard !Task.isCancelled else { return }
            
            // Trigger search after debounce
            await applySearch(newQuery)
        }
    }
}
```

**Debounce Duration**: 300ms provides good balance between responsiveness and performance. User feels instant feedback without overwhelming the system.

---

### 3. Filter Persistence Strategy

**Decision**: Use UserDefaults with Codable for filter persistence

**Rationale**:
- UserDefaults is the standard macOS persistence for user preferences
- Codable provides type-safe serialization/deserialization
- No additional dependencies or database complexity required
- Automatic handling of app sandbox and iCloud sync (if enabled)
- Easy to version and migrate schemas

**Alternatives Considered**:
- ❌ SwiftData/CoreData: Overkill for simple key-value storage
- ❌ JSON files in Application Support: More complex, requires manual file management
- ❌ iCloud Key-Value Store: Unnecessary; filters are device-specific preferences

**Implementation Strategy**:
```swift
protocol FilterPersistence {
    func save(_ configuration: FilterConfiguration) async throws
    func load() async throws -> FilterConfiguration?
    func clear() async throws
}

final class UserDefaultsFilterPersistence: FilterPersistence {
    private let defaults: UserDefaults
    private let key = "com.gitreviewit.filter.configuration"
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    func save(_ configuration: FilterConfiguration) async throws {
        let data = try JSONEncoder().encode(configuration)
        defaults.set(data, forKey: key)
    }
    
    func load() async throws -> FilterConfiguration? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(FilterConfiguration.self, from: data)
    }
    
    func clear() async throws {
        defaults.removeObject(forKey: key)
    }
}
```

**Schema Versioning**: Include version field in FilterConfiguration for future migrations:
```swift
struct FilterConfiguration: Codable {
    let version: Int = 1
    var selectedOrganizations: Set<String>
    var selectedRepositories: Set<String>
    var selectedTeams: Set<String>
}
```

---

### 4. Structured Filter UX Approach

**Decision**: Use sheet presentation with checkable list + active filter chips

**Rationale**:
- Sheet keeps main PR list uncluttered while providing full-screen filter selection
- Checkable lists (List with selection binding) are native SwiftUI pattern
- Filter chips above PR list provide at-a-glance visibility of active filters
- Chips are dismissible (X button) for quick removal of individual filters
- "Clear All" button in sheet for bulk reset

**Alternatives Considered**:
- ❌ Sidebar with filters: Not suitable for macOS window sizes; clutters UI
- ❌ Popover with filter options: Too small for long lists of orgs/repos/teams
- ❌ Inline filter controls in list: Breaks visual hierarchy and clutters list

**UX Flow**:
1. User taps "Filter" button in toolbar → FilterSheet presents
2. FilterSheet has three sections: Organizations, Repositories, Teams
3. Each section is a checkable list (multi-select)
4. "Apply" button dismisses sheet and applies filters
5. "Clear All" button resets all selections
6. Active filters appear as chips above PR list
7. Tapping X on a chip removes that specific filter
8. Tapping "Filter" button again shows current selections pre-checked

**Visual Hierarchy**:
```
┌─────────────────────────────────────┐
│ Review Requests        [Filter] [≡] │
├─────────────────────────────────────┤
│ 🏢 CompanyA  ✕  📦 backend-service ✕│  ← Filter chips
├─────────────────────────────────────┤
│ □ PR #123: Fix authentication bug   │
│   kamaal111/backend-service         │
│   @alice · 2 hours ago              │
├─────────────────────────────────────┤
│ □ PR #456: Add logging feature      │
│   CompanyA/api-gateway              │
│   @bob · 5 hours ago                │
└─────────────────────────────────────┘

FilterSheet (presented as sheet):
┌─────────────────────────────────────┐
│ Filters                   [Clear All]│
├─────────────────────────────────────┤
│ Organizations (2)                    │
│   ☑ CompanyA                         │
│   ☐ CompanyB                         │
│                                      │
│ Repositories (3)                     │
│   ☐ api-gateway                      │
│   ☑ backend-service                  │
│   ☐ frontend                         │
│                                      │
│ Teams (1) ⚠️ Unavailable            │
│   (Requires read:org permission)     │
│                                      │
│               [Apply] [Cancel]       │
└─────────────────────────────────────┘
```

---

### 5. GitHub Teams API Integration

**Decision**: Fetch teams via `GET /user/teams` with graceful degradation

**Rationale**:
- `/user/teams` returns teams the authenticated user belongs to
- Requires `read:org` OAuth scope (optional)
- Can map teams to repositories via team slug/repository association
- API may fail or return 403/404 if user lacks permissions

**Alternatives Considered**:
- ❌ `/orgs/{org}/teams`: Requires org-level permissions, not suitable for personal access
- ❌ Fetch team per repository: Too many API calls, rate limit concerns
- ❌ Infer teams from PR data: Not possible; GitHub API doesn't include team info in PR responses

**API Endpoint**:
```
GET {baseURL}/user/teams
Headers: Authorization: Bearer <token>, Accept: application/vnd.github+json
Response:
[
  {
    "id": 12345,
    "slug": "backend-team",
    "name": "Backend Team",
    "organization": { "login": "CompanyA" },
    "repositories_url": "https://api.github.com/teams/12345/repos"
  }
]
```

**Graceful Degradation Strategy**:
- Attempt to fetch teams when filter metadata is loaded
- If 403/404 or other error, set team availability state to `.unavailable(reason)`
- Display clear message in FilterSheet: "Team filtering unavailable - requires additional permissions"
- Do not block organization or repository filtering
- If user upgrades OAuth scope later, retry team fetch on next metadata load

**Caching Strategy**: Cache team metadata in memory for session duration. Refresh when user explicitly refreshes PR list or reopens FilterSheet after 5+ minutes.

---

### 6. Filter Metadata Derivation vs Fetching

**Decision**: Derive organizations and repositories from PR list; fetch teams separately

**Rationale**:
- Organizations and repositories are already present in PullRequest objects
- Deriving from existing data is instant (no API calls, no rate limits)
- Teams require separate API call but are optional (graceful degradation)
- Reduces API usage and improves performance

**Implementation**:
```swift
struct FilterMetadata {
    let organizations: Set<String>
    let repositories: Set<String>  // Full names: "owner/repo"
    let teams: LoadingState<[Team]>
    
    /// Derive metadata from PR list
    static func from(pullRequests: [PullRequest]) -> FilterMetadata {
        let orgs = Set(pullRequests.map(\.repositoryOwner))
        let repos = Set(pullRequests.map(\.repositoryFullName))
        
        return FilterMetadata(
            organizations: orgs,
            repositories: repos,
            teams: .idle  // Fetch separately
        )
    }
}
```

**Why Not Fetch Orgs/Repos**: GitHub API doesn't provide a simple endpoint for "all orgs/repos where user has PRs awaiting review". Deriving from PR list is more accurate and efficient.

---

### 7. Filtering Pipeline Architecture

**Decision**: Two-stage pipeline: structured filters → fuzzy search

**Rationale**:
- Structured filters narrow down dataset first (cheap Set operations)
- Fuzzy search operates on smaller result set (performance optimization)
- Clear separation of concerns (filter logic vs search logic)
- Easy to test each stage independently

**Pipeline Flow**:
```
All PRs (500) 
    ↓
Apply Organization Filter (if active)
    ↓
Filtered by Org (200)
    ↓
Apply Repository Filter (if active)
    ↓
Filtered by Repo (50)
    ↓
Apply Team Filter (if active, when available)
    ↓
Filtered by Team (30)
    ↓
Apply Fuzzy Search (if query non-empty)
    ↓
Ranked Search Results (10)
```

**Implementation**:
```swift
struct FilterEngine {
    func apply(
        configuration: FilterConfiguration,
        searchQuery: String,
        to pullRequests: [PullRequest],
        teamMetadata: [Team]
    ) -> [PullRequest] {
        var filtered = pullRequests
        
        // Stage 1: Structured filters (order: org → repo → team)
        if !configuration.selectedOrganizations.isEmpty {
            filtered = filtered.filter { configuration.selectedOrganizations.contains($0.repositoryOwner) }
        }
        
        if !configuration.selectedRepositories.isEmpty {
            filtered = filtered.filter { configuration.selectedRepositories.contains($0.repositoryFullName) }
        }
        
        if !configuration.selectedTeams.isEmpty {
            // Map teams to repos, then filter
            let teamRepos = Set(teamMetadata
                .filter { configuration.selectedTeams.contains($0.slug) }
                .flatMap { $0.repositories })
            filtered = filtered.filter { teamRepos.contains($0.repositoryFullName) }
        }
        
        // Stage 2: Fuzzy search
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedQuery.isEmpty {
            let matches = FuzzyMatcher().match(query: trimmedQuery, in: filtered)
            filtered = matches.map(\.pr)
        }
        
        return filtered
    }
}
```

---

### 8. Levenshtein Distance Implementation

**Decision**: Standard iterative DP algorithm with optimization for short strings

**Rationale**:
- Well-established algorithm for edit distance
- O(m*n) time complexity acceptable for typical query/text lengths
- Can optimize by early termination if distance exceeds threshold
- No dependencies required

**Implementation**:
```swift
/// Calculate Levenshtein distance between two strings
func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
    let s1 = Array(str1)
    let s2 = Array(str2)
    
    guard !s1.isEmpty else { return s2.count }
    guard !s2.isEmpty else { return s1.count }
    
    var distance = Array(repeating: Array(repeating: 0, count: s2.count + 1), count: s1.count + 1)
    
    for i in 0...s1.count {
        distance[i][0] = i
    }
    
    for j in 0...s2.count {
        distance[0][j] = j
    }
    
    for i in 1...s1.count {
        for j in 1...s2.count {
            if s1[i-1] == s2[j-1] {
                distance[i][j] = distance[i-1][j-1]
            } else {
                distance[i][j] = min(
                    distance[i-1][j] + 1,      // deletion
                    distance[i][j-1] + 1,      // insertion
                    distance[i-1][j-1] + 1     // substitution
                ) 
            }
        }
    }
    
    return distance[s1.count][s2.count]
}
```

**Performance Note**: For queries/text longer than 100 characters, consider early termination if distance exceeds threshold. In practice, PR titles/authors/repos are typically <100 chars.

---

## Summary

All unknowns resolved. Implementation strategy is clear:
- **Fuzzy Search**: Levenshtein + prefix matching with weighted scoring
- **Debouncing**: Task-based with 300ms delay
- **Persistence**: UserDefaults with Codable
- **Filter UX**: Sheet with checkable lists + filter chips
- **Teams API**: `/user/teams` with graceful degradation
- **Metadata**: Derive orgs/repos from PRs, fetch teams separately
- **Pipeline**: Two-stage (structured → fuzzy search)
- **String Similarity**: Standard Levenshtein DP algorithm

Ready to proceed to Phase 1 (Design).
