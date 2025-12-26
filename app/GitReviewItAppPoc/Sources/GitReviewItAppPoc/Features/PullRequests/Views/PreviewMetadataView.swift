import SwiftUI

/// A view that displays preview metadata for a pull request
///
/// Shows change statistics (additions, deletions, changed files),
/// comment count, reviewer information, and labels when available.
/// Displays "—" for unavailable data to distinguish from zero values.
struct PreviewMetadataView: View {
    /// The preview metadata to display, or nil if not yet loaded
    let previewMetadata: PRPreviewMetadata?

    /// The comment count from the Search API (always available)
    let commentCount: Int?

    /// The labels associated with the PR (always available from Search API)
    let labels: [PRLabel]

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

            // Comments - prefer metadata's totalCommentCount when available,
            // otherwise fall back to Search API commentCount
            metadataItem(
                value: previewMetadata?.totalCommentCount ?? commentCount,
                label: "💬",
                accessibilityLabel: commentsAccessibilityLabel
            )

            // Check status (only show if metadata is loaded and not unknown)
            if let checkStatus = previewMetadata?.checkStatus, checkStatus != .unknown {
                checkStatusView(status: checkStatus)
            }

            // Merge status (only show if metadata is loaded and not unknown)
            if let mergeStatus = previewMetadata?.mergeStatus, mergeStatus != .unknown {
                mergeStatusView(status: mergeStatus)
            }

            // Reviewers (all reviewers - both requested and completed)
            if let reviewers = previewMetadata?.allReviewers, !reviewers.isEmpty {
                reviewersView(reviewers: reviewers)
            }

            // Labels
            if !labels.isEmpty {
                labelsView(labels: labels)
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

    /// Creates a view displaying CI/CD check status
    ///
    /// - Parameter status: The check status to display
    /// - Returns: A view displaying the check status indicator
    @ViewBuilder
    private func checkStatusView(status: PRCheckStatus) -> some View {
        let (icon, color, label) = checkStatusAttributes(status: status)

        HStack(spacing: 2) {
            Text(icon)
            Text(label)
                .foregroundStyle(color)
        }
        .accessibilityLabel(checkStatusAccessibilityLabel(status: status))
    }

    /// Returns display attributes for a check status
    ///
    /// - Parameter status: The check status
    /// - Returns: Tuple of (icon, color, label)
    private func checkStatusAttributes(status: PRCheckStatus) -> (String, Color, String) {
        switch status {
        case .passing:
            return ("✓", .green, "CI")
        case .failing:
            return ("✗", .red, "CI")
        case .pending:
            return ("○", .orange, "CI")
        case .unknown:
            return ("", .secondary, "")
        }
    }

    /// Creates a view displaying mergeability status
    ///
    /// - Parameter status: The merge status to display
    /// - Returns: A view displaying the merge status indicator
    @ViewBuilder
    private func mergeStatusView(status: PRMergeStatus) -> some View {
        let (icon, color, label) = mergeStatusAttributes(status: status)

        HStack(spacing: 2) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text("Merge")
                .foregroundStyle(color)
        }
        .accessibilityLabel(label)
    }

