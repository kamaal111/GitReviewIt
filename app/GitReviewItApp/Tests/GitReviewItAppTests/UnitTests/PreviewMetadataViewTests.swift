import SwiftUI
import Testing

@testable import GitReviewItApp

/// Tests for PreviewMetadataView comment count display
@MainActor
struct PreviewMetadataViewTests {
    // MARK: - Comment Count Display Tests

    @Test
    func `displays comment count when available`() throws {
        let previewMetadata = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 3,
            requestedReviewers: []
        )
        let view = PreviewMetadataView(
            previewMetadata: previewMetadata,
            commentCount: 12,
            currentUserLogin: nil
        )

        // Test that view renders without crashing
        _ = view.body
    }

    @Test
    func `displays zero comments when count is zero`() throws {
        let view = PreviewMetadataView(
            previewMetadata: nil,
            commentCount: 0,
            currentUserLogin: nil
        )

        // Verify accessibility label for zero comments
        let accessibilityLabel = view.commentsAccessibilityLabel
        #expect(accessibilityLabel == "No comments")
    }

    @Test
    func `displays unavailable for nil comment count`() throws {
        let view = PreviewMetadataView(
            previewMetadata: nil,
            commentCount: nil,
            currentUserLogin: nil
        )

        // Verify accessibility label for unavailable comments
        let accessibilityLabel = view.commentsAccessibilityLabel
        #expect(accessibilityLabel == "Comments: unavailable")
    }

    @Test
    func `accessibility label uses singular for one comment`() throws {
        let view = PreviewMetadataView(
            previewMetadata: nil,
            commentCount: 1,
            currentUserLogin: nil
        )

        let accessibilityLabel = view.commentsAccessibilityLabel
        #expect(accessibilityLabel == "1 comment")
    }

    @Test
    func `accessibility label uses plural for multiple comments`() throws {
        let view = PreviewMetadataView(
            previewMetadata: nil,
            commentCount: 5,
            currentUserLogin: nil
        )

        let accessibilityLabel = view.commentsAccessibilityLabel
        #expect(accessibilityLabel == "5 comments")
    }

    @Test
    func `displays both metadata and comment count together`() throws {
        let previewMetadata = PRPreviewMetadata(
            additions: 100,
            deletions: 50,
            changedFiles: 8,
            requestedReviewers: []
        )
        let view = PreviewMetadataView(
            previewMetadata: previewMetadata,
            commentCount: 3,
            currentUserLogin: nil
        )

        // Verify comment accessibility label
        let commentsLabel = view.commentsAccessibilityLabel
        #expect(commentsLabel == "3 comments")

        // Verify other accessibility labels still work
        let filesLabel = view.filesAccessibilityLabel
        #expect(filesLabel == "8 files changed")
    }

    @Test
    func `displays comment count when metadata unavailable`() throws {
        let view = PreviewMetadataView(
            previewMetadata: nil,
            commentCount: 7,
            currentUserLogin: nil
        )

        let accessibilityLabel = view.commentsAccessibilityLabel
        #expect(accessibilityLabel == "7 comments")
    }

    @Test
    func `handles large comment counts correctly`() throws {
        let view = PreviewMetadataView(
            previewMetadata: nil,
            commentCount: 999,
            currentUserLogin: nil
        )

        let accessibilityLabel = view.commentsAccessibilityLabel
        #expect(accessibilityLabel == "999 comments")
    }

    // MARK: - Reviewer Display Tests

    @Test
    func `displays no reviewers when list is empty`() throws {
        let previewMetadata = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 3,
            requestedReviewers: []
        )
        let view = PreviewMetadataView(
            previewMetadata: previewMetadata,
            commentCount: 0,
            currentUserLogin: nil
        )

        // Verify accessibility label for empty reviewers
        let accessibilityLabel = view.reviewersAccessibilityLabel(reviewers: [])
        #expect(accessibilityLabel == "No reviewers")
    }

    @Test
    func `displays single reviewer correctly`() throws {
        let reviewer = Reviewer(
            login: "octocat",
            avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1")
        )
        let previewMetadata = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 3,
            requestedReviewers: [reviewer]
        )
        let view = PreviewMetadataView(
            previewMetadata: previewMetadata,
            commentCount: 0,
            currentUserLogin: nil
        )

        // Verify accessibility label for single reviewer
        let accessibilityLabel = view.reviewersAccessibilityLabel(reviewers: [reviewer])
        #expect(accessibilityLabel == "1 reviewer: octocat")
    }

    @Test
    func `displays multiple reviewers correctly`() throws {
        let reviewers = [
            Reviewer(login: "octocat", avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1")),
            Reviewer(login: "defunkt", avatarURL: URL(string: "https://avatars.githubusercontent.com/u/2")),
            Reviewer(login: "pjhyett", avatarURL: URL(string: "https://avatars.githubusercontent.com/u/3")),
        ]
        let previewMetadata = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 3,
            requestedReviewers: reviewers
        )
        let view = PreviewMetadataView(
            previewMetadata: previewMetadata,
            commentCount: 0,
            currentUserLogin: nil
        )

        // Verify accessibility label for multiple reviewers
        let accessibilityLabel = view.reviewersAccessibilityLabel(reviewers: reviewers)
        #expect(accessibilityLabel == "3 reviewers: octocat, defunkt, pjhyett")
    }

    @Test
    func `indicates when user is sole reviewer`() throws {
        let reviewer = Reviewer(
            login: "currentuser",
            avatarURL: URL(string: "https://avatars.githubusercontent.com/u/100")
        )
        let previewMetadata = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 3,
            requestedReviewers: [reviewer]
        )
        let view = PreviewMetadataView(
            previewMetadata: previewMetadata,
            commentCount: 0,
            currentUserLogin: "currentuser"
        )

        // Verify accessibility label for sole reviewer
        let accessibilityLabel = view.reviewersAccessibilityLabel(reviewers: [reviewer])
        #expect(accessibilityLabel == "You are the sole reviewer")
    }

    @Test
    func `does not indicate sole reviewer when multiple reviewers present`() throws {
        let reviewers = [
            Reviewer(login: "currentuser", avatarURL: URL(string: "https://avatars.githubusercontent.com/u/100")),
            Reviewer(login: "otheruser", avatarURL: URL(string: "https://avatars.githubusercontent.com/u/101")),
        ]
        let previewMetadata = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 3,
            requestedReviewers: reviewers
        )
        let view = PreviewMetadataView(
            previewMetadata: previewMetadata,
            commentCount: 0,
            currentUserLogin: "currentuser"
        )

        // Verify it doesn't show sole reviewer message
        let accessibilityLabel = view.reviewersAccessibilityLabel(reviewers: reviewers)
        #expect(accessibilityLabel == "2 reviewers: currentuser, otheruser")
    }

    @Test
    func `truncates reviewer list when more than three reviewers`() throws {
        let reviewers = [
            Reviewer(login: "user1", avatarURL: nil),
            Reviewer(login: "user2", avatarURL: nil),
            Reviewer(login: "user3", avatarURL: nil),
            Reviewer(login: "user4", avatarURL: nil),
            Reviewer(login: "user5", avatarURL: nil),
        ]
        let previewMetadata = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 3,
            requestedReviewers: reviewers
        )
        let view = PreviewMetadataView(
            previewMetadata: previewMetadata,
            commentCount: 0,
            currentUserLogin: nil
        )

        // Verify accessibility label shows first 3 reviewers plus count
        let accessibilityLabel = view.reviewersAccessibilityLabel(reviewers: reviewers)
        #expect(accessibilityLabel == "5 reviewers: user1, user2, user3 and 2 more")
    }

    @Test
    func `handles reviewers without avatar URLs`() throws {
        let reviewer = Reviewer(login: "noavatar", avatarURL: nil)
        let previewMetadata = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 3,
            requestedReviewers: [reviewer]
        )
        let view = PreviewMetadataView(
            previewMetadata: previewMetadata,
            commentCount: 0,
            currentUserLogin: nil
        )

        // Verify view renders without crashing
        _ = view.body

        // Verify accessibility label works
        let accessibilityLabel = view.reviewersAccessibilityLabel(reviewers: [reviewer])
        #expect(accessibilityLabel == "1 reviewer: noavatar")
    }
}
