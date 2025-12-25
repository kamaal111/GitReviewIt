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
            commentCount: 12
        )

        // Test that view renders without crashing
        _ = view.body
    }

    @Test
    func `displays zero comments when count is zero`() throws {
        let view = PreviewMetadataView(
            previewMetadata: nil,
            commentCount: 0
        )

        // Verify accessibility label for zero comments
        let accessibilityLabel = view.commentsAccessibilityLabel
        #expect(accessibilityLabel == "No comments")
    }

    @Test
    func `displays unavailable for nil comment count`() throws {
        let view = PreviewMetadataView(
            previewMetadata: nil,
            commentCount: nil
        )

        // Verify accessibility label for unavailable comments
        let accessibilityLabel = view.commentsAccessibilityLabel
        #expect(accessibilityLabel == "Comments: unavailable")
    }

    @Test
    func `accessibility label uses singular for one comment`() throws {
        let view = PreviewMetadataView(
            previewMetadata: nil,
            commentCount: 1
        )

        let accessibilityLabel = view.commentsAccessibilityLabel
        #expect(accessibilityLabel == "1 comment")
    }

    @Test
    func `accessibility label uses plural for multiple comments`() throws {
        let view = PreviewMetadataView(
            previewMetadata: nil,
            commentCount: 5
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
            commentCount: 3
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
            commentCount: 7
        )

        let accessibilityLabel = view.commentsAccessibilityLabel
        #expect(accessibilityLabel == "7 comments")
    }

    @Test
    func `handles large comment counts correctly`() throws {
        let view = PreviewMetadataView(
            previewMetadata: nil,
            commentCount: 999
        )

        let accessibilityLabel = view.commentsAccessibilityLabel
        #expect(accessibilityLabel == "999 comments")
    }
}
