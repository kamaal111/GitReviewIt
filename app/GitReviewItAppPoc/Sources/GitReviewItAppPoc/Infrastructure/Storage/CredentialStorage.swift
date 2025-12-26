import Foundation
import Security

/// Protocol for secure credential storage operations
protocol CredentialStorage: Sendable {
    /// Store credentials securely in the keychain
    /// - Parameter credentials: The credentials to store
    /// - Throws: CredentialStorageError if storage fails
    func store(_ credentials: GitHubCredentials) async throws

    /// Retrieve the stored credentials from the keychain
    /// - Returns: The stored credentials, or nil if no credentials exist
    /// - Throws: CredentialStorageError if retrieval fails
    func retrieve() async throws -> GitHubCredentials?

    /// Delete the stored credentials from the keychain
    /// - Throws: CredentialStorageError if deletion fails
    func delete() async throws
}

/// Errors that can occur during credential storage operations
enum CredentialStorageError: Error, Equatable {
    /// Failed to store the credentials in the keychain
    case storeFailed(status: OSStatus)

    /// Failed to retrieve the credentials from the keychain
    case retrieveFailed(status: OSStatus)

    /// Failed to delete the credentials from the keychain
    case deleteFailed(status: OSStatus)

    /// Credential data was corrupted or invalid
    case invalidData

    /// The keychain is not available or accessible
    case keychainUnavailable

    // MARK: - Equatable Conformance

    static func == (lhs: CredentialStorageError, rhs: CredentialStorageError) -> Bool {
        switch (lhs, rhs) {
        case (.storeFailed(let lhsStatus), .storeFailed(let rhsStatus)):
            return lhsStatus == rhsStatus
        case (.retrieveFailed(let lhsStatus), .retrieveFailed(let rhsStatus)):
            return lhsStatus == rhsStatus
        case (.deleteFailed(let lhsStatus), .deleteFailed(let rhsStatus)):
            return lhsStatus == rhsStatus
        case (.invalidData, .invalidData):
            return true
        case (.keychainUnavailable, .keychainUnavailable):
            return true
        default:
            return false
        }
    }
}

// MARK: - LocalizedError

extension CredentialStorageError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .storeFailed(let status):
            return "Failed to store credentials securely (error code: \(status))."
        case .retrieveFailed(let status):
            return "Failed to retrieve stored credentials (error code: \(status))."
        case .deleteFailed(let status):
            return "Failed to delete stored credentials (error code: \(status))."
        case .invalidData:
            return "Stored credential data is corrupted or invalid."
        case .keychainUnavailable:
            return "Secure storage is not available on this device."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .storeFailed, .retrieveFailed, .deleteFailed:
            return "Try signing out and signing in again."
        case .invalidData:
            return "Sign out and sign in again to refresh your credentials."
        case .keychainUnavailable:
            return "Check your system security settings and try again."
        }
    }
}

// MARK: - KeychainCredentialStorage

/// Production implementation of CredentialStorage using macOS Keychain
final class KeychainCredentialStorage: CredentialStorage {
    private let service: String
    private let account: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// Initialize with custom service and account identifiers
    /// - Parameters:
    ///   - service: Keychain service identifier (default: app bundle identifier)
    ///   - account: Keychain account identifier (default: "github-credentials")
    init(
        service: String = Bundle.main.bundleIdentifier ?? "com.gitreviewit.app",
        account: String = "github-credentials"
    ) {
        self.service = service
        self.account = account
    }

    /// Store credentials in the keychain
    func store(_ credentials: GitHubCredentials) async throws {
        guard let data = try? encoder.encode(credentials) else {
            throw CredentialStorageError.invalidData
        }

        // First try to delete any existing credentials
        try? await delete()

        // Create query for storing the credentials
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw CredentialStorageError.storeFailed(status: status)
        }
    }

    /// Retrieve the stored credentials from the keychain
    func retrieve() async throws -> GitHubCredentials? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw CredentialStorageError.retrieveFailed(status: status)
        }

        guard let data = result as? Data else {
            throw CredentialStorageError.invalidData
        }

        do {
            return try decoder.decode(GitHubCredentials.self, from: data)
        } catch {
            throw CredentialStorageError.invalidData
        }
    }

    /// Delete the stored credentials from the keychain
    func delete() async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)

        // Deleting a non-existent item is not an error
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw CredentialStorageError.deleteFailed(status: status)
        }
    }
}
