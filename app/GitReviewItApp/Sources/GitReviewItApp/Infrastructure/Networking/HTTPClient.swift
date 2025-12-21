import Foundation
import OSLog

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

// MARK: - URLSessionHTTPClient

/// Production implementation of HTTPClient using URLSession
final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    private let logger = Logger(subsystem: "com.gitreviewit.app", category: "HTTPClient")

    /// Initialize with a custom URLSession (default creates standard configuration)
    /// - Parameter session: URLSession to use for requests
    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Performs an HTTP request using URLSession
    /// - Parameter request: The URLRequest to execute
    /// - Returns: Response data and HTTPURLResponse
    /// - Throws: HTTPError for various failure scenarios
    func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let startTime = Date()
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "unknown"

        // Log request details (excluding sensitive headers)
        var logHeaders: [String: String] = [:]
        if let headers = request.allHTTPHeaderFields {
            for (key, value) in headers {
                // Don't log authorization header for security
                if key.lowercased() != "authorization" {
                    logHeaders[key] = value
                } else {
                    logHeaders[key] = "[REDACTED]"
                }
            }
        }

        logger.info("HTTP Request: \(method) \(url, privacy: .public)")
        if !logHeaders.isEmpty {
            logger.debug("Request headers: \(String(describing: logHeaders), privacy: .public)")
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid response type received")
                throw HTTPError.invalidResponse
            }

            let duration = Date().timeIntervalSince(startTime)
            let statusCode = httpResponse.statusCode
            let dataSize = data.count

            logger.info(
                """
                HTTP Response: \(method) \(url, privacy: .public) - \
                \(statusCode) (\(String(format: "%.3f", duration))s, \(dataSize) bytes)
                """
            )

            return (data, httpResponse)
        } catch let error as HTTPError {
            let duration = Date().timeIntervalSince(startTime)
            logger.error(
                """
                HTTP Request failed: \(method) \(url, privacy: .public) - \
                \(error.localizedDescription) (\(String(format: "%.3f", duration))s)
                """
            )
            throw error
        } catch let urlError as URLError {
            let duration = Date().timeIntervalSince(startTime)
            let mappedError = mapURLError(urlError)
            logger.error(
                """
                HTTP Request failed: \(method) \(url, privacy: .public) - \
                \(mappedError.localizedDescription) (\(String(format: "%.3f", duration))s)
                """
            )
            throw mappedError
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error(
                """
                HTTP Request failed: \(method) \(url, privacy: .public) - Unknown error: \
                \(error.localizedDescription) (\(String(format: "%.3f", duration))s)
                """
            )
            throw HTTPError.unknown(error)
        }
    }

    /// Maps URLError cases to HTTPError cases
    private func mapURLError(_ error: URLError) -> HTTPError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            return .connectionFailed(error)
        case .timedOut:
            return .timeout
        case .badURL, .unsupportedURL:
            return .invalidURL
        case .secureConnectionFailed, .serverCertificateHasBadDate,
            .serverCertificateUntrusted, .serverCertificateHasUnknownRoot,
            .serverCertificateNotYetValid, .clientCertificateRejected,
            .clientCertificateRequired:
            return .sslError(error)
        case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return .dnsError
        case .cancelled:
            return .cancelled
        default:
            return .unknown(error)
        }
    }
}
