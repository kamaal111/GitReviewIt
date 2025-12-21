import Foundation
import Testing

@testable import GitReviewItApp

/// Integration tests for credential persistence and session management.
/// Verifies that valid credentials are restored on launch and invalid ones are cleared.
@MainActor
struct CredentialPersistenceTests {

    // MARK: - Test Helpers

    private func makeContainer(
        mockAPI: MockGitHubAPI = MockGitHubAPI(),
        mockStorage: MockCredentialStorage = MockCredentialStorage()
    ) -> (AuthenticationContainer, MockGitHubAPI, MockCredentialStorage) {
        let container = AuthenticationContainer(
            githubAPI: mockAPI,
            credentialStorage: mockStorage
        )
        return (container, mockAPI, mockStorage)
    }

    // MARK: - T071: App Launch with Valid Credentials

    @Test
    func `App launch with valid stored credentials restores authenticated session`() async throws {
        // Arrange
        let (container, mockAPI, mockStorage) = makeContainer()

        // Pre-condition: Valid credentials exist in storage
        let storedToken = "ghp_valid_token"
        let storedBaseURL = "https://api.github.com"
        let credentials = GitHubCredentials(token: storedToken, baseURL: storedBaseURL)
        try await mockStorage.store(credentials)

        // Mock API returns valid user for these credentials
        let expectedUser = AuthenticatedUser(
            login: "returning_user",
            name: "Returning User",
            avatarURL: nil
        )
        mockAPI.userToReturn = expectedUser

        // Act - Simulate app launch
        await container.checkExistingCredentials()

        // Assert
        #expect(container.authState.isAuthenticated, "Should be authenticated")
        #expect(container.authState.user?.login == "returning_user", "User should be restored")
        #expect(
            container.authState.credentials?.token == storedToken, "Credentials should be restored")
    }

    // MARK: - T072: App Launch with Expired Credentials

    @Test
    func `App launch with expired credentials clears storage and requires login`() async throws {
        // Arrange
        let (container, mockAPI, mockStorage) = makeContainer()

        // Pre-condition: Expired credentials exist in storage
        let expiredToken = "ghp_expired_token"
        let credentials = GitHubCredentials(token: expiredToken, baseURL: "https://api.github.com")
        try await mockStorage.store(credentials)

        // Mock API returns 401 Unauthorized
        mockAPI.fetchUserErrorToThrow = APIError.unauthorized

        // Act - Simulate app launch
        await container.checkExistingCredentials()

        // Assert
        #expect(!container.authState.isAuthenticated, "Should NOT be authenticated")
        #expect(
            container.authState == .unauthenticated, "Should transition to unauthenticated state")

        // Verify credentials were removed from storage
        let stored = try await mockStorage.retrieve()
        #expect(stored == nil, "Expired credentials should be deleted")
    }

    // MARK: - T073: App Launch with No Credentials

    @Test
    func `App launch with no stored credentials shows login screen`() async throws {
        // Arrange
        let (container, _, mockStorage) = makeContainer()

        // Pre-condition: Storage is empty
        try await mockStorage.delete()

        // Act - Simulate app launch
        await container.checkExistingCredentials()

        // Assert
        #expect(!container.authState.isAuthenticated, "Should not be authenticated")
        #expect(container.authState == .unauthenticated, "Should be in unauthenticated state")
    }
}
