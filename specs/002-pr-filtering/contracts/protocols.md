# API Contracts: PR Filtering

**Feature**: PR Filtering  
**Date**: December 23, 2025  
**Purpose**: Define protocol boundaries for filtering services

## Service Protocols

### FilterPersistence

**Purpose**: Abstract persistence layer for filter configuration

**Responsibility**: Save and load filter configuration to/from persistent storage

**Protocol Definition**:
```swift
protocol FilterPersistence: Sendable {
    /// Save filter configuration to persistent storage
    /// - Parameter configuration: The filter configuration to save
    /// - Throws: If save operation fails
    func save(_ configuration: FilterConfiguration) async throws
    
    /// Load filter configuration from persistent storage
    /// - Returns: Saved configuration, or nil if none exists
    /// - Throws: If load operation fails (e.g., corrupted data)
    func load() async throws -> FilterConfiguration?
    
    /// Clear all persisted filter configuration
    /// - Throws: If clear operation fails
    func clear() async throws
}
```

**Concrete Implementation**: `UserDefaultsFilterPersistence`

**Mock Implementation** (for tests):
```swift
final class MockFilterPersistence: FilterPersistence {
    var savedConfiguration: FilterConfiguration?
    var shouldThrowOnSave = false
    var shouldThrowOnLoad = false
    
    func save(_ configuration: FilterConfiguration) async throws {
        guard !shouldThrowOnSave else { throw PersistenceError.saveFailed }
        savedConfiguration = configuration
    }
    
    func load() async throws -> FilterConfiguration? {
        guard !shouldThrowOnLoad else { throw PersistenceError.loadFailed }
        return savedConfiguration
    }
    
    func clear() async throws {
        savedConfiguration = nil
    }
}

enum PersistenceError: Error {
    case saveFailed
    case loadFailed
}
```

---

### FuzzyMatcherProtocol

**Purpose**: Abstract fuzzy matching logic for testability

**Responsibility**: Match search query against PR attributes and return ranked results

**Protocol Definition**:
```swift
protocol FuzzyMatcherProtocol {
    /// Match query against PRs and return ranked results
    /// - Parameters:
    ///   - query: Search query string
    ///   - pullRequests: Array of PRs to search
    /// - Returns: Array of PRs sorted by match score (best first)
    func match(query: String, in pullRequests: [PullRequest]) -> [PullRequest]
}
```

**Concrete Implementation**: `FuzzyMatcher`

**Mock Implementation** (for tests):
```swift
final class MockFuzzyMatcher: FuzzyMatcherProtocol {
    var matchResultOverride: [PullRequest]?
    
    func match(query: String, in pullRequests: [PullRequest]) -> [PullRequest] {
        if let override = matchResultOverride {
            return override
        }
        
        // Simple substring match for tests
        let lowercasedQuery = query.lowercased()
        return pullRequests.filter { pr in
            pr.title.lowercased().contains(lowercasedQuery) ||
            pr.repositoryFullName.lowercased().contains(lowercasedQuery) ||
            pr.authorLogin.lowercased().contains(lowercasedQuery)
        }
    }
}
```

---

### FilterEngineProtocol

**Purpose**: Abstract filtering pipeline for testability

**Responsibility**: Apply structured filters and search to produce filtered PR list

**Protocol Definition**:
```swift
protocol FilterEngineProtocol {
    /// Apply filter configuration and search query to PR list
    /// - Parameters:
    ///   - configuration: Filter configuration (org/repo/team selections)
    ///   - searchQuery: Search query string (may be empty)
    ///   - pullRequests: Array of PRs to filter
    ///   - teamMetadata: Available teams for team filtering
    /// - Returns: Filtered PR array
    func apply(
        configuration: FilterConfiguration,
        searchQuery: String,
        to pullRequests: [PullRequest],
        teamMetadata: [Team]
    ) -> [PullRequest]
}
```

**Concrete Implementation**: `FilterEngine`

