# Data Model: PR Filtering

**Feature**: PR Filtering  
**Date**: December 23, 2025  
**Purpose**: Define data structures, relationships, and state models for filtering PRs

## Domain Models

### FilterConfiguration

**Purpose**: Represents the user's persistent filter selections (organization, repository, team).

**Type**: Value type (struct)

**Properties**:
| Name | Type | Optional | Description |
|------|------|----------|-------------|
| `version` | Int | No | Schema version for future migrations (current: 1) |
| `selectedOrganizations` | Set<String> | No | Organization logins to filter by (empty = no filter) |
| `selectedRepositories` | Set<String> | No | Repository full names ("owner/repo") to filter by |
| `selectedTeams` | Set<String> | No | Team slugs to filter by (may be ignored if teams unavailable) |

**Conformances**: `Codable`, `Equatable`

**Validation Rules**:
- Sets may be empty (no filter applied)
- Repository names must be in "owner/repo" format
- Team slugs are validated against available teams (invalid slugs ignored)

**Persistence**: Stored in UserDefaults as JSON

**Example**:
```swift
FilterConfiguration(
    version: 1,
    selectedOrganizations: ["CompanyA", "CompanyB"],
    selectedRepositories: ["CompanyA/backend-service"],
    selectedTeams: ["backend-team"]
)
```

---

### FilterMetadata

**Purpose**: Represents available filter options derived from the current PR dataset and fetched teams.

**Type**: Value type (struct)

**Properties**:
| Name | Type | Optional | Description |
|------|------|----------|-------------|
| `organizations` | Set<String> | No | All unique organizations from current PR list |
| `repositories` | Set<String> | No | All unique repository full names from PR list |
| `teams` | LoadingState<[Team]> | No | Teams loaded from GitHub API (may be unavailable) |

**Computed Properties**:
| Name | Type | Description |
|------|------|-------------|
| `areTeamsAvailable` | Bool | True if teams are .loaded, false otherwise |
| `sortedOrganizations` | [String] | Organizations sorted alphabetically |
| `sortedRepositories` | [String] | Repositories sorted alphabetically |

**Derivation**: Organizations and repositories are derived from `[PullRequest]`. Teams are fetched separately from GitHub API.

**Example**:
```swift
FilterMetadata(
    organizations: ["CompanyA", "CompanyB", "PersonalOrg"],
    repositories: ["CompanyA/backend-service", "CompanyA/frontend", "PersonalOrg/hobby-project"],
    teams: .loaded([
        Team(slug: "backend-team", name: "Backend Team", ...),
        Team(slug: "frontend-team", name: "Frontend Team", ...)
    ])
)
```

---

### Team

**Purpose**: Represents a GitHub team for filtering purposes.

**Type**: Value type (struct)

**Properties**:
| Name | Type | Optional | Description |
|------|------|----------|-------------|
| `slug` | String | No | Team identifier (e.g., "backend-team") |
| `name` | String | No | Display name (e.g., "Backend Team") |
| `organizationLogin` | String | No | Organization this team belongs to |
| `repositories` | [String] | No | Repository full names this team has access to |

**Conformances**: `Codable`, `Equatable`, `Identifiable`

**API Mapping**: Mapped from GitHub `/user/teams` response

**Example**:
```swift
Team(
    slug: "backend-team",
    name: "Backend Team",
    organizationLogin: "CompanyA",
    repositories: ["CompanyA/backend-service", "CompanyA/api-gateway"]
)
```

---

### SearchQuery

**Purpose**: Represents the user's current (transient) search text.

**Type**: Value type (String alias)

**Validation**: Trimmed of whitespace; empty string treated as "no search"

**Persistence**: NOT persisted (transient state only)

**Usage**: Passed to fuzzy matcher for filtering

---

## State Models

### FilterState

**Purpose**: Observable state container for filter and search state. Owned by PullRequestListContainer.

**Type**: Reference type (class), annotated with `@Observable`

**Properties**:
| Name | Type | Mutable | Description |
|------|------|---------|-------------|
| `configuration` | FilterConfiguration | private(set) | Current filter selections (persisted) |
| `metadata` | FilterMetadata | private(set) | Available filter options derived from PRs |
| `searchQuery` | String | private(set) | Current search text (transient) |
| `isShowingFilterSheet` | Bool | public var | Whether filter sheet is presented |

**Dependencies**:
| Name | Type | Description |
|------|------|-------------|
| `persistence` | FilterPersistence | Saves/loads filter configuration |

