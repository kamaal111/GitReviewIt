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
            switch authContainer.authState {
            case .unknown:
                // Initial state - show loading while checking for stored credentials
                LoadingView(message: "Loading...")
            case .authenticated:
                // User is authenticated - show main app
                PullRequestListView()
            case .unauthenticated:
                // User is not authenticated - show login
                if authContainer.isLoading {
                    LoadingView(message: "Signing in...")
                } else {
                    LoginView(container: authContainer)
                }
            }
        }
        .task {
            // Check for existing credentials on launch
            await authContainer.checkExistingCredentials()
        }
    }
}
