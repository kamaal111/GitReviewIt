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
    @State private var showingFilterSheet = false
    @State private var showingSettings = false
    private let currentUserLogin: String
    private let onLogout: () async -> Void

    /// Creates a new pull request list view
    /// - Parameters:
    ///   - container: The state container managing PR data
    ///   - currentUserLogin: The login name of the currently authenticated user
    ///   - onLogout: Closure to execute when user requests logout
    init(container: PullRequestListContainer, currentUserLogin: String, onLogout: @escaping () async -> Void) {
        _container = State(wrappedValue: container)
        self.currentUserLogin = currentUserLogin
        self.onLogout = onLogout
    }

    var body: some View {
        Group {
            switch container.loadingState {
            case .idle, .loading:
                LoadingView()
                    .accessibilityLabel("Loading pull requests")
            case .loaded(let prs):
                VStack(spacing: 0) {
                    TextField(
                        "Search pull requests",
                        text: Binding(
                            get: { container.filterState.searchQuery },
                            set: { container.filterState.updateSearchQuery($0) }
                        )
                    )
                    .textFieldStyle(.roundedBorder)
                    .padding()

                    // Show active filter chips
                    if hasActiveFilters {
                        FilterChipsView(
                            configuration: container.filterState.configuration,
                            onRemoveOrganization: { org in
                                let newOrgs = container.filterState.configuration
                                    .selectedOrganizations
                                    .filter { $0 != org }
                                let newConfig = FilterConfiguration(
                                    version: 1,
                                    selectedOrganizations: Set(newOrgs),
                                    selectedRepositories: container.filterState.configuration.selectedRepositories,
                                    selectedTeams: container.filterState.configuration.selectedTeams
                                )
                                Task {
                                    await container.filterState.updateFilterConfiguration(newConfig)
                                }
                            },
                            onRemoveRepository: { repo in
                                let newRepos = container.filterState.configuration
                                    .selectedRepositories
                                    .filter { $0 != repo }
                                let newConfig = FilterConfiguration(
                                    version: 1,
                                    selectedOrganizations: container.filterState.configuration.selectedOrganizations,
                                    selectedRepositories: Set(newRepos),
                                    selectedTeams: container.filterState.configuration.selectedTeams
                                )
                                Task {
                                    await container.filterState.updateFilterConfiguration(newConfig)
                                }
                            }
                        )
                        .frame(height: 40)
                    }

                    if container.filteredPullRequests.isEmpty {
                        emptyStateView(totalPRs: prs.count)
                    } else {
                        ScrollViewReader { proxy in
                            List(container.filteredPullRequests) { pr in
                                PullRequestRow(
                                    pullRequest: pr,
                                    currentUserLogin: currentUserLogin,
                                    isEnrichingMetadata: container.isEnrichingMetadata
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    container.openPR(url: pr.htmlURL)
                                }
                                .accessibilityHint("Double tap to open in browser")
                                .id(pr.id)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .refreshable {
                                await container.loadPullRequests()
                            }
                            .onChange(of: container.filteredPullRequests.count) { oldCount, newCount in
                                guard newCount > oldCount else { return }
                                guard let firstPR = container.filteredPullRequests.first else { return }

                                withAnimation {
                                    proxy.scrollTo(firstPR.id, anchor: .top)
                                }
                            }
                        }
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
                        showingSettings = true
                    },
                    label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                )
                .accessibilityLabel("Open settings")
            }

            ToolbarItem(placement: .automatic) {
                Button(
                    action: {
                        Task {
                            await container.loadPullRequests()
                        }
                    },
                    label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                )
                .keyboardShortcut("r", modifiers: .command)
                .accessibilityLabel("Refresh pull requests")
                .disabled(container.loadingState == .loading)
            }

            ToolbarItem(placement: .automatic) {
                Button(
                    action: {
                        showingFilterSheet = true
                    },
                    label: {
                        Label(
                            "Filter",
                            systemImage: hasActiveFilters
                                ? "line.3.horizontal.decrease.circle.fill"
                                : "line.3.horizontal.decrease.circle"
                        )
                    }
                )
                .accessibilityLabel("Filter pull requests")
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterSheet(
                metadata: container.filterState.metadata,
                currentConfiguration: container.filterState.configuration,
                onApply: { newConfig in
                    Task {
                        await container.filterState.updateFilterConfiguration(newConfig)
                    }
                    showingFilterSheet = false
                },
                onCancel: {
                    showingFilterSheet = false
                },
                onClearAll: {
                    Task {
                        await container.filterState.clearAllFilters()
                    }
                    showingFilterSheet = false
                }
            )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(onLogout: onLogout)
        }
        .alert(
            "Filter Error",
            isPresented: Binding(
                get: { container.filterState.errorMessage != nil },
                set: { if !$0 { container.filterState.clearError() } }
            )
        ) {
            Button("OK") {
                container.filterState.clearError()
            }
        } message: {
            if let errorMessage = container.filterState.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Helper Views and Properties

    private var hasActiveFilters: Bool {
        !container.filterState.configuration.selectedOrganizations.isEmpty
            || !container.filterState.configuration.selectedRepositories.isEmpty
            || !container.filterState.configuration.selectedTeams.isEmpty
    }

    @ViewBuilder
    private func emptyStateView(totalPRs: Int) -> some View {
        if totalPRs == 0 {
            ContentUnavailableView(
                "No Pull Requests",
                systemImage: "checkmark.circle",
                description: Text("You have no pull requests awaiting your review.")
            )
            .accessibilityLabel("No pull requests found")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            let hasSearch = !container.filterState.searchQuery.isEmpty

            VStack(spacing: 16) {
                ContentUnavailableView(
                    hasActiveFilters && hasSearch
                        ? "No Matching Results"
                        : hasActiveFilters
                            ? "No PRs Match Filters"
                            : "No Search Results",
                    systemImage: "magnifyingglass",
                    description: Text(emptyStateDescription(hasSearch: hasSearch))
                )

                if hasActiveFilters || hasSearch {
                    HStack(spacing: 12) {
                        if hasSearch {
                            Button("Clear Search") {
                                container.filterState.clearSearchQuery()
                            }
                        }

                        if hasActiveFilters {
                            Button("Clear Filters") {
                                Task {
                                    await container.filterState.clearAllFilters()
                                }
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func emptyStateDescription(hasSearch: Bool) -> String {
        let hasFilters = hasActiveFilters

        if hasFilters && hasSearch {
            return "No pull requests match both your search and filter criteria. "
                + "Try adjusting your filters or search query."
        } else if hasFilters {
            return "No pull requests match your current filters. Try selecting different organizations or repositories."
        } else {
            return "No pull requests match '\(container.filterState.searchQuery)'. Try a different search query."
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

        func fetchPRDetails(
            owner: String,
            repo: String,
            number: Int,
            credentials: GitHubCredentials
        ) async throws -> PRPreviewMetadata {
            PRPreviewMetadata(
                additions: 145,
                deletions: 23,
                changedFiles: 7,
                requestedReviewers: []
            )
        }

        func fetchPRReviews(
            owner: String,
            repo: String,
            number: Int,
            credentials: GitHubCredentials
        ) async throws -> [PRReviewResponse] {
            []
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
                currentUserLogin: "kamaal111",
                onLogout: {}
            )
        }
    }
#endif
