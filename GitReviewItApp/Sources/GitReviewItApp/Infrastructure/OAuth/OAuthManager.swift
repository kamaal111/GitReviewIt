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

// MARK: - ASWebAuthenticationSessionOAuthManager

/// Production implementation of OAuthManager using ASWebAuthenticationSession
final class ASWebAuthenticationSessionOAuthManager: NSObject, OAuthManager {
    private var currentSession: ASWebAuthenticationSession?
    private var continuation: CheckedContinuation<String, Error>?
    
    /// Start OAuth authorization flow
    func authorize() async throws -> String {
        // Note: This implementation requires GitHub OAuth configuration
        // The actual authorizationURL should be constructed with:
        // - client_id from GitHubOAuthConfig
        // - redirect_uri (e.g., "gitreviewit://oauth-callback")
        // - scope (e.g., "repo,user")
        // - state (random string for CSRF protection)
        
        throw OAuthError.authorizationFailed(reason: "authorize() requires authorizationURL parameter - use a higher-level component")
    }
    
    /// Start OAuth authorization flow with explicit parameters
    /// - Parameters:
    ///   - authorizationURL: Complete GitHub OAuth URL with all query parameters
    ///   - callbackURLScheme: Custom URL scheme for callback (e.g., "gitreviewit")
    /// - Returns: Authorization code from the callback
    func authorize(authorizationURL: URL, callbackURLScheme: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            let session = ASWebAuthenticationSession(
                url: authorizationURL,
                callbackURLScheme: callbackURLScheme
            ) { [weak self] callbackURL, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.handleAuthenticationError(error)
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    self.continuation?.resume(throwing: OAuthError.invalidCallbackURL)
                    self.continuation = nil
                    return
                }
                
                do {
                    let code = try self.extractAuthorizationCode(from: callbackURL)
                    self.continuation?.resume(returning: code)
                    self.continuation = nil
                } catch {
                    self.continuation?.resume(throwing: error)
                    self.continuation = nil
                }
            }
            
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            
            if session.start() {
                self.currentSession = session
            } else {
                continuation.resume(throwing: OAuthError.presentationFailed)
                self.continuation = nil
            }
        }
    }
    
    /// Exchange authorization code for access token
    func exchangeCodeForToken(code: String) async throws -> String {
        // Note: This should be handled by GitHubAPIClient
        // OAuthManager's responsibility ends at obtaining the authorization code
        throw OAuthError.tokenExchangeFailed(reason: "Token exchange should be handled by GitHubAPIClient")
    }
    
    // MARK: - Private Helpers
    
    private func handleAuthenticationError(_ error: Error) {
        if let asError = error as? ASWebAuthenticationSessionError {
            switch asError.code {
            case .canceledLogin:
                continuation?.resume(throwing: OAuthError.userCancelled)
            case .presentationContextNotProvided, .presentationContextInvalid:
                continuation?.resume(throwing: OAuthError.presentationFailed)
            @unknown default:
                continuation?.resume(throwing: OAuthError.unknown(error))
            }
        } else {
            continuation?.resume(throwing: OAuthError.unknown(error))
        }
        continuation = nil
    }
    
    private func extractAuthorizationCode(from url: URL) throws -> String {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            throw OAuthError.invalidCallbackURL
        }
        
        // Check for error parameter from GitHub
        if let error = queryItems.first(where: { $0.name == "error" })?.value {
            let description = queryItems.first(where: { $0.name == "error_description" })?.value
            throw OAuthError.authorizationFailed(reason: description ?? error)
        }
        
        // Extract authorization code
        guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
            throw OAuthError.invalidCallbackURL
        }
        
        return code
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension ASWebAuthenticationSessionOAuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Return the key window or first window as presentation anchor
        #if os(macOS)
        return NSApplication.shared.windows.first { $0.isKeyWindow } ?? NSApplication.shared.windows.first ?? ASPresentationAnchor()
        #else
        return UIApplication.shared.windows.first { $0.isKeyWindow } ?? UIApplication.shared.windows.first ?? ASPresentationAnchor()
        #endif
    }
}