    /// Returns display attributes for a merge status
    ///
    /// - Parameter status: The merge status
    /// - Returns: Tuple of (icon, color, label)
    private func mergeStatusAttributes(status: PRMergeStatus) -> (String, Color, String) {
        switch status {
        case .mergeable:
            return ("checkmark.circle", .green, "Mergeable")
        case .conflicting:
            return ("exclamationmark.triangle", .red, "Conflicting")
        case .unknown:
            return ("questionmark.circle", .secondary, "Merge status unknown")
        }
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

    /// Creates a view displaying labels with color-coded backgrounds
    ///
    /// - Parameter labels: The list of PR labels
    /// - Returns: A view displaying label tags
    @ViewBuilder
    private func labelsView(labels: [PRLabel]) -> some View {
        HStack(spacing: 4) {
            // Show up to 3 labels
            ForEach(labels.prefix(3)) { label in
                labelTag(label: label)
            }

            // Show count for additional labels
            if labels.count > 3 {
                Text("+\(labels.count - 3)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityLabel(labelsAccessibilityLabel(labels: labels))
    }

    /// Creates a single label tag with color-coded background
    ///
    /// - Parameter label: The label to display
    /// - Returns: A view displaying the label tag
    @ViewBuilder
    private func labelTag(label: PRLabel) -> some View {
        let backgroundColor = Color(hex: label.color) ?? .secondary
        let textColor = backgroundColor.contrastingTextColor()

        Text(label.name)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .foregroundStyle(textColor)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .accessibilityLabel("Label: \(label.name)")
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
        // Prefer metadata's totalCommentCount when available, otherwise use Search API commentCount
        let count = previewMetadata?.totalCommentCount ?? commentCount

        guard let count = count else {
            return "Comments: unavailable"
        }

        if count == 0 {
            return "No comments"
        }

        let commentWord = count == 1 ? "comment" : "comments"
        return "\(count) \(commentWord)"
    }

    /// Generates an accessibility label for check status
    ///
    /// - Parameter status: The check status
    /// - Returns: A descriptive accessibility label
    func checkStatusAccessibilityLabel(status: PRCheckStatus) -> String {
        switch status {
        case .passing:
            return "CI checks passing"
        case .failing:
            return "CI checks failing"
        case .pending:
            return "CI checks pending"
        case .unknown:
            return "CI checks status unknown"
        }
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

    /// Generates an accessibility label for the label list
    ///
    /// - Parameter labels: The list of PR labels
    /// - Returns: A descriptive accessibility label
    func labelsAccessibilityLabel(labels: [PRLabel]) -> String {
        guard !labels.isEmpty else {
            return "No labels"
        }

        let labelWord = labels.count == 1 ? "label" : "labels"
        let names = labels.prefix(3).map { $0.name }.joined(separator: ", ")

        if labels.count > 3 {
            return "\(labels.count) \(labelWord): \(names) and \(labels.count - 3) more"
        } else {
            return "\(labels.count) \(labelWord): \(names)"
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
        labels: [],
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
        labels: [],
        currentUserLogin: nil
    )
    .padding()
}

#Preview("Unavailable Data") {
    PreviewMetadataView(
        previewMetadata: nil,
        commentCount: nil,
        labels: [],
        currentUserLogin: nil
    )
    .padding()
}

#Preview("With Comments Only") {
    PreviewMetadataView(
        previewMetadata: nil,
        commentCount: 5,
        labels: [],
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
        labels: [],
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
        labels: [],
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
        labels: [],
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
        labels: [],
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
        labels: [],
        currentUserLogin: nil
    )
    .padding()
}

#Preview("With Labels") {
    PreviewMetadataView(
        previewMetadata: PRPreviewMetadata(
            additions: 120,
            deletions: 45,
            changedFiles: 8,
            requestedReviewers: []
        ),
        commentCount: 5,
        labels: [
            PRLabel(name: "bug", color: "d73a4a"),
            PRLabel(name: "enhancement", color: "a2eeef"),
            PRLabel(name: "documentation", color: "0075ca"),
        ],
        currentUserLogin: nil
    )
    .padding()
}

#Preview("With Many Labels") {
    PreviewMetadataView(
        previewMetadata: nil,
        commentCount: 8,
        labels: [
            PRLabel(name: "bug", color: "d73a4a"),
            PRLabel(name: "urgent", color: "ff6b6b"),
            PRLabel(name: "backend", color: "0e8a16"),
            PRLabel(name: "frontend", color: "1d76db"),
            PRLabel(name: "needs-review", color: "fbca04"),
        ],
        currentUserLogin: nil
    )
    .padding()
}

#Preview("Labels Only") {
    PreviewMetadataView(
        previewMetadata: nil,
        commentCount: nil,
        labels: [
            PRLabel(name: "feature", color: "84b6eb"),
            PRLabel(name: "high-priority", color: "d93f0b"),
        ],
        currentUserLogin: nil
    )
    .padding()
}