**Intent Methods**:
| Method | Parameters | Description |
|--------|------------|-------------|
| `updateSearchQuery(_:)` | String | Updates search query with debouncing |
| `updateFilterConfiguration(_:)` | FilterConfiguration | Applies new filter configuration and persists |
| `clearAllFilters()` | None | Resets configuration to empty and persists |
| `clearSearchQuery()` | None | Resets search query to empty string |
| `loadPersistedConfiguration()` | None | Loads saved configuration from persistence |
| `updateMetadata(from:)` | [PullRequest] | Derives metadata from PR list |
| `fetchTeams(api:credentials:)` | GitHubAPI, credentials | Fetches teams from API |

**State Transitions**:
```
Initial: configuration = .empty, searchQuery = "", metadata = .empty
    ↓
loadPersistedConfiguration() called on init
    ↓
Restored: configuration = loaded from UserDefaults (or .empty if none)
    ↓
updateMetadata(from: pullRequests) called when PRs load
    ↓
Metadata Derived: organizations + repositories extracted from PRs
    ↓
fetchTeams() called (async)
    ↓
Teams Loaded/Failed: metadata.teams = .loaded([Team]) or .failed(APIError)
```

---

### FilteredPullRequests

**Purpose**: Derived state representing the filtered and searched PR list.

**Type**: Computed property on PullRequestListContainer (not stored)

**Computation**:
```swift
var filteredPullRequests: [PullRequest] {
    guard case .loaded(let allPRs) = loadingState else { return [] }
    
    return filterEngine.apply(
        configuration: filterState.configuration,
        searchQuery: filterState.searchQuery,
        to: allPRs,
        teamMetadata: filterState.metadata.teams.value ?? []
    )
}
```

**Caching**: Not cached; recomputed on every access. Performance acceptable for typical PR volumes (hundreds).

---

## API Models

### TeamResponse (GitHub API)

**Purpose**: Response model for `/user/teams` GitHub API endpoint.

**Type**: Value type (struct)

**Properties**:
| Name | Type | Optional | Description |
|------|------|----------|-------------|
| `id` | Int | No | Team ID |
| `slug` | String | No | Team identifier |
| `name` | String | No | Display name |
| `organization` | OrganizationInfo | No | Nested organization info |
| `repositoriesURL` | String | No | URL to fetch team repositories |

**Nested Type**: `OrganizationInfo`
| Name | Type | Description |
|------|------|-------------|
| `login` | String | Organization login |

**Mapping to Domain**: 
```swift
extension Team {
    init(from response: TeamResponse, repositories: [String]) {
        self.init(
            slug: response.slug,
            name: response.name,
            organizationLogin: response.organization.login,
            repositories: repositories
        )
    }
}
```

---

## Persistence Models

### Persisted Filter Configuration

**Format**: JSON stored in UserDefaults

**Key**: `"com.gitreviewit.filter.configuration"`

**Schema**:
```json
{
  "version": 1,
  "selectedOrganizations": ["CompanyA", "CompanyB"],
  "selectedRepositories": ["CompanyA/backend-service"],
  "selectedTeams": ["backend-team"]
}
```

**Migration Strategy**: When loading, check version field:
- Version 1: Current schema
- Unknown version: Ignore and use default empty configuration

---

## Relationships

```
┌─────────────────────────────────────────┐
│  FilterConfiguration                    │
│  (persisted in UserDefaults)            │
│  - selectedOrganizations: Set<String>   │
│  - selectedRepositories: Set<String>    │
│  - selectedTeams: Set<String>           │
└────────────┬────────────────────────────┘
             │ owned by
             │
┌────────────▼────────────────────────────┐
│  FilterState (@Observable)              │
│  - configuration: FilterConfiguration   │
│  - metadata: FilterMetadata             │
│  - searchQuery: String                  │
└────────────┬────────────────────────────┘
             │ owned by
             │
┌────────────▼────────────────────────────┐
│  PullRequestListContainer               │
│  - filterState: FilterState             │
│  - loadingState: LoadingState<[PR]>     │
└────────────┬────────────────────────────┘
             │
             │ computes
             │
┌────────────▼────────────────────────────┐
│  filteredPullRequests: [PullRequest]    │
│  (derived via FilterEngine)             │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  FilterMetadata                         │
│  - organizations: Set<String>           │
│  - repositories: Set<String>            │
│  - teams: LoadingState<[Team]>          │
└────────────┬────────────────────────────┘
             │ derived from
             │
┌────────────▼────────────────────────────┐
│  [PullRequest]                          │
│  (from GitHub API)                      │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  Team                                   │
│  - slug: String                         │
│  - name: String                         │
│  - organizationLogin: String            │
│  - repositories: [String]               │
└────────────┬────────────────────────────┘
             │ fetched from
             │
┌────────────▼────────────────────────────┐
│  GitHub /user/teams API                 │
│  (requires read:org scope)              │
└─────────────────────────────────────────┘
```

