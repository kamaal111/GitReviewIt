import Foundation

/// Response structure for decoding GitHub PR Details API
///
/// Maps to the response from `GET /repos/{owner}/{repo}/pulls/{number}`
/// See: https://docs.github.com/en/rest/pulls/pulls#get-a-pull-request
///
/// **Usage**:
/// ```swift
/// let response = try JSONDecoder().decode(PRDetailsResponse.self, from: data)
/// let metadata = response.toPRPreviewMetadata(reviews: reviews)
/// ```
struct PRDetailsResponse: Decodable {
    let additions: Int
    let deletions: Int
    let changed_files: Int
    let requested_reviewers: [ReviewerResponse]
    let head: Head
    let mergeable: Bool?
    let mergeable_state: String?
    let comments: Int  // Issue comments count from PR API

    struct ReviewerResponse: Decodable {
        let login: String
        let avatar_url: URL?
    }

    struct Head: Decodable {
        let sha: String
    }

    /// Converts API response to domain model, optionally including completed reviews
    ///
    /// - Parameters:
    ///   - reviews: Optional array of completed PR reviews
    ///   - checkStatus: CI/CD check status (defaults to .unknown)
    ///   - reviewCommentCount: Number of review comments (inline code comments) (defaults to 0)
    /// - Returns: PRPreviewMetadata with change stats, reviewers, check status, and comment counts
    func toPRPreviewMetadata(
        reviews: [PRReviewResponse] = [],
        checkStatus: PRCheckStatus = .unknown,
        reviewCommentCount: Int = 0
    ) -> PRPreviewMetadata {
        // Convert requested reviewers
        let requestedReviewers = requested_reviewers.map { reviewer in
            Reviewer(
                login: reviewer.login,
                avatarURL: reviewer.avatar_url,
                state: .requested
            )
        }

        // Convert completed reviews, taking the latest review per user
        var reviewerMap: [String: PRReviewResponse] = [:]
        for review in reviews {
            let login = review.user.login
            // Keep the latest review for each user
            if let existing = reviewerMap[login] {
                guard let existingDate = existing.submitted_at else {
                    continue
                }
                guard let newDate = review.submitted_at else {
                    continue
                }

                if newDate > existingDate {
                    reviewerMap[login] = review
                }
            } else {
                reviewerMap[login] = review
            }
        }

        let completedReviewers = reviewerMap.values.compactMap { review -> Reviewer? in
            guard let state = ReviewState(rawValue: review.state.lowercased()) else {
                return nil
            }
            return Reviewer(
                login: review.user.login,
                avatarURL: review.user.avatar_url,
                state: state
            )
        }

        let mergeStatus: PRMergeStatus
        if let mergeable = mergeable {
            mergeStatus = mergeable ? .mergeable : .conflicting
        } else {
            mergeStatus = .unknown
        }

        // Total comments = issue comments from PR + review comments (inline code comments)
        let totalComments = comments + reviewCommentCount

        return PRPreviewMetadata(
            additions: additions,
            deletions: deletions,
            changedFiles: changed_files,
            requestedReviewers: requestedReviewers,
            completedReviewers: completedReviewers,
            checkStatus: checkStatus,
            mergeStatus: mergeStatus,
            totalCommentCount: totalComments
        )
    }
}

/// Response structure for decoding GitHub PR Reviews API
///
/// Maps to the response from `GET /repos/{owner}/{repo}/pulls/{number}/reviews`
/// See: https://docs.github.com/en/rest/pulls/reviews#list-reviews-for-a-pull-request
struct PRReviewResponse: Decodable {
    let user: UserResponse
    let state: String  // "APPROVED", "CHANGES_REQUESTED", "COMMENTED", etc.
    let submitted_at: Date?

    struct UserResponse: Decodable {
        let login: String
        let avatar_url: URL?
    }
}

/// Response structure for decoding GitHub PR Review Comments API
///
/// Maps to the response from `GET /repos/{owner}/{repo}/pulls/{number}/comments`
/// See: https://docs.github.com/en/rest/pulls/comments#list-review-comments-on-a-pull-request
///
/// This represents inline code review comments (different from issue comments)
struct PRReviewCommentResponse: Decodable {
    let id: Int
    let user: UserResponse
    let body: String
    let created_at: Date

    struct UserResponse: Decodable {
        let login: String
        let avatar_url: URL?
    }
}
