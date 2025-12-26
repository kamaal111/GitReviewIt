import Foundation
import Testing

@testable import GitReviewItAppPoc

/// Integration tests for the complete authentication flow.
/// Tests Personal Access Token validation, credential storage, and GitHub Enterprise support.
@MainActor
struct AuthenticationFlowTests {

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

    private func loadFixture<T: Decodable>(name: String) throws -> T {
        let bundle = Bundle.module
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw NSError(
                domain: "TestError", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Fixture \(name).json not found"])
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - T041: Test Successful PAT Validation and Credential Storage

    @Test
    func `Successful PAT validation stores credentials and transitions to authenticated state`()
    async throws {
        // Arrange
        let (container, mockAPI, mockStorage) = makeContainer()

        // Configure mock to succeed with valid user response
        let expectedUser = AuthenticatedUser(
            login: "octocat",
            name: "The Octocat",
            avatarURL: URL(string: "https://github.com/images/error/octocat_happy.gif")
        )
        mockAPI.userToReturn = expectedUser

        let testToken = "ghp_test123456789"
        let testBaseURL = "https://api.github.com"

        // Act
        await container.validateAndSaveCredentials(token: testToken, baseURL: testBaseURL)

        // Assert
        #expect(container.authState.isAuthenticated, "Container should be in authenticated state")
        #expect(container.authState.user?.login == "octocat", "User login should match fixture")
        #expect(container.error == nil, "Error should be nil after successful authentication")
        #expect(!container.isLoading, "Loading should be false after completion")

        // Verify credentials were stored
        let storedCredentials = try await mockStorage.retrieve()
        #expect(storedCredentials?.token == testToken, "Stored token should match input")
        #expect(storedCredentials?.baseURL == testBaseURL, "Stored base URL should match input")
    }

    @Test
    func `Successful PAT validation with default baseURL uses GitHub cloud API`() async throws {
        // Arrange
        let (container, mockAPI, mockStorage) = makeContainer()

        let expectedUser = AuthenticatedUser(login: "testuser", name: "Test User", avatarURL: nil)
        mockAPI.userToReturn = expectedUser

        let testToken = "ghp_cloudtoken"

        // Act - Don't specify baseURL, should default to https://api.github.com
        await container.validateAndSaveCredentials(token: testToken)

        // Assert
        #expect(container.authState.isAuthenticated, "Container should be authenticated")

        let storedCredentials = try await mockStorage.retrieve()
        #expect(
            storedCredentials?.baseURL == "https://api.github.com",
            "Default base URL should be GitHub cloud")
    }

    // MARK: - T042: Test Invalid PAT Handling (401 Response)

    @Test
    func `Invalid PAT returns 401 and transitions to unauthenticated state with error`()
    async throws {
        // Arrange
        let (container, mockAPI, _) = makeContainer()

        // Configure mock to return unauthorized error
        mockAPI.fetchUserErrorToThrow = APIError.unauthorized

        let testToken = "ghp_invalid_token"
        let testBaseURL = "https://api.github.com"

        // Act
        await container.validateAndSaveCredentials(token: testToken, baseURL: testBaseURL)

        // Assert
        #expect(!container.authState.isAuthenticated, "Container should remain unauthenticated")
        #expect(container.error != nil, "Error should be set")
        #expect(container.error == .unauthorized, "Expected unauthorized error")
        #expect(!container.isLoading, "Loading should be false after completion")
    }

    @Test
    func `Invalid PAT does not store credentials in keychain`() async throws {
        // Arrange
        let (container, mockAPI, mockStorage) = makeContainer()

        mockAPI.fetchUserErrorToThrow = APIError.unauthorized

        let testToken = "ghp_bad_token"

        // Act
        await container.validateAndSaveCredentials(token: testToken)

        // Assert - No credentials should be stored
        let storedCredentials = try await mockStorage.retrieve()
        #expect(storedCredentials == nil, "No credentials should be stored after failed validation")
    }

    @Test
    func `Network error during validation shows appropriate error`() async throws {
        // Arrange
        let (container, mockAPI, _) = makeContainer()

        let networkError = URLError(.notConnectedToInternet)
        mockAPI.fetchUserErrorToThrow = APIError.networkError(networkError)

        let testToken = "ghp_token"

        // Act
        await container.validateAndSaveCredentials(token: testToken)

        // Assert
        #expect(!container.authState.isAuthenticated, "Container should remain unauthenticated")
        #expect(container.error != nil, "Network error should be set")

        let expectedError = APIError.networkError(networkError)
        #expect(container.error == expectedError, "Expected network error")
    }

    // MARK: - T043: Test GitHub Enterprise Custom baseURL Authentication

    @Test
    func `GitHub Enterprise authentication with custom baseURL succeeds`() async throws {
        // Arrange
        let (container, mockAPI, mockStorage) = makeContainer()

        let expectedUser = AuthenticatedUser(
            login: "enterprise-user",
            name: "Enterprise User",
            avatarURL: URL(string: "https://ghe.company.com/avatars/user.png")
        )
        mockAPI.userToReturn = expectedUser

        let testToken = "ghp_enterprise123"
        let gheBaseURL = "https://github.company.com/api/v3"

        // Act
        await container.validateAndSaveCredentials(token: testToken, baseURL: gheBaseURL)

        // Assert
        #expect(container.authState.isAuthenticated, "GHE authentication should succeed")
        #expect(container.authState.user?.login == "enterprise-user", "User should match GHE user")

        // Verify GHE base URL is stored
        let storedCredentials = try await mockStorage.retrieve()
        #expect(storedCredentials?.baseURL == gheBaseURL, "Stored base URL should be GHE URL")
        #expect(storedCredentials?.token == testToken, "Token should be stored correctly")
    }

    @Test
    func `Multiple GitHub Enterprise instances with different baseURLs work independently`()
    async throws {
        // Arrange
        let (container1, mockAPI1, mockStorage1) = makeContainer()
        let (container2, mockAPI2, mockStorage2) = makeContainer()

        let user1 = AuthenticatedUser(login: "user-company-a", name: nil, avatarURL: nil)
        let user2 = AuthenticatedUser(login: "user-company-b", name: nil, avatarURL: nil)

        mockAPI1.userToReturn = user1
        mockAPI2.userToReturn = user2

        let token1 = "ghp_companyA"
        let baseURL1 = "https://github.companyA.com/api/v3"

        let token2 = "ghp_companyB"
        let baseURL2 = "https://github.companyB.com/api/v3"

        // Act
        await container1.validateAndSaveCredentials(token: token1, baseURL: baseURL1)
        await container2.validateAndSaveCredentials(token: token2, baseURL: baseURL2)

        // Assert
        #expect(container1.authState.user?.login == "user-company-a")
        #expect(container2.authState.user?.login == "user-company-b")

        let creds1 = try await mockStorage1.retrieve()
        let creds2 = try await mockStorage2.retrieve()

        #expect(creds1?.baseURL == baseURL1, "First instance should use Company A URL")
        #expect(creds2?.baseURL == baseURL2, "Second instance should use Company B URL")
    }

    // MARK: - Additional Flow Tests

    @Test
    func `Logout clears stored credentials and transitions to unauthenticated`() async throws {
        // Arrange
        let (container, mockAPI, mockStorage) = makeContainer()

        // First authenticate
        let user = AuthenticatedUser(login: "testuser", name: nil, avatarURL: nil)
        mockAPI.userToReturn = user
        await container.validateAndSaveCredentials(token: "ghp_test")

        #expect(container.authState.isAuthenticated, "Should be authenticated before logout")

        // Act
        await container.logout()

        // Assert
        #expect(!container.authState.isAuthenticated, "Should be unauthenticated after logout")

        let storedCredentials = try await mockStorage.retrieve()
        #expect(storedCredentials == nil, "Credentials should be cleared from storage")
    }

    @Test
    func `Check existing credentials with valid stored token succeeds`() async throws {
        // Arrange
        let (container, mockAPI, mockStorage) = makeContainer()

        // Pre-store valid credentials
        let credentials = GitHubCredentials(token: "ghp_stored", baseURL: "https://api.github.com")
        try await mockStorage.store(credentials)

        let expectedUser = AuthenticatedUser(login: "returning-user", name: nil, avatarURL: nil)
        mockAPI.userToReturn = expectedUser

        // Act
        await container.checkExistingCredentials()

        // Assert
        #expect(container.authState.isAuthenticated, "Should authenticate with stored credentials")
        #expect(container.authState.user?.login == "returning-user")
    }

    @Test
    func `Check existing credentials with no stored token stays unauthenticated`() async throws {
        // Arrange
        let (container, _, _) = makeContainer()

        // Act - No credentials stored
        await container.checkExistingCredentials()

        // Assert
        #expect(
            !container.authState.isAuthenticated,
            "Should remain unauthenticated with no stored credentials")
        #expect(container.error == nil, "No error should be set when no credentials exist")
    }

    @Test
    func `Check existing credentials with expired token clears storage and stays unauthenticated`()
    async throws {
        // Arrange
        let (container, mockAPI, mockStorage) = makeContainer()

        // Pre-store credentials (simulating expired token)
        let credentials = GitHubCredentials(token: "ghp_expired", baseURL: "https://api.github.com")
        try await mockStorage.store(credentials)

        // Mock API returns 401 for expired token
        mockAPI.fetchUserErrorToThrow = APIError.unauthorized

        // Act
        await container.checkExistingCredentials()

        // Assert
        #expect(!container.authState.isAuthenticated, "Should not authenticate with expired token")

        let storedCredentials = try await mockStorage.retrieve()
        #expect(storedCredentials == nil, "Expired credentials should be cleared from storage")
    }
}
