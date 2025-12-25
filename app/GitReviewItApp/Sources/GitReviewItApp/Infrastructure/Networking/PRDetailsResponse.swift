import Foundation

/// Response structure for decoding GitHub PR Details API
///
/// Maps to the response from `GET /repos/{owner}/{repo}/pulls/{number}`
/// See: https://docs.github.com/en/rest/pulls/pulls#get-a-pull-request
///
/// **Usage**:
/// ```swift
/// let response = try JSONDecoder().decode(PRDetailsResponse.self, from: data)
/// let metadata = response.toPRPreviewMetadata()
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

    /// Converts API response to domain model
    ///
    /// - Returns: PRPreviewMetadata with change stats and reviewers
    func toPRPreviewMetadata() -> PRPreviewMetadata {
        PRPreviewMetadata(
            additions: additions,
            deletions: deletions,
            changedFiles: changed_files,
            requestedReviewers: requested_reviewers.map { reviewer in
                Reviewer(
                    login: reviewer.login,
                    avatarURL: reviewer.avatar_url
                )
            }
        )
    }
}
