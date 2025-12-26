import SwiftUI

/// A row view representing a single pull request in the list
struct PullRequestRow: View {
    /// The pull request to display
    let pullRequest: PullRequest
    /// The login name of the currently authenticated user
    let currentUserLogin: String
    /// Indicates whether metadata enrichment is currently in progress
    let isEnrichingMetadata: Bool

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: pullRequest.updatedAt, relativeTo: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(pullRequest.repositoryFullName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Repository: \(pullRequest.repositoryFullName)")

            HStack(spacing: 6) {
                Text(pullRequest.title)
                    .font(.headline)
                    .lineLimit(2)

                if pullRequest.isDraft {
                    Text("DRAFT")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.15))
                        )
                        .accessibilityLabel("Draft")
                }

                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Title: \(pullRequest.title)\(pullRequest.isDraft ? ", Draft" : "")")

            HStack(spacing: 4) {
                if let avatarURL = pullRequest.authorAvatarURL {
                    AsyncImage(url: avatarURL) { image in
                        image.resizable()
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 16, height: 16)
                    .clipShape(Circle())
                    .accessibilityHidden(true)
                }

                Text(pullRequest.authorLogin)
                    .font(.caption)
                    .fontWeight(.medium)

                Text("•")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(relativeTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    // Loading indicator when metadata enrichment is in progress and metadata not yet loaded
                    if isEnrichingMetadata && pullRequest.previewMetadata == nil {
                        ProgressView()
                            .controlSize(.small)
                            .accessibilityLabel("Loading metadata")
                    }

                    PreviewMetadataView(
                        previewMetadata: pullRequest.previewMetadata,
                        commentCount: pullRequest.commentCount,
                        labels: pullRequest.labels,
                        currentUserLogin: currentUserLogin
                    )
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Created by \(pullRequest.authorLogin), \(relativeTime)")
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let pr = PullRequest(
        repositoryOwner: "kamaal111",
        repositoryName: "GitReviewIt",
        number: 1,
        title: "Add Pull Request List Feature",
        authorLogin: "kamaal111",
        authorAvatarURL: URL(string: "https://avatars.githubusercontent.com/u/31306306?v=4"),
        updatedAt: Date(),
        htmlURL: URL(string: "https://github.com/kamaal111/GitReviewIt/pull/1")!
    )
    return List {
        PullRequestRow(pullRequest: pr, currentUserLogin: "kamaal111", isEnrichingMetadata: true)
        PullRequestRow(pullRequest: pr, currentUserLogin: "kamaal111", isEnrichingMetadata: false)
    }
}
