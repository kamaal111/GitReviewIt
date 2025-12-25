# Research: PR Status Insights

**Feature**: PR Status Insights
**Date**: 2025-12-25

## API Strategy Decision

**Decision**: Use **REST API** exclusively.

**Rationale**:
1.  **Consistency**: The app currently uses REST (`GitHubAPIClient`). Introducing GraphQL would require a new client stack, authentication handling, and error mapping, which is overkill for this feature.
2.  **Efficiency**:
    *   **Draft Status**: Available for free in the existing Search API call (`GET /search/issues`).
    *   **Mergeability**: Available for free in the existing PR Details call (`GET /repos/.../pulls/...`).
    *   **Checks**: Can be fetched in parallel with existing calls using `GET /repos/.../commits/{ref}/check-runs`.
3.  **Simplicity**: REST endpoints are well-documented and map directly to Swift structs.

**Alternatives Considered**:
*   **GraphQL**: Would allow fetching everything in a single query. Rejected because it requires significant architectural changes (new client) and the current REST approach is already efficient enough (parallel requests).
*   **Legacy Status API**: `GET /repos/.../commits/{ref}/status`. Rejected because it doesn't fully support GitHub Actions (Check Runs). We will use Check Runs API which is the modern standard.

## Data Sources

| Insight | Source API | Cost |
| :--- | :--- | :--- |
| **Draft Status** | `GET /search/issues` | 0 (already called) |
| **Mergeability** | `GET /repos/.../pulls/{number}` | 0 (already called) |
| **Checks** | `GET /repos/.../commits/{ref}/check-runs` | 1 extra call per PR detail view |

## Rate Limiting

*   Search API: 30 requests/minute (authenticated). We are already using this.
*   Core API: 5000 requests/hour.
*   Fetching details for visible PRs is the current behavior. Adding one extra call for checks doubles the detail fetch cost but is within limits for typical usage (reviewing < 50 PRs/day).
*   **Mitigation**: If rate limits are hit, the app already handles 403s. We will ensure status insights degrade to "Unknown" rather than blocking the UI.
