//
//  ContentView.swift
//  GitReviewIt
//
//  Created by Kamaal M Farah on 12/20/25.
//

import SwiftUI

/// Root view that manages navigation between authentication and main app screens.
/// Checks for existing credentials on launch and shows appropriate view based on auth state.
struct ContentView: View {

    // MARK: - Dependencies

    private let githubAPI: GitHubAPI
    private let credentialStorage: CredentialStorage

    // MARK: - State Container

    @State private var authContainer: AuthenticationContainer

    // MARK: - Initialization

    init(
        githubAPI: GitHubAPI = GitHubAPIClient(httpClient: URLSessionHTTPClient()),
        credentialStorage: CredentialStorage = KeychainCredentialStorage()
    ) {
        self.githubAPI = githubAPI
        self.credentialStorage = credentialStorage
        self.authContainer = AuthenticationContainer(
            githubAPI: githubAPI,
            credentialStorage: credentialStorage
        )
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch authContainer.authState {
            case .unknown:
                // Initial state - show loading while checking for stored credentials
                LoadingView(message: "Loading...")
            case .authenticated:
                // User is authenticated - show main app
                if let user = authContainer.authState.user {
                    PullRequestListView(
                        container: PullRequestListContainer(
                            githubAPI: githubAPI,
                            credentialStorage: credentialStorage
                        ),
                        currentUserLogin: user.login,
                        onLogout: {
                            await authContainer.logout()
                        }
                    )
                } else {
                    // Fallback if user is missing (shouldn't happen)
                    LoadingView(message: "Loading user...")
                }
            case .unauthenticated:
                // User is not authenticated - show login
                LoginView(container: authContainer)
            }
        }
        .task {
            // Check for existing credentials on launch
            await authContainer.checkExistingCredentials()
        }
    }
}

#if DEBUG
    private struct PreviewGitHubAPI: GitHubAPI {
        func fetchUser(credentials: GitHubCredentials) async throws -> AuthenticatedUser {
            AuthenticatedUser(login: "kamaal111", name: "Kamaal", avatarURL: nil)
        }

        func fetchTeams(credentials: GitHubCredentials) async throws -> [Team] { [] }

        func fetchReviewRequests(credentials: GitHubCredentials) async throws -> [PullRequest] { [] }

        func fetchPRDetails(
            owner: String,
            repo: String,
            number: Int,
            credentials: GitHubCredentials
        ) async throws -> PRPreviewMetadata {
            PRPreviewMetadata(
                additions: 10,
                deletions: 5,
                changedFiles: 2,
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

        func fetchCheckRuns(
            owner: String,
            repo: String,
            ref: String,
            credentials: GitHubCredentials
        ) async throws -> CheckRunsResponse {
            CheckRunsResponse(total_count: 0, check_runs: [])
        }
    }

    private struct PreviewCredentialStorage: CredentialStorage {
        func store(_ credentials: GitHubCredentials) async throws {}
        func retrieve() async throws -> GitHubCredentials? { nil }
        func delete() async throws {}
    }

    #Preview {
        ContentView(
            githubAPI: PreviewGitHubAPI(),
            credentialStorage: PreviewCredentialStorage()
        )
    }
#endif
