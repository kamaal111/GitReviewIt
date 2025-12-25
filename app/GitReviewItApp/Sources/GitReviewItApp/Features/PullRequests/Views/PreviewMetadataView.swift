import SwiftUI

/// A view that displays preview metadata for a pull request
///
/// Shows change statistics (additions, deletions, changed files),
/// comment count, and reviewer information when available.
/// Displays "—" for unavailable data to distinguish from zero values.
struct PreviewMetadataView: View {
    /// The preview metadata to display, or nil if not yet loaded
    let previewMetadata: PRPreviewMetadata?

    /// The comment count from the Search API (always available)
    let commentCount: Int?

    /// The currently authenticated user's login (optional, used to determine sole reviewer status)
    let currentUserLogin: String?

    var body: some View {
        HStack(spacing: 8) {
            // Changed files
            metadataItem(
                value: previewMetadata?.changedFiles,
                label: "files",
                accessibilityLabel: filesAccessibilityLabel
            )

            // Additions
            metadataItem(
                value: previewMetadata?.additions,
                label: "+",
                color: .green,
                accessibilityLabel: additionsAccessibilityLabel
            )

            // Deletions
            metadataItem(
                value: previewMetadata?.deletions,
                label: "−",
                color: .red,
                accessibilityLabel: deletionsAccessibilityLabel
            )

            // Comments
            metadataItem(
                value: commentCount,
                label: "💬",
                accessibilityLabel: commentsAccessibilityLabel
            )

            // Reviewers (all reviewers - both requested and completed)
            if let reviewers = previewMetadata?.allReviewers, !reviewers.isEmpty {
                reviewersView(reviewers: reviewers)
            }
        }
        .font(.caption)
        .accessibilityElement(children: .combine)
    }

    /// Creates a metadata item view
    ///
    /// - Parameters:
    ///   - value: The numeric value to display, or nil if unavailable
    ///   - label: The label text (e.g., "files", "+", "−")
    ///   - color: Optional color for the value
    ///   - accessibilityLabel: Accessibility label for VoiceOver
    /// - Returns: A view displaying the metadata item
    @ViewBuilder
    private func metadataItem(
        value: Int?,
        label: String,
        color: Color? = nil,
        accessibilityLabel: String
    ) -> some View {
        HStack(spacing: 2) {
            if let value = value {
                Text("\(value)")
                    .foregroundStyle(color ?? .primary)
            } else {
                Text("—")
                    .foregroundStyle(.secondary)
            }

            Text(label)
                .foregroundStyle(.secondary)
        }
        .accessibilityLabel(accessibilityLabel)
    }

    /// Creates a view displaying reviewer avatars and count
    ///
    /// - Parameter reviewers: The list of requested reviewers
    /// - Returns: A view displaying reviewer information
    @ViewBuilder
    private func reviewersView(reviewers: [Reviewer]) -> some View {
        HStack(spacing: 4) {
            // Show up to 3 reviewer avatars
            ForEach(reviewers.prefix(3)) { reviewer in
                if let avatarURL = reviewer.avatarURL {
                    AsyncImage(url: avatarURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.secondary.opacity(0.3))
                    }
                    .frame(width: 16, height: 16)
                    .clipShape(Circle())
                    .accessibilityLabel("Reviewer: \(reviewer.login)")
                } else {
                    // Fallback for reviewers without avatar URLs
                    Circle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 16, height: 16)
                        .overlay {
                            Text(String(reviewer.login.prefix(1).uppercased()))
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(.primary)
                        }
                        .accessibilityLabel("Reviewer: \(reviewer.login)")
                }
            }

            // Show reviewer count with special indicator for sole reviewer
            if isSoleReviewer(reviewers: reviewers) {
                Text("(sole)")
                    .foregroundStyle(.orange)
            } else if reviewers.count > 3 {
                Text("+\(reviewers.count - 3)")
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityLabel(reviewersAccessibilityLabel(reviewers: reviewers))
    }

    // MARK: - Accessibility Labels

    var filesAccessibilityLabel: String {
        guard let changedFiles = previewMetadata?.changedFiles else {
            return "Files changed: unavailable"
        }

        let fileWord = changedFiles == 1 ? "file" : "files"
        return "\(changedFiles) \(fileWord) changed"
    }

    var additionsAccessibilityLabel: String {
        guard let additions = previewMetadata?.additions else {
            return "Lines added: unavailable"
        }

        let lineWord = additions == 1 ? "line" : "lines"
        return "\(additions) \(lineWord) added"
    }

    var deletionsAccessibilityLabel: String {
        guard let deletions = previewMetadata?.deletions else {
            return "Lines deleted: unavailable"
        }

        let lineWord = deletions == 1 ? "line" : "lines"
        return "\(deletions) \(lineWord) deleted"
    }

    var commentsAccessibilityLabel: String {
        guard let commentCount = commentCount else {
            return "Comments: unavailable"
        }

        if commentCount == 0 {
            return "No comments"
        }

        let commentWord = commentCount == 1 ? "comment" : "comments"
        return "\(commentCount) \(commentWord)"
    }

