import Foundation

/// Errors that can occur when interacting with the GitHub API
enum APIError: Error, Equatable {
    /// The HTTP request failed with a network-level error
    case networkError(Error)

    /// The device is not connected to the internet
    case networkUnreachable

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
        case (.networkUnreachable, .networkUnreachable):
            return true
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
            return
                """
                We couldn't connect to GitHub. Please check your internet connection and ensure the API URL is correct.

                Details: \(error.localizedDescription)
                """
        case .networkUnreachable:
            return "You seem to be offline. Please check your internet connection."
        case .httpError(let statusCode, let message):
            if let message = message {
                return "GitHub returned an error (\(statusCode)): \(message)"
            }
            return "GitHub returned an error (Status: \(statusCode))"
        case .unauthorized:
            return "Your session has expired or your token is invalid. Please sign in again."
        case .rateLimitExceeded(let resetAt):
            if let resetAt = resetAt {
                let formatter = DateFormatter()
                formatter.timeStyle = .medium
                formatter.dateStyle = .none
                return
                    """
                    You've reached the GitHub API rate limit. \
                    Your quota will reset at \(formatter.string(from: resetAt)).
                    """
            }
            return
                "You've reached the GitHub API rate limit. Please wait a few minutes before trying again."
        case .invalidResponse:
            return "We received an invalid response from GitHub. Please try again later."
        case .decodingError:
            return
                "We encountered an issue processing the data from GitHub. Please try again later."
        case .notFound:
            return
                "The requested resource could not be found. Please check your permissions and try again."
        case .serverError:
            return "GitHub is experiencing technical difficulties. Please try again later."
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkError, .networkUnreachable:
            return "Check your Wi-Fi or cellular data connection."
        case .unauthorized:
            return "Go to Settings to update your Personal Access Token."
        case .rateLimitExceeded:
            return "Wait until the reset time or check your token permissions."
        case .serverError:
            return "Check GitHub Status (githubstatus.com) for updates."
        default:
            return nil
        }
    }
}
