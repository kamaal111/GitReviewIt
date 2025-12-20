import Foundation

/// Protocol for HTTP networking operations
protocol HTTPClient: Sendable {
    /// Perform an HTTP request
    /// - Parameters:
    ///   - request: The URL request to execute
    /// - Returns: Response data and HTTP response
    /// - Throws: HTTPError if the request fails
    func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

/// Errors that can occur during HTTP operations
enum HTTPError: Error, Equatable {
    /// Network connection failed
    case connectionFailed(Error)
    
    /// Request timed out
    case timeout
    
    /// Invalid URL
    case invalidURL
    
    /// Response is not an HTTP response
    case invalidResponse
    
    /// HTTP error with status code
    case httpError(statusCode: Int, data: Data?)
    
    /// No data received from server
    case noData
    
    /// SSL/TLS error
    case sslError(Error)
    
    /// DNS lookup failed
    case dnsError
    
    /// Request was cancelled
    case cancelled
    
    /// Unknown network error
    case unknown(Error)
    
    // MARK: - Computed Properties
    
    /// Returns true if this error represents a client error (4xx)
    var isClientError: Bool {
        if case .httpError(let statusCode, _) = self {
            return (400..<500).contains(statusCode)
        }
        return false
    }
    
    /// Returns true if this error represents a server error (5xx)
    var isServerError: Bool {
        if case .httpError(let statusCode, _) = self {
            return (500..<600).contains(statusCode)
        }
        return false
    }
    
    /// Returns true if this error is recoverable by retrying
    var isRetryable: Bool {
        switch self {
        case .timeout, .connectionFailed, .dnsError:
            return true
        case .httpError(let statusCode, _):
            // Retry on server errors and specific client errors
            return (500..<600).contains(statusCode) || statusCode == 429
        default:
            return false
        }
    }
    
    // MARK: - Equatable Conformance
    
    static func == (lhs: HTTPError, rhs: HTTPError) -> Bool {
        switch (lhs, rhs) {
        case (.connectionFailed(let lhsError), .connectionFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.timeout, .timeout):
            return true
        case (.invalidURL, .invalidURL):
            return true
        case (.invalidResponse, .invalidResponse):
            return true
        case (.httpError(let lhsCode, let lhsData), .httpError(let rhsCode, let rhsData)):
            return lhsCode == rhsCode && lhsData == rhsData
        case (.noData, .noData):
            return true
        case (.sslError(let lhsError), .sslError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.dnsError, .dnsError):
            return true
        case (.cancelled, .cancelled):
            return true
        case (.unknown(let lhsError), .unknown(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - LocalizedError

extension HTTPError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .connectionFailed(let error):
            return "Connection failed: \(error.localizedDescription)"
        case .timeout:
            return "Request timed out."
        case .invalidURL:
            return "Invalid URL."
        case .invalidResponse:
            return "Received invalid response from server."
        case .httpError(let statusCode, _):
            return "HTTP error \(statusCode): \(HTTPURLResponse.localizedString(forStatusCode: statusCode))"
        case .noData:
            return "No data received from server."
        case .sslError(let error):
            return "Secure connection failed: \(error.localizedDescription)"
        case .dnsError:
            return "Could not resolve server address."
        case .cancelled:
            return "Request was cancelled."
        case .unknown(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .connectionFailed, .timeout, .dnsError:
            return "Check your internet connection and try again."
        case .httpError(let statusCode, _) where (500..<600).contains(statusCode):
            return "The server is experiencing issues. Try again in a few moments."
        case .httpError(429, _):
            return "Too many requests. Wait a moment before trying again."
        case .sslError:
            return "Check your device's date and time settings."
        case .cancelled:
            return nil
        default:
            return "Please try again."
        }
    }
}
