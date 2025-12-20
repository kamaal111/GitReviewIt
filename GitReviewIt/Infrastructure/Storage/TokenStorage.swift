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
