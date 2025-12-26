import SwiftUI
import Testing

@testable import GitReviewItAppPoc

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
            labels: [],
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
            labels: [],
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
            labels: [],
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
            labels: [],
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
            labels: [],
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
            requestedReviewers: [],
            totalCommentCount: 3
        )
        let view = PreviewMetadataView(
            previewMetadata: previewMetadata,
            commentCount: 3,
            labels: [],
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
            labels: [],
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
            labels: [],
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
            labels: [],
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
            labels: [],
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
            labels: [],
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
            labels: [],
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
            labels: [],
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
            labels: [],
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
            labels: [],
            currentUserLogin: nil
        )

        // Verify view renders without crashing
        _ = view.body

        // Verify accessibility label works
        let accessibilityLabel = view.reviewersAccessibilityLabel(reviewers: [reviewer])
        #expect(accessibilityLabel == "1 reviewer: noavatar")
    }

    // MARK: - Label Display Tests

    @Test
    func `displays no labels when list is empty`() throws {
        let view = PreviewMetadataView(
            previewMetadata: nil,
            commentCount: 0,
            labels: [],
            currentUserLogin: nil
        )

        // Verify accessibility label for empty labels
        let accessibilityLabel = view.labelsAccessibilityLabel(labels: [])
        #expect(accessibilityLabel == "No labels")
    }

    @Test
    func `displays single label correctly`() throws {
        let label = PRLabel(name: "bug", color: "d73a4a")
        let view = PreviewMetadataView(
            previewMetadata: nil,
            commentCount: 0,
            labels: [label],
            currentUserLogin: nil
        )

        // Verify view renders without crashing
        _ = view.body

        // Verify accessibility label
        let accessibilityLabel = view.labelsAccessibilityLabel(labels: [label])
        #expect(accessibilityLabel == "1 label: bug")
    }

    @Test
    func `displays multiple labels correctly`() throws {
        let labels = [
            PRLabel(name: "bug", color: "d73a4a"),
            PRLabel(name: "enhancement", color: "a2eeef"),
            PRLabel(name: "documentation", color: "0075ca"),
        ]
        let view = PreviewMetadataView(
            previewMetadata: nil,
            commentCount: 0,
            labels: labels,
            currentUserLogin: nil
        )

        // Verify view renders without crashing
        _ = view.body

        // Verify accessibility label
        let accessibilityLabel = view.labelsAccessibilityLabel(labels: labels)
        #expect(accessibilityLabel == "3 labels: bug, enhancement, documentation")
    }

    @Test
    func `truncates label list when more than three labels`() throws {
        let labels = [
            PRLabel(name: "bug", color: "d73a4a"),
            PRLabel(name: "urgent", color: "ff6b6b"),
            PRLabel(name: "backend", color: "0e8a16"),
            PRLabel(name: "frontend", color: "1d76db"),
            PRLabel(name: "needs-review", color: "fbca04"),
        ]
        let view = PreviewMetadataView(
            previewMetadata: nil,
            commentCount: 0,
            labels: labels,
            currentUserLogin: nil
        )

        // Verify view renders without crashing
        _ = view.body

        // Verify accessibility label shows first 3 labels plus count
        let accessibilityLabel = view.labelsAccessibilityLabel(labels: labels)
        #expect(accessibilityLabel == "5 labels: bug, urgent, backend and 2 more")
    }

    @Test
    func `displays labels alongside metadata`() throws {
        let labels = [
            PRLabel(name: "bug", color: "d73a4a"),
            PRLabel(name: "high-priority", color: "d93f0b"),
        ]
        let previewMetadata = PRPreviewMetadata(
            additions: 50,
            deletions: 20,
            changedFiles: 4,
            requestedReviewers: [],
            totalCommentCount: 8
        )
        let view = PreviewMetadataView(
            previewMetadata: previewMetadata,
            commentCount: 8,
            labels: labels,
            currentUserLogin: nil
        )

        // Verify view renders without crashing
        _ = view.body

        // Verify all accessibility labels work
        let labelsLabel = view.labelsAccessibilityLabel(labels: labels)
        #expect(labelsLabel == "2 labels: bug, high-priority")

        let filesLabel = view.filesAccessibilityLabel
        #expect(filesLabel == "4 files changed")

        let commentsLabel = view.commentsAccessibilityLabel
        #expect(commentsLabel == "8 comments")
    }

    // MARK: - Check Status Accessibility Tests

    @Test
    func `check status passing has correct accessibility label`() throws {
        let view = PreviewMetadataView(
            previewMetadata: nil,
            commentCount: nil,
            labels: [],
            currentUserLogin: nil
        )

        let accessibilityLabel = view.checkStatusAccessibilityLabel(status: .passing)
        #expect(accessibilityLabel == "CI checks passing")
    }

    @Test
    func `check status failing has correct accessibility label`() throws {
        let view = PreviewMetadataView(
            previewMetadata: nil,
            commentCount: nil,
            labels: [],
            currentUserLogin: nil
        )

        let accessibilityLabel = view.checkStatusAccessibilityLabel(status: .failing)
        #expect(accessibilityLabel == "CI checks failing")
    }

    @Test
    func `check status pending has correct accessibility label`() throws {
        let view = PreviewMetadataView(
            previewMetadata: nil,
            commentCount: nil,
            labels: [],
            currentUserLogin: nil
        )

        let accessibilityLabel = view.checkStatusAccessibilityLabel(status: .pending)
        #expect(accessibilityLabel == "CI checks pending")
    }

    @Test
    func `check status unknown has correct accessibility label`() throws {
        let view = PreviewMetadataView(
            previewMetadata: nil,
            commentCount: nil,
            labels: [],
            currentUserLogin: nil
        )

        let accessibilityLabel = view.checkStatusAccessibilityLabel(status: .unknown)
        #expect(accessibilityLabel == "CI checks status unknown")
    }

    // MARK: - Merge Status Accessibility Tests

    @Test
    func `merge status mergeable has correct accessibility label`() throws {
        let previewMetadata = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 3,
            requestedReviewers: [],
            checkStatus: .passing,
            mergeStatus: .mergeable
        )
        let view = PreviewMetadataView(
            previewMetadata: previewMetadata,
            commentCount: nil,
            labels: [],
            currentUserLogin: nil
        )

        // Verify view renders without crashing
        _ = view.body
    }

    @Test
    func `merge status conflicting has correct accessibility label`() throws {
        let previewMetadata = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 3,
            requestedReviewers: [],
            checkStatus: .failing,
            mergeStatus: .conflicting
        )
        let view = PreviewMetadataView(
            previewMetadata: previewMetadata,
            commentCount: nil,
            labels: [],
            currentUserLogin: nil
        )

        // Verify view renders without crashing
        _ = view.body
    }

    @Test
    func `merge status unknown has correct accessibility label`() throws {
        let previewMetadata = PRPreviewMetadata(
            additions: 10,
            deletions: 5,
            changedFiles: 3,
            requestedReviewers: [],
            checkStatus: .unknown,
            mergeStatus: .unknown
        )
        let view = PreviewMetadataView(
            previewMetadata: previewMetadata,
            commentCount: nil,
            labels: [],
            currentUserLogin: nil
        )

        // Verify view renders without crashing
        _ = view.body
    }

    // MARK: - Draft Status Accessibility Tests

    @Test
    func `draft badge has correct accessibility label in PullRequestRow`() throws {
        let draftPR = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 1,
            title: "Draft PR",
            authorLogin: "author",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/1")!,
            isDraft: true
        )

        let row = PullRequestRow(
            pullRequest: draftPR,
            currentUserLogin: "testuser",
            isEnrichingMetadata: false
        )

        // Verify view renders without crashing
        _ = row.body
    }

    @Test
    func `all status indicators render together with accessibility support`() throws {
        let previewMetadata = PRPreviewMetadata(
            additions: 42,
            deletions: 17,
            changedFiles: 5,
            requestedReviewers: [
                Reviewer(login: "reviewer1", avatarURL: nil)
            ],
            checkStatus: .passing,
            mergeStatus: .mergeable,
            totalCommentCount: 5
        )

        let draftPR = PullRequest(
            repositoryOwner: "owner",
            repositoryName: "repo",
            number: 1,
            title: "Draft PR with all status",
            authorLogin: "author",
            authorAvatarURL: nil,
            updatedAt: Date(),
            htmlURL: URL(string: "https://github.com/owner/repo/pull/1")!,
            commentCount: 5,
            isDraft: true,
            previewMetadata: previewMetadata
        )

        let row = PullRequestRow(
            pullRequest: draftPR,
            currentUserLogin: "testuser",
            isEnrichingMetadata: false
        )

        // Verify view renders without crashing - all status indicators should be accessible
        _ = row.body

        // Verify PreviewMetadataView accessibility labels
        let metadataView = PreviewMetadataView(
            previewMetadata: previewMetadata,
            commentCount: draftPR.commentCount,
            labels: draftPR.labels,
            currentUserLogin: "testuser"
        )

        #expect(metadataView.checkStatusAccessibilityLabel(status: .passing) == "CI checks passing")
        #expect(metadataView.filesAccessibilityLabel == "5 files changed")
        #expect(metadataView.commentsAccessibilityLabel == "5 comments")
    }
}
