import Foundation
import OSLog

private let logger = Logger(subsystem: "com.gitreviewit.app", category: "PRPreviewMetadata")

/// Represents the aggregated status of CI/CD checks for a pull request
///
/// **States**:
/// - `passing`: All checks completed successfully
/// - `failing`: One or more checks failed, timed out, or require action
/// - `pending`: One or more checks are in progress or queued
/// - `unknown`: No checks configured or status unavailable
///
/// **Usage**:
/// ```swift
/// let status = PRCheckStatus.passing
/// ```
enum PRCheckStatus: String, Codable, Sendable {
    case passing
    case failing
    case pending
    case unknown
}

/// Represents the mergeability status of a pull request
///
/// **States**:
/// - `mergeable`: No conflicts, ready to merge
/// - `conflicting`: Merge conflicts detected
/// - `unknown`: Mergeability status not yet computed or unavailable
enum PRMergeStatus: String, Codable, Sendable {
    case mergeable
    case conflicting
    case unknown
}

/// Container for asynchronously-loaded preview metadata from GitHub PR Details API
///
/// This model contains change statistics and reviewer information that requires
/// a separate API call per PR (not available in the Search API). The presence of
/// this struct indicates that metadata was successfully fetched.
///
/// **Invariants**:
/// - All count fields (`additions`, `deletions`, `changedFiles`) must be >= 0
/// - `requestedReviewers` is an empty array when no reviewers are assigned (not unavailable)
/// - `completedReviewers` contains reviewers who have already submitted reviews
/// - Zero values are semantically valid (e.g., a PR with only deletions has `additions == 0`)
///
/// **Semantics**:
/// - `additions == 0`: PR adds no lines (valid state)
/// - `deletions == 0`: PR removes no lines (valid state)
/// - `changedFiles == 0`: Edge case - should not occur but handled gracefully
/// - `requestedReviewers.isEmpty`: No pending reviewers (valid state)
/// - `completedReviewers.isEmpty`: No completed reviews yet (valid state)
///
/// **Usage**:
/// ```swift
/// let metadata = PRPreviewMetadata(
///     additions: 145,
///     deletions: 23,
///     changedFiles: 7,
///     requestedReviewers: [
///         Reviewer(login: "octocat", avatarURL: URL(string: "https://..."), state: .requested)
///     ],
///     completedReviewers: [
///         Reviewer(login: "kamaal111", avatarURL: URL(string: "https://..."), state: .approved)
///     ]
/// )
/// ```
struct PRPreviewMetadata: Equatable, Sendable {
    let additions: Int
    let deletions: Int
    let changedFiles: Int
    let requestedReviewers: [Reviewer]
    let completedReviewers: [Reviewer]
    let checkStatus: PRCheckStatus
    let mergeStatus: PRMergeStatus

    /// Creates new preview metadata with validation
    ///
    /// - Parameters:
    ///   - additions: Number of lines added (must be >= 0)
    ///   - deletions: Number of lines deleted (must be >= 0)
    ///   - changedFiles: Number of files modified (must be >= 0)
    ///   - requestedReviewers: List of requested reviewers (empty array if none)
    ///   - completedReviewers: List of reviewers who have completed reviews (empty array if none)
    ///   - checkStatus: CI/CD check status (defaults to .unknown)
    ///   - mergeStatus: Mergeability status (defaults to .unknown)
    ///
    /// - Precondition: All count fields must be non-negative
    init(
        additions: Int,
        deletions: Int,
        changedFiles: Int,
        requestedReviewers: [Reviewer],
        completedReviewers: [Reviewer] = [],
        checkStatus: PRCheckStatus = .unknown,
        mergeStatus: PRMergeStatus = .unknown
    ) {
        guard additions >= 0 else {
            preconditionFailure("additions must be non-negative, got: \(additions)")
        }

        guard deletions >= 0 else {
            preconditionFailure("deletions must be non-negative, got: \(deletions)")
        }

        guard changedFiles >= 0 else {
            preconditionFailure("changedFiles must be non-negative, got: \(changedFiles)")
        }

        self.additions = additions
        self.deletions = deletions
        self.changedFiles = changedFiles
        self.requestedReviewers = requestedReviewers
        self.completedReviewers = completedReviewers
        self.checkStatus = checkStatus
        self.mergeStatus = mergeStatus

        logger.debug(
            """
            Created PRPreviewMetadata: +\(additions) -\(deletions) \
            ~\(changedFiles) files, \(requestedReviewers.count) requested, \
            \(completedReviewers.count) completed, checks: \(checkStatus.rawValue), \
            merge: \(mergeStatus.rawValue)
            """
        )
    }
}

// MARK: - Computed Properties

extension PRPreviewMetadata {
    /// Total number of lines changed (additions + deletions)
    var totalChanges: Int {
        additions + deletions
    }

    /// Whether this PR has any requested reviewers
    var hasRequestedReviewers: Bool {
        !requestedReviewers.isEmpty
    }

    /// All reviewers (both requested and completed)
    var allReviewers: [Reviewer] {
        completedReviewers + requestedReviewers
    }

    /// Whether this PR has any reviewers (requested or completed)
    var hasAnyReviewers: Bool {
        !allReviewers.isEmpty
    }
}
