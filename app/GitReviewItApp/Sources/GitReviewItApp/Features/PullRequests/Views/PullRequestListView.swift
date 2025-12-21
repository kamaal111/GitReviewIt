import SwiftUI

/// View displaying a list of pull requests awaiting review
///
/// This view handles multiple states:
/// - Loading: Shows a progress indicator
/// - Empty: Shows a message when no PRs are found
/// - Error: Shows an error message with retry button
/// - Loaded: Shows the list of PRs
struct PullRequestListView: View {
    @State private var container: PullRequestListContainer
    private let onLogout: () async -> Void

    /// Creates a new pull request list view
    /// - Parameters:
    ///   - container: The state container managing PR data
    ///   - onLogout: Closure to execute when user requests logout
    init(container: PullRequestListContainer, onLogout: @escaping () async -> Void) {
        _container = State(wrappedValue: container)
        self.onLogout = onLogout
    }

    var body: some View {
        Group {
            switch container.loadingState {
            case .idle, .loading:
                LoadingView()
                    .accessibilityLabel("Loading pull requests")
            case .loaded(let prs):
                if prs.isEmpty {
                    ContentUnavailableView(
                        "No Pull Requests",
                        systemImage: "checkmark.circle",
                        description: Text("You have no pull requests awaiting your review.")
                    )
                    .accessibilityLabel("No pull requests found")
                } else {
                    List(prs) { pr in
                        PullRequestRow(pullRequest: pr)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                container.openPR(url: pr.htmlURL)
                            }
                            .accessibilityHint("Double tap to open in browser")
                    }
                    .refreshable {
                        await container.loadPullRequests()
                    }
                }
            case .failed(let error):
                ErrorView(error: error) {
                    Task {
                        await container.retry()
                    }
                }
            }
        }
        .navigationTitle("Review Requests")
        .task {
            if case .idle = container.loadingState {
                await container.loadPullRequests()
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(
                    action: {
                        Task {
                            await onLogout()
                        }
                    },
                    label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                )
                .accessibilityLabel("Log out")
            }
        }
    }
}

#if DEBUG
    private struct PreviewGitHubAPI: GitHubAPI {
        func fetchUser(credentials: GitHubCredentials) async throws -> AuthenticatedUser {
            AuthenticatedUser(login: "kamaal111", name: "Kamaal", avatarURL: nil)
        }

        func fetchTeams(credentials: GitHubCredentials) async throws -> [Team] { [] }

        func fetchReviewRequests(credentials: GitHubCredentials) async throws -> [PullRequest] {
            [
                PullRequest(
                    repositoryOwner: "kamaal111",
                    repositoryName: "GitReviewIt",
                    number: 1,
                    title: "Add Pull Request List Feature",
                    authorLogin: "kamaal111",
                    authorAvatarURL: nil,
                    updatedAt: Date(),
                    htmlURL: URL(string: "https://github.com/kamaal111/GitReviewIt/pull/1")!
                )
            ]
        }
    }

    private struct PreviewCredentialStorage: CredentialStorage {
        func store(_ credentials: GitHubCredentials) async throws {}
        func retrieve() async throws -> GitHubCredentials? {
            GitHubCredentials(token: "token", baseURL: "https://api.github.com")
        }
        func delete() async throws {}
    }

    #Preview {
        NavigationStack {
            PullRequestListView(
                container: PullRequestListContainer(
                    githubAPI: PreviewGitHubAPI(),
                    credentialStorage: PreviewCredentialStorage()
                ),
                onLogout: {}
            )
        }
    }
#endif
