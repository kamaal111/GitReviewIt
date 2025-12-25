# Quickstart: PR Status Insights

## Prerequisites

*   **GitHub Token**: Ensure your personal access token has `repo` scope (for private repos) or public access.
*   **Xcode 16+**: Required for Swift 6.0.

## Running the App

1.  Open `app/GitReviewIt.xcodeproj`.
2.  Select `GitReviewIt` scheme.
3.  Run (Cmd+R).

## Verifying the Feature

1.  **Draft Status**:
    *   Create a Draft PR in a repo you have access to.
    *   Refresh the PR list.
    *   Verify the "Draft" badge appears.

2.  **Mergeability**:
    *   Create a PR with merge conflicts.
    *   Refresh the PR list.
    *   Verify the "Conflict" icon appears.

3.  **Checks**:
    *   Create a PR with failing CI checks.
    *   Refresh the PR list.
    *   Verify the "Failing" status appears.

## Troubleshooting

*   **Status is "Unknown"**:
    *   Check network connection.
    *   Check if API rate limit is exceeded (logs will show 403).
    *   Verify token permissions.
