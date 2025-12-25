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

    struct ReviewerResponse: Decodable {
        let login: String
        let avatar_url: URL?
    }

    /// Converts API response to domain model, optionally including completed reviews
    ///
    /// - Parameter reviews: Optional array of completed PR reviews
    /// - Returns: PRPreviewMetadata with change stats and reviewers
    func toPRPreviewMetadata(reviews: [PRReviewResponse] = []) -> PRPreviewMetadata {
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

        return PRPreviewMetadata(
            additions: additions,
            deletions: deletions,
            changedFiles: changed_files,
            requestedReviewers: requestedReviewers,
            completedReviewers: completedReviewers
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