---

## State Diagram: Filter Lifecycle

```
┌─────────────────────────────────────────┐
│  App Launch                             │
└────────────┬────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────┐
│  FilterState.loadPersistedConfiguration()│
│  → configuration loaded from UserDefaults│
└────────────┬────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────┐
│  PRs fetched (already implemented)     │
└────────────┬────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────┐
│  FilterState.updateMetadata(from: prs) │
│  → organizations + repositories derived │
└────────────┬────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────┐
│  FilterState.fetchTeams()               │
│  → teams fetched from API (async)       │
└────────────┬────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────┐
│  Filtered PRs displayed                 │
│  (computed from configuration + query)  │
└────────────┬────────────────────────────┘
             │
             ▼
     ┌───────┴───────┐
     │               │
     ▼               ▼
┌─────────┐    ┌──────────────┐
│ User    │    │ User opens   │
│ searches│    │ filter sheet │
└────┬────┘    └──────┬───────┘
     │                │
     ▼                ▼
┌─────────────┐  ┌──────────────────┐
│ Search      │  │ User selects     │
│ query       │  │ orgs/repos/teams │
│ updated     │  └──────┬───────────┘
│ (debounced) │         │
└────┬────────┘         ▼
     │          ┌───────────────────┐
     │          │ User taps "Apply" │
     │          └──────┬────────────┘
     │                 │
     │                 ▼
     │          ┌──────────────────────┐
     │          │ updateFilterConfiguration()│
     │          │ → persisted to UserDefaults│
     │          └──────┬─────────────────────┘
     │                 │
     └─────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  filteredPullRequests recomputed        │
│  → view updates automatically           │
└─────────────────────────────────────────┘
```

---

## Invariants

1. **Empty configuration = no filtering**: If all filter sets are empty, all PRs pass through
2. **Search query is trimmed**: Leading/trailing whitespace always removed before matching
3. **Invalid team slugs ignored**: If persisted configuration references teams that don't exist, they are silently ignored
4. **Metadata always reflects current PR list**: updateMetadata() called whenever PR list changes
5. **Filtering is deterministic**: Same input (PRs + configuration + query) always produces same output
6. **Search does not persist**: On app relaunch, searchQuery is always empty
7. **Configuration persists on every change**: updateFilterConfiguration() immediately saves to UserDefaults

---

## Performance Considerations

### Derived Metadata
- **Cost**: O(n) where n = number of PRs
- **Frequency**: Once per PR list fetch
- **Acceptable**: PRs are typically <1000, operation is trivial

### Filtering Pipeline
- **Cost**: O(n * f) where n = PR count, f = filter count
- **Frequency**: On every configuration/query change
- **Optimization**: Set-based filtering is O(1) lookup per PR

### Fuzzy Search
- **Cost**: O(n * m * k) where n = PR count, m = query length, k = text length
- **Frequency**: On every query change (debounced to 300ms)
- **Optimization**: Levenshtein distance computed only for fields with low scores (fallback)

### Persistence
- **Cost**: O(1) for UserDefaults read/write
- **Frequency**: On configuration change, app launch
- **Acceptable**: Synchronous operations are fast enough for simple JSON

---

## Testing Strategy

### Unit Tests
- FilterConfiguration: Codable round-trip, Equatable conformance
- FilterMetadata: Derivation from PR lists, team availability checks
- Team: Codable mapping from API response
- FilterEngine: Structured filter correctness, fuzzy search ranking, combined filtering

### Integration Tests
- FilterState: Persistence/restore, metadata updates, team fetching, debouncing
- PullRequestListContainer: filteredPullRequests computation, filter + search combinations
- Full filtering scenarios: Apply filters, search, persist, relaunch, verify restoration

---

## Extension Points

Future enhancements (out of scope for this feature):
- **Saved filter presets**: Named configurations users can switch between
- **Filter export/import**: Share filter configurations across devices
- **Advanced search syntax**: Boolean operators, field-specific queries (e.g., `author:john`)
- **Search history**: Recently used search queries
- **Smart suggestions**: Autocomplete for search based on PR data