**Mock Implementation** (for tests):
```swift
final class MockFilterEngine: FilterEngineProtocol {
    var applyResultOverride: [PullRequest]?
    var applyCalls: [(FilterConfiguration, String, [PullRequest], [Team])] = []
    
    func apply(
        configuration: FilterConfiguration,
        searchQuery: String,
        to pullRequests: [PullRequest],
        teamMetadata: [Team]
    ) -> [PullRequest] {
        applyCalls.append((configuration, searchQuery, pullRequests, teamMetadata))
        
        if let override = applyResultOverride {
            return override
        }
        
        // Simple filter implementation for tests
        var filtered = pullRequests
        
        if !configuration.selectedOrganizations.isEmpty {
            filtered = filtered.filter { configuration.selectedOrganizations.contains($0.repositoryOwner) }
        }
        
        if !configuration.selectedRepositories.isEmpty {
            filtered = filtered.filter { configuration.selectedRepositories.contains($0.repositoryFullName) }
        }
        
        return filtered
    }
}
```

---

## Extended GitHub API Protocol

### GitHubAPI Extension

**Purpose**: Add team fetching capability to existing GitHubAPI protocol

**New Method**:
```swift
extension GitHubAPI {
    /// Fetch teams the authenticated user belongs to
    /// - Parameter credentials: GitHub credentials with valid token
    /// - Returns: Array of teams
    /// - Throws: APIError if request fails (403/404 if read:org scope missing)
    func fetchTeams(credentials: GitHubCredentials) async throws -> [Team]
}
```

**Expected Behavior**:
- Returns teams from `GET {baseURL}/user/teams`
- Throws `.unauthorized` if token invalid
- Throws `.forbidden` if `read:org` scope missing
- Throws `.networkUnavailable` if network error
- Returns empty array if user has no teams (valid response)

**Mock Implementation** (for tests):
```swift
extension MockGitHubAPI {
    var teamsToReturn: [Team] = []
    var fetchTeamsError: APIError?
    var fetchTeamsCallCount = 0
    
    func fetchTeams(credentials: GitHubCredentials) async throws -> [Team] {
        fetchTeamsCallCount += 1
        
        if let error = fetchTeamsError {
            throw error
        }
        
        return teamsToReturn
    }
}
```

---

## Data Transfer Objects

### TeamDTO

**Purpose**: GitHub API response model for team data

**Structure**:
```swift
struct TeamDTO: Codable {
    let id: Int
    let slug: String
    let name: String
    let organization: OrganizationDTO
    let repositoriesURL: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case slug
        case name
        case organization
        case repositoriesURL = "repositories_url"
    }
}

struct OrganizationDTO: Codable {
    let login: String
}
```

**Mapping to Domain**:
```swift
extension Team {
    /// Initialize from GitHub API response
    /// - Parameters:
    ///   - dto: API response DTO
    ///   - repositories: Repository full names this team has access to
    init(from dto: TeamDTO, repositories: [String]) {
        self.init(
            slug: dto.slug,
            name: dto.name,
            organizationLogin: dto.organization.login,
            repositories: repositories
        )
    }
}
```

---

## Contract Examples

### Saving Filter Configuration

```swift
let persistence: FilterPersistence = UserDefaultsFilterPersistence()
let configuration = FilterConfiguration(
    version: 1,
    selectedOrganizations: ["CompanyA"],
    selectedRepositories: ["CompanyA/backend-service"],
    selectedTeams: []
)

try await persistence.save(configuration)
```

### Loading Filter Configuration

```swift
let persistence: FilterPersistence = UserDefaultsFilterPersistence()
let configuration = try await persistence.load()

if let config = configuration {
    print("Loaded filters: \(config.selectedOrganizations)")
} else {
    print("No saved filters")
}
```

### Filtering PRs

```swift
let engine: FilterEngineProtocol = FilterEngine(fuzzyMatcher: FuzzyMatcher())
let configuration = FilterConfiguration(
    version: 1,
    selectedOrganizations: ["CompanyA"],
    selectedRepositories: [],
    selectedTeams: []
)

let filtered = engine.apply(
    configuration: configuration,
    searchQuery: "bug fix",
    to: allPRs,
    teamMetadata: teams
)

print("Found \(filtered.count) matching PRs")
```

