import Foundation
import OSLog

private let logger = Logger(subsystem: "com.gitreviewit.app", category: "PRPreviewMetadata")

/// Container for asynchronously-loaded preview metadata from GitHub PR Details API
///
/// This model contains change statistics and reviewer information that requires
/// a separate API call per PR (not available in the Search API). The presence of
/// this struct indicates that metadata was successfully fetched.
///
/// **Invariants**:
/// - All count fields (`additions`, `deletions`, `changedFiles`) must be >= 0
/// - `requestedReviewers` is an empty array when no reviewers are assigned (not unavailable)
/// - Zero values are semantically valid (e.g., a PR with only deletions has `additions == 0`)
///
/// **Semantics**:
/// - `additions == 0`: PR adds no lines (valid state)
/// - `deletions == 0`: PR removes no lines (valid state)
/// - `changedFiles == 0`: Edge case - should not occur but handled gracefully
/// - `requestedReviewers.isEmpty`: No reviewers assigned (valid state)
///
/// **Usage**:
/// ```swift
/// let metadata = PRPreviewMetadata(
///     additions: 145,
///     deletions: 23,
///     changedFiles: 7,
///     requestedReviewers: [
///         Reviewer(login: "octocat", avatarURL: URL(string: "https://..."))
///     ]
/// )
/// ```
struct PRPreviewMetadata: Equatable, Sendable {
    let additions: Int
    let deletions: Int
    let changedFiles: Int
    let requestedReviewers: [Reviewer]

    /// Creates new preview metadata with validation
    ///
    /// - Parameters:
    ///   - additions: Number of lines added (must be >= 0)
    ///   - deletions: Number of lines deleted (must be >= 0)
    ///   - changedFiles: Number of files modified (must be >= 0)
    ///   - requestedReviewers: List of requested reviewers (empty array if none)
    ///
    /// - Precondition: All count fields must be non-negative
    init(
        additions: Int,
        deletions: Int,
        changedFiles: Int,
        requestedReviewers: [Reviewer]
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

        logger.debug(
            """
            Created PRPreviewMetadata: +\(additions) -\(deletions) \
            ~\(changedFiles) files, \(requestedReviewers.count) reviewers
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
}