    /// Generates an accessibility label for the reviewer list
    ///
    /// - Parameter reviewers: The list of requested reviewers
    /// - Returns: A descriptive accessibility label
    func reviewersAccessibilityLabel(reviewers: [Reviewer]) -> String {
        guard !reviewers.isEmpty else {
            return "No reviewers"
        }

        if isSoleReviewer(reviewers: reviewers) {
            return "You are the sole reviewer"
        }

        let reviewerWord = reviewers.count == 1 ? "reviewer" : "reviewers"
        let names = reviewers.prefix(3).map { $0.login }.joined(separator: ", ")

        if reviewers.count > 3 {
            return "\(reviewers.count) \(reviewerWord): \(names) and \(reviewers.count - 3) more"
        } else {
            return "\(reviewers.count) \(reviewerWord): \(names)"
        }
    }

    /// Checks if the current user is the sole reviewer
    ///
    /// - Parameter reviewers: The list of requested reviewers
    /// - Returns: True if current user is the only reviewer
    private func isSoleReviewer(reviewers: [Reviewer]) -> Bool {
        guard let currentUserLogin = currentUserLogin else {
            return false
        }

        guard reviewers.count == 1 else {
            return false
        }

        guard let firstReviewer = reviewers.first else {
            return false
        }

        return firstReviewer.login == currentUserLogin
    }
}

// MARK: - Previews

#Preview("With Metadata") {
    PreviewMetadataView(
        previewMetadata: PRPreviewMetadata(
            additions: 145,
            deletions: 23,
            changedFiles: 7,
            requestedReviewers: []
        ),
        commentCount: 12,
        currentUserLogin: nil
    )
    .padding()
}

#Preview("Zero Values") {
    PreviewMetadataView(
        previewMetadata: PRPreviewMetadata(
            additions: 0,
            deletions: 0,
            changedFiles: 1,
            requestedReviewers: []
        ),
        commentCount: 0,
        currentUserLogin: nil
    )
    .padding()
}

#Preview("Unavailable Data") {
    PreviewMetadataView(
        previewMetadata: nil,
        commentCount: nil,
        currentUserLogin: nil
    )
    .padding()
}

#Preview("With Comments Only") {
    PreviewMetadataView(
        previewMetadata: nil,
        commentCount: 5,
        currentUserLogin: nil
    )
    .padding()
}

#Preview("With Single Reviewer") {
    PreviewMetadataView(
        previewMetadata: PRPreviewMetadata(
            additions: 45,
            deletions: 12,
            changedFiles: 3,
            requestedReviewers: [
                Reviewer(login: "octocat", avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1"))
            ]
        ),
        commentCount: 2,
        currentUserLogin: nil
    )
    .padding()
}

#Preview("With Multiple Reviewers") {
    PreviewMetadataView(
        previewMetadata: PRPreviewMetadata(
            additions: 145,
            deletions: 23,
            changedFiles: 7,
            requestedReviewers: [
                Reviewer(login: "octocat", avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1")),
                Reviewer(login: "defunkt", avatarURL: URL(string: "https://avatars.githubusercontent.com/u/2")),
                Reviewer(login: "pjhyett", avatarURL: URL(string: "https://avatars.githubusercontent.com/u/3")),
            ]
        ),
        commentCount: 8,
        currentUserLogin: nil
    )
    .padding()
}

#Preview("With Many Reviewers") {
    PreviewMetadataView(
        previewMetadata: PRPreviewMetadata(
            additions: 200,
            deletions: 50,
            changedFiles: 12,
            requestedReviewers: [
                Reviewer(login: "octocat", avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1")),
                Reviewer(login: "defunkt", avatarURL: URL(string: "https://avatars.githubusercontent.com/u/2")),
                Reviewer(login: "pjhyett", avatarURL: URL(string: "https://avatars.githubusercontent.com/u/3")),
                Reviewer(login: "wycats", avatarURL: nil),
                Reviewer(login: "ezmobius", avatarURL: nil),
            ]
        ),
        commentCount: 15,
        currentUserLogin: nil
    )
    .padding()
}

#Preview("Sole Reviewer") {
    PreviewMetadataView(
        previewMetadata: PRPreviewMetadata(
            additions: 75,
            deletions: 18,
            changedFiles: 4,
            requestedReviewers: [
                Reviewer(login: "currentuser", avatarURL: URL(string: "https://avatars.githubusercontent.com/u/100"))
            ]
        ),
        commentCount: 3,
        currentUserLogin: "currentuser"
    )
    .padding()
}

#Preview("Reviewer Without Avatar") {
    PreviewMetadataView(
        previewMetadata: PRPreviewMetadata(
            additions: 30,
            deletions: 10,
            changedFiles: 2,
            requestedReviewers: [
                Reviewer(login: "noavatar", avatarURL: nil)
            ]
        ),
        commentCount: 1,
        currentUserLogin: nil
    )
    .padding()
}
