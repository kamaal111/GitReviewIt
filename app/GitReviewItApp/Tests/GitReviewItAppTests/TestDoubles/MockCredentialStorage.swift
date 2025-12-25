import Foundation

@testable import GitReviewItApp

/// Mock implementation of CredentialStorage for testing
/// Stores credentials in-memory without using the actual Keychain
@MainActor
final class MockCredentialStorage: CredentialStorage {
    // MARK: - Configuration

    /// Stored credentials (in-memory only)
    private(set) var storedCredentials: GitHubCredentials?

    /// Error to throw on store operations
    var storeErrorToThrow: CredentialStorageError?

    /// Error to throw on retrieve operations
    var retrieveErrorToThrow: CredentialStorageError?

    /// Error to throw on delete operations
    var deleteErrorToThrow: CredentialStorageError?

    // MARK: - Initializer

    init(mockCredentials: GitHubCredentials? = nil) {
        self.storedCredentials = mockCredentials
    }

    // MARK: - Captured Data

    /// Count of how many times store was called
    private(set) var storeCallCount = 0

    /// Count of how many times retrieve was called
    private(set) var retrieveCallCount = 0

    /// Count of how many times delete was called
    private(set) var deleteCallCount = 0

    // MARK: - CredentialStorage Protocol

    func store(_ credentials: GitHubCredentials) async throws {
        storeCallCount += 1

        if let error = storeErrorToThrow {
            throw error
        }

        storedCredentials = credentials
    }

    func retrieve() async throws -> GitHubCredentials? {
        retrieveCallCount += 1

        if let error = retrieveErrorToThrow {
            throw error
        }

        return storedCredentials
    }

    func delete() async throws {
        deleteCallCount += 1

        if let error = deleteErrorToThrow {
            throw error
        }

        storedCredentials = nil
    }

    // MARK: - Test Helpers

    /// Reset all captured data and configuration
    func reset() {
        storedCredentials = nil
        storeErrorToThrow = nil
        retrieveErrorToThrow = nil
        deleteErrorToThrow = nil
        storeCallCount = 0
        retrieveCallCount = 0
        deleteCallCount = 0
    }

    /// Pre-populate storage with credentials (simulating existing stored credentials)
    func preloadCredentials(_ credentials: GitHubCredentials) {
        storedCredentials = credentials
    }

    /// Check if credentials are currently stored
    var hasStoredCredentials: Bool {
        storedCredentials != nil
    }
}
