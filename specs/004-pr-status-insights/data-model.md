# Data Model: PR Status Insights

## Enums

### `PRCheckStatus`
Represents the aggregated status of CI/CD checks.

```swift
enum PRCheckStatus: String, Codable, Sendable {
    case passing
    case failing
    case pending
    case unknown
}
```

### `PRMergeStatus`
Represents the mergeability of the PR.

```swift
enum PRMergeStatus: String, Codable, Sendable {
    case clean
    case conflicts
    case unknown
}
```

## Model Updates

### `PullRequest`
Update the main model to include draft status (available from Search API).

```swift
struct PullRequest {
    // ... existing fields
    let isDraft: Bool // New field from Search API
}
```

### `PRPreviewMetadata`
Update the metadata container to include status insights.

```swift
struct PRPreviewMetadata {
    // ... existing fields (additions, deletions, etc.)
    let checkStatus: PRCheckStatus
    let mergeStatus: PRMergeStatus
}
```

## API Response Models

### `PRDetailsResponse` (Update)
Update to decode mergeability and head SHA.

```swift
struct PRDetailsResponse: Decodable {
    // ... existing fields
    let draft: Bool
    let mergeable: Bool?
    let mergeable_state: String
    let head: Head

    struct Head: Decodable {
        let sha: String
    }
}
```

### `CheckRunsResponse` (New)
Response from `GET /repos/{owner}/{repo}/commits/{ref}/check-runs`.

```swift
struct CheckRunsResponse: Decodable {
    let total_count: Int
    let check_runs: [CheckRun]

    struct CheckRun: Decodable {
        let status: String // "queued", "in_progress", "completed"
        let conclusion: String? // "success", "failure", "neutral", "cancelled", "timed_out", "action_required", "skipped"
    }
}
```

### `CommitStatusResponse` (New - Optional/Fallback)
Response from `GET /repos/{owner}/{repo}/commits/{ref}/status` (for legacy statuses).
*Decision: Start with Check Runs only as it covers Actions. If needed, add legacy status later.*
