import SwiftUI

/// A reusable error display view with retry functionality
struct ErrorView: View {
    /// The error to display
    let error: APIError

    /// Optional action to perform when retry button is tapped
    let retryAction: (() -> Void)?

    /// Creates an error view
    /// - Parameters:
    ///   - error: The API error to display
    ///   - retryAction: Optional closure to execute on retry button tap
    init(error: APIError, retryAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: errorIcon)
                .font(.system(size: 48))
                .foregroundStyle(.red)

            VStack(spacing: 8) {
                Text(errorTitle)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text(errorMessage)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let retryAction = retryAction {
                Button(action: retryAction) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(errorTitle). \(errorMessage)")
    }

    // MARK: - Error Presentation

    private var errorIcon: String {
        switch error {
        case .networkError, .networkUnreachable:
            return "wifi.slash"
        case .unauthorized:
            return "lock.shield"
        case .rateLimitExceeded:
            return "hourglass"
        case .notFound:
            return "magnifyingglass"
        case .serverError:
            return "server.rack"
        default:
            return "exclamationmark.triangle"
        }
    }

    private var errorTitle: String {
        switch error {
        case .networkError, .networkUnreachable:
            return "Connection Error"
        case .unauthorized:
            return "Authentication Failed"
        case .rateLimitExceeded:
            return "Rate Limit Exceeded"
        case .notFound:
            return "Not Found"
        case .serverError:
            return "Server Error"
        case .invalidResponse, .decodingError:
            return "Invalid Response"
        default:
            return "Something Went Wrong"
        }
    }

    private var errorMessage: String {
        // Use the localized description we defined in APIError.swift
        return error.localizedDescription
    }
}

// MARK: - Previews

#Preview("Network Error") {
    ErrorView(
        error: .networkError(NSError(domain: "", code: -1009)),
        retryAction: {}
    )
}

#Preview("Unauthorized") {
    ErrorView(
        error: .unauthorized,
        retryAction: {}
    )
}

#Preview("Rate Limit") {
    ErrorView(
        error: .rateLimitExceeded(resetAt: Date().addingTimeInterval(3600)),
        retryAction: {}
    )
}

#Preview("Server Error") {
    ErrorView(
        error: .serverError(statusCode: 503),
        retryAction: {}
    )
}

#Preview("Without Retry") {
    ErrorView(error: .notFound)
}

#Preview("In Frame") {
    ErrorView(
        error: .invalidResponse,
        retryAction: {}
    )
    .frame(width: 500, height: 400)
}
