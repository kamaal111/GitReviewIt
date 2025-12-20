import Foundation
import AuthenticationServices

/// Protocol for OAuth authentication operations
protocol OAuthManager: Sendable {
    /// Start the OAuth authorization flow
    /// - Returns: Authorization code from successful OAuth flow
    /// - Throws: OAuthError if the flow fails or is cancelled
    func authorize() async throws -> String
    
    /// Exchange authorization code for access token
    /// - Parameter code: Authorization code from OAuth flow
    /// - Returns: Access token string
    /// - Throws: OAuthError if token exchange fails
    func exchangeCodeForToken(code: String) async throws -> String
}

/// Errors that can occur during OAuth authentication
enum OAuthError: Error, Equatable {
    /// User cancelled the OAuth flow
    case userCancelled
    
    /// OAuth flow failed to complete
    case authorizationFailed(reason: String?)
    
    /// Failed to exchange authorization code for token
    case tokenExchangeFailed(reason: String?)
    
    /// OAuth callback URL is invalid or missing required parameters
    case invalidCallbackURL
    
    /// OAuth state parameter mismatch (CSRF protection)
    case stateMismatch
    
    /// The authentication session presentation failed
    case presentationFailed
    
    /// Network error during OAuth token exchange
    case networkError(Error)
    
    /// Unexpected error during OAuth flow
    case unknown(Error)
    
    // MARK: - Equatable Conformance
    
    static func == (lhs: OAuthError, rhs: OAuthError) -> Bool {
        switch (lhs, rhs) {
        case (.userCancelled, .userCancelled):
            return true
        case (.authorizationFailed(let lhsReason), .authorizationFailed(let rhsReason)):
            return lhsReason == rhsReason
        case (.tokenExchangeFailed(let lhsReason), .tokenExchangeFailed(let rhsReason)):
            return lhsReason == rhsReason
        case (.invalidCallbackURL, .invalidCallbackURL):
            return true
        case (.stateMismatch, .stateMismatch):
            return true
        case (.presentationFailed, .presentationFailed):
            return true
        case (.networkError(let lhsError), .networkError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.unknown(let lhsError), .unknown(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - LocalizedError

extension OAuthError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "Sign in was cancelled."
        case .authorizationFailed(let reason):
            if let reason = reason {
                return "GitHub authorization failed: \(reason)"
            }
            return "GitHub authorization failed."
        case .tokenExchangeFailed(let reason):
            if let reason = reason {
                return "Failed to complete sign in: \(reason)"
            }
            return "Failed to complete sign in."
        case .invalidCallbackURL:
            return "Invalid response from GitHub authorization."
        case .stateMismatch:
            return "Security verification failed during sign in."
        case .presentationFailed:
            return "Could not display GitHub sign in page."
        case .networkError(let error):
            return "Network error during sign in: \(error.localizedDescription)"
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .userCancelled:
            return "Try signing in again when ready."
        case .authorizationFailed, .tokenExchangeFailed:
            return "Check your internet connection and try again."
        case .invalidCallbackURL, .stateMismatch:
            return "Try signing in again. If the problem persists, contact support."
        case .presentationFailed:
            return "Make sure Safari is working properly and try again."
        case .networkError:
            return "Check your internet connection and try again."
        case .unknown:
            return "Please try again."
        }
    }
}
