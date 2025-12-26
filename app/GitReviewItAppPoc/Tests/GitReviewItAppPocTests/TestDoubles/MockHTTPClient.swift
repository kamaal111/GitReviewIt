import Foundation

@testable import GitReviewItAppPoc

/// Mock implementation of HTTPClient for testing
/// Allows pre-configuring responses and capturing requests
@MainActor
final class MockHTTPClient: HTTPClient {
    // MARK: - Configuration

    /// Closure to generate responses for requests
    var responseHandler: ((URLRequest) async throws -> (Data, HTTPURLResponse))?

    /// Stored responses keyed by URL string
    var responses: [String: (Data, HTTPURLResponse)] = [:]

    /// Error to throw for all requests
    var errorToThrow: Error?

    // MARK: - Captured Data

    /// All requests that were performed
    private(set) var capturedRequests: [URLRequest] = []

    /// Count of how many times perform was called
    var performCallCount: Int {
        capturedRequests.count
    }

    // MARK: - HTTPClient Protocol

    func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        // Capture the request
        capturedRequests.append(request)

        // Throw configured error if set
        if let error = errorToThrow {
            throw error
        }

        // Use custom response handler if provided
        if let handler = responseHandler {
            return try await handler(request)
        }

        // Use pre-configured response for URL if available
        if let urlString = request.url?.absoluteString,
           let response = responses[urlString] {
            return response
        }

        // Default: return empty 200 OK response
        let defaultResponse = HTTPURLResponse(
            url: request.url ?? URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        return (Data(), defaultResponse)
    }

    // MARK: - Test Helpers

    /// Reset all captured data and configuration
    func reset() {
        capturedRequests.removeAll()
        responses.removeAll()
        responseHandler = nil
        errorToThrow = nil
    }

    /// Set a response for a specific URL
    func setResponse(for urlString: String, data: Data, statusCode: Int) {
        guard let url = URL(string: urlString) else { return }
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        responses[urlString] = (data, response)
    }

    /// Get the last captured request
    var lastRequest: URLRequest? {
        capturedRequests.last
    }

    /// Check if a request was made to a specific URL
    func didRequest(urlContaining substring: String) -> Bool {
        capturedRequests.contains { request in
            request.url?.absoluteString.contains(substring) ?? false
        }
    }
}