### Fetching Teams

```swift
let api: GitHubAPI = GitHubAPIClient()
let credentials = GitHubCredentials(token: "...", baseURL: "https://api.github.com")

do {
    let teams = try await api.fetchTeams(credentials: credentials)
    print("User belongs to \(teams.count) teams")
} catch APIError.forbidden {
    print("Team data unavailable: requires read:org scope")
} catch {
    print("Failed to fetch teams: \(error)")
}
```

---

## Contract Testing Strategy

### Unit Tests

Test each protocol implementation independently:

**FilterPersistence**:
- Save and load round-trip
- Handle missing data (return nil)
- Handle corrupted data (throw error)
- Clear removes data

**FuzzyMatcher**:
- Exact match returns highest score
- Prefix match returns high score
- Substring match returns medium score
- Fuzzy match (typos) returns low score
- No match returns empty array
- Tie-breaking is deterministic

**FilterEngine**:
- Organization filter includes/excludes correctly
- Repository filter includes/excludes correctly
- Team filter includes/excludes correctly
- Multiple filters combine correctly (AND logic)
- Search query filters results correctly
- Empty configuration/query passes all PRs through

**GitHubAPI.fetchTeams**:
- Returns teams on success
- Throws `.unauthorized` on 401
- Throws `.forbidden` on 403
- Throws `.networkUnavailable` on network error
- Returns empty array when user has no teams

### Integration Tests

Test protocol interactions:

**FilterState + FilterPersistence**:
- Configuration persists across state instances
- Loading on init restores saved configuration
- Updating configuration triggers save

**PullRequestListContainer + FilterEngine**:
- filteredPullRequests computes correctly
- Changing filter configuration updates filtered list
- Changing search query updates filtered list
- Combination of filters + search works correctly

**Full Pipeline**:
- User applies filters → persisted → app relaunch → filters restored → PRs filtered correctly

---

## Versioning & Compatibility

### FilterConfiguration Versioning

Current version: 1

Future migrations (if schema changes):
```swift
extension FilterConfiguration {
    static func migrate(from data: Data) throws -> FilterConfiguration {
        let decoder = JSONDecoder()
        
        // Try current version first
        if let v1 = try? decoder.decode(FilterConfiguration.self, from: data) {
            return v1
        }
        
        // Fall back to older versions or default
        return FilterConfiguration.empty
    }
}
```

### API Versioning

GitHub API version: `application/vnd.github+json` (v3)

No breaking changes expected for `/user/teams` endpoint. If GitHub deprecates this endpoint, gracefully degrade to "teams unavailable" state.

---

## Error Handling Contracts

### Persistence Errors

```swift
enum FilterPersistenceError: Error, LocalizedError {
    case encodingFailed
    case decodingFailed
    case storageUnavailable
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode filter configuration"
        case .decodingFailed:
            return "Failed to decode filter configuration. Filters have been reset."
        case .storageUnavailable:
            return "Storage unavailable. Changes will not be saved."
        }
    }
}
```

### API Errors (reuse existing APIError enum)

```swift
// Existing APIError extended with team-specific cases if needed
extension APIError {
    static let teamsUnavailable = APIError.forbidden
    // If 403 response includes specific message, can be mapped to custom error
}
```

---

## Dependency Injection Pattern

All protocols are injected via initializers:

```swift
@Observable
@MainActor
final class FilterState {
    private let persistence: FilterPersistence
    private let fuzzyMatcher: FuzzyMatcherProtocol
    
    init(
        persistence: FilterPersistence = UserDefaultsFilterPersistence(),
        fuzzyMatcher: FuzzyMatcherProtocol = FuzzyMatcher()
    ) {
        self.persistence = persistence
        self.fuzzyMatcher = fuzzyMatcher
    }
}
```

Tests inject mock implementations:

```swift
let mockPersistence = MockFilterPersistence()
let filterState = FilterState(persistence: mockPersistence)

// Test persistence behavior
await filterState.updateFilterConfiguration(...)
#expect(mockPersistence.savedConfiguration != nil)
```
