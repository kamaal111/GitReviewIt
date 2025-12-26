import Testing

@testable import GitReviewItAppPoc

@MainActor
struct LogoutTests {

    @Test
    func `Logout clears credentials and resets state`() async throws {
        // Given
        let (authContainer, storage, _) = try await createAuthenticatedContainer()

        // Verify we are authenticated and storage has token
        #expect(authContainer.authState.isAuthenticated)
        let token = try await storage.retrieve()
        #expect(token != nil)

        // When
        await authContainer.logout()

        // Then
        // 1. State should be unauthenticated
        #expect(authContainer.authState == .unauthenticated)
        #expect(!authContainer.authState.isAuthenticated)

        // 2. Credentials should be removed from storage
        let deletedToken = try await storage.retrieve()
        #expect(deletedToken == nil)

        // 3. User data should be cleared from state
        #expect(authContainer.authState.user == nil)
        #expect(authContainer.authState.credentials == nil)
    }

    // Helper to setup authenticated state
    private func createAuthenticatedContainer() async throws -> (
        AuthenticationContainer, MockCredentialStorage, MockGitHubAPI
    ) {
        let storage = MockCredentialStorage()
        let api = MockGitHubAPI()
        let container = AuthenticationContainer(githubAPI: api, credentialStorage: storage)

        // Setup initial valid token
        let token = "valid_token"
        let baseURL = "https://api.github.com"

        // Mock successful user fetch
        api.userToReturn = AuthenticatedUser(login: "testuser")

        // Authenticate
        await container.validateAndSaveCredentials(token: token, baseURL: baseURL)

        return (container, storage, api)
    }
}
