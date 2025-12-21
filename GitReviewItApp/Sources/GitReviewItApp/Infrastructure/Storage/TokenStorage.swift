import Foundation
import Security

/// Protocol for secure token storage operations
protocol TokenStorage: Sendable {
    /// Store a token securely in the keychain
    /// - Parameter token: The token to store
    /// - Throws: TokenStorageError if storage fails
    func store(_ token: String) async throws
    
    /// Retrieve the stored token from the keychain
    /// - Returns: The stored token, or nil if no token exists
    /// - Throws: TokenStorageError if retrieval fails
    func retrieve() async throws -> String?
    
    /// Delete the stored token from the keychain
    /// - Throws: TokenStorageError if deletion fails
    func delete() async throws
}

/// Errors that can occur during token storage operations
enum TokenStorageError: Error, Equatable {
    /// Failed to store the token in the keychain
    case storeFailed(status: OSStatus)
    
    /// Failed to retrieve the token from the keychain
    case retrieveFailed(status: OSStatus)
    
    /// Failed to delete the token from the keychain
    case deleteFailed(status: OSStatus)
    
    /// Token data was corrupted or invalid
    case invalidData
    
    /// The keychain is not available or accessible
    case keychainUnavailable
    
    // MARK: - Equatable Conformance
    
    static func == (lhs: TokenStorageError, rhs: TokenStorageError) -> Bool {
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

extension TokenStorageError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .storeFailed(let status):
            return "Failed to store token securely (error code: \(status))."
        case .retrieveFailed(let status):
            return "Failed to retrieve stored token (error code: \(status))."
        case .deleteFailed(let status):
            return "Failed to delete stored token (error code: \(status))."
        case .invalidData:
            return "Stored token data is corrupted or invalid."
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

// MARK: - KeychainTokenStorage

/// Production implementation of TokenStorage using macOS Keychain
final class KeychainTokenStorage: TokenStorage {
    private let service: String
    private let account: String
    
    /// Initialize with custom service and account identifiers
    /// - Parameters:
    ///   - service: Keychain service identifier (default: app bundle identifier)
    ///   - account: Keychain account identifier (default: "github-token")
    init(
        service: String = Bundle.main.bundleIdentifier ?? "com.gitreviewit.app",
        account: String = "github-token"
    ) {
        self.service = service
        self.account = account
    }
    
    /// Store a token in the keychain
    func store(_ token: String) async throws {
        guard let tokenData = token.data(using: .utf8) else {
            throw TokenStorageError.invalidData
        }
        
        // First try to delete any existing token
        try? await delete()
        
        // Create query for storing the token
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: tokenData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw TokenStorageError.storeFailed(status: status)
        }
    }
    
    /// Retrieve the stored token from the keychain
    func retrieve() async throws -> String? {
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
            throw TokenStorageError.retrieveFailed(status: status)
        }
        
        guard let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw TokenStorageError.invalidData
        }
        
        return token
    }
    
    /// Delete the stored token from the keychain
    func delete() async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        // Deleting a non-existent item is not an error
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw TokenStorageError.deleteFailed(status: status)
        }
    }
}
