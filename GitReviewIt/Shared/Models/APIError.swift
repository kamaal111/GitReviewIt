import Foundation

/// Errors that can occur when interacting with the GitHub API
enum APIError: Error, Equatable {
    /// The HTTP request failed with a network-level error
    case networkError(Error)
    
    /// The server returned an error status code
    case httpError(statusCode: Int, message: String?)
    
    /// Authentication failed - token is invalid or expired
    case unauthorized
    
    /// Rate limit exceeded - includes reset time if available
    case rateLimitExceeded(resetAt: Date?)
    
    /// The response could not be decoded
    case invalidResponse
    
    /// The response JSON could not be parsed into expected model
    case decodingError(Error)
    
    /// The endpoint or resource was not found
    case notFound
    
    /// Server error (5xx status codes)
    case serverError(statusCode: Int)
    
    /// Unexpected error that doesn't fit other categories
    case unknown(Error)
    
    // MARK: - Equatable Conformance
    
    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.networkError(let lhsError), .networkError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.httpError(let lhsCode, let lhsMsg), .httpError(let rhsCode, let rhsMsg)):
            return lhsCode == rhsCode && lhsMsg == rhsMsg
        case (.unauthorized, .unauthorized):
            return true
        case (.rateLimitExceeded(let lhsReset), .rateLimitExceeded(let rhsReset)):
            return lhsReset == rhsReset
        case (.invalidResponse, .invalidResponse):
            return true
        case (.decodingError(let lhsError), .decodingError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.notFound, .notFound):
            return true
        case (.serverError(let lhsCode), .serverError(let rhsCode)):
            return lhsCode == rhsCode
        case (.unknown(let lhsError), .unknown(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - LocalizedError

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network connection failed: \(error.localizedDescription)"
        case .httpError(let statusCode, let message):
            if let message = message {
                return "Server error (\(statusCode)): \(message)"
            }
            return "Server returned error code \(statusCode)"
        case .unauthorized:
            return "Authentication failed. Please log in again."
        case .rateLimitExceeded(let resetAt):
            if let resetAt = resetAt {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return "Rate limit exceeded. Try again after \(formatter.string(from: resetAt))."
            }
            return "Rate limit exceeded. Please try again later."
        case .invalidResponse:
            return "Received invalid response from server."
        case .decodingError:
            return "Failed to parse server response."
        case .notFound:
            return "The requested resource was not found."
        case .serverError(let statusCode):
            return "Server error (\(statusCode)). Please try again later."
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Check your internet connection and try again."
        case .unauthorized:
            return "Sign out and sign in again with your GitHub account."
        case .rateLimitExceeded:
            return "GitHub API rate limit reached. Wait a few minutes before trying again."
        case .serverError:
            return "GitHub's servers are experiencing issues. Try again in a few moments."
        default:
            return nil
        }
    }
}
