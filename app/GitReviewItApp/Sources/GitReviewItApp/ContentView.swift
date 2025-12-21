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

    // MARK: - State Container

    @State private var authContainer: AuthenticationContainer

    // MARK: - Initialization

    init(
        githubAPI: GitHubAPI = GitHubAPIClient(httpClient: URLSessionHTTPClient()),
        credentialStorage: CredentialStorage = KeychainCredentialStorage()
    ) {
        self.authContainer = AuthenticationContainer(
            githubAPI: githubAPI,
            credentialStorage: credentialStorage
        )
    }

    // MARK: - Body

    var body: some View {
        Group {
            if authContainer.isLoading && !authContainer.authState.isAuthenticated {
                // Show loading state during initial credential check
                LoadingView(message: "Checking credentials...")
            } else if authContainer.authState.isAuthenticated {
                // User is authenticated - show main app
                PullRequestListView()
            } else {
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
