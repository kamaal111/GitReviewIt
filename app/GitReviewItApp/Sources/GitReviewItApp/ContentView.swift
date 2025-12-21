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
                PullRequestListView(
                    container: PullRequestListContainer(
                        githubAPI: githubAPI,
                        credentialStorage: credentialStorage
                    ),
                    onLogout: {
                        await authContainer.logout()
                    }
                )
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
