import Foundation
import Observation

/// State container for authentication flow using Personal Access Tokens.
/// Manages credential validation, storage, and user session state.
@MainActor
@Observable
final class AuthenticationContainer {

    // MARK: - Dependencies

    private let githubAPI: GitHubAPI
    private let credentialStorage: CredentialStorage

    // MARK: - Observable State

    private(set) var authState: AuthState = .unauthenticated
    private(set) var isLoading = false
    private(set) var error: APIError?

    // MARK: - Initialization

    init(
        githubAPI: GitHubAPI,
        credentialStorage: CredentialStorage
    ) {
        self.githubAPI = githubAPI
        self.credentialStorage = credentialStorage
    }

    // MARK: - Intent: Validate and Save Credentials

    /// Validates the provided Personal Access Token and base URL by making a test API call to GitHub.
    /// If validation succeeds, stores the credentials securely in Keychain.
    ///
    /// - Parameters:
    ///   - token: The GitHub Personal Access Token to validate
    ///   - baseURL: The GitHub API base URL (default: https://api.github.com, or custom for GitHub Enterprise)
    /// - Throws: APIError if validation fails, or CredentialStorageError if storage fails
    func validateAndSaveCredentials(token: String, baseURL: String = "https://api.github.com") async
    {
        isLoading = true
        error = nil

        do {
            // Create credentials
            let credentials = GitHubCredentials(token: token, baseURL: baseURL)

            // Validate by fetching user profile
            let user = try await githubAPI.fetchUser(credentials: credentials)

            // Store credentials if validation succeeds
            try await credentialStorage.store(credentials)

            // Update auth state
            authState = .authenticated(user: user, credentials: credentials)
            isLoading = false

        } catch let apiError as APIError {
            isLoading = false
            error = apiError
            authState = .unauthenticated
        } catch {
            isLoading = false
            self.error = .unknown(error)
            authState = .unauthenticated
        }
    }

    // MARK: - Intent: Check Existing Credentials

    /// Checks if credentials are already stored and validates them.
    /// Call this on app launch to restore authenticated session.
    func checkExistingCredentials() async {
        isLoading = true
        error = nil

        do {
            // Try to load stored credentials
            guard let credentials = try await credentialStorage.retrieve() else {
                // No stored credentials - stay unauthenticated
                isLoading = false
                authState = .unauthenticated
                return
            }

            // Validate stored credentials by fetching user
            let user = try await githubAPI.fetchUser(credentials: credentials)

            // Credentials are valid
            authState = .authenticated(user: user, credentials: credentials)
            isLoading = false

        } catch let apiError as APIError where apiError.isUnauthorized {
            // Token is invalid or expired - clear storage and show login
            try? await credentialStorage.delete()
            isLoading = false
            authState = .unauthenticated

        } catch {
            // Other errors - show error but stay unauthenticated
            isLoading = false
            self.error = error as? APIError ?? .unknown(error)
            authState = .unauthenticated
        }
    }

    // MARK: - Intent: Logout

    /// Logs out the current user by deleting stored credentials.
    /// Transitions back to unauthenticated state.
    func logout() async {
        isLoading = true
        error = nil

        do {
            try await credentialStorage.delete()
            authState = .unauthenticated
            isLoading = false
        } catch {
            isLoading = false
            self.error = .unknown(error)
        }
    }
}

// MARK: - Auth State

extension AuthenticationContainer {
    enum AuthState {
        case unauthenticated
        case authenticated(user: AuthenticatedUser, credentials: GitHubCredentials)

        var isAuthenticated: Bool {
            if case .authenticated = self {
                return true
            }
            return false
        }

        var user: AuthenticatedUser? {
            if case .authenticated(let user, _) = self {
                return user
            }
            return nil
        }

        var credentials: GitHubCredentials? {
            if case .authenticated(_, let credentials) = self {
                return credentials
            }
            return nil
        }
    }
}

// MARK: - APIError Extension

extension APIError {
    fileprivate var isUnauthorized: Bool {
        if case .unauthorized = self {
            return true
        }
        return false
    }
}
