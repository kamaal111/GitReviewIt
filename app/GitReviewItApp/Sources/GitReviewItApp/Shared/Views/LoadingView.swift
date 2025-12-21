import SwiftUI

/// A reusable loading indicator view with optional message
struct LoadingView: View {
    /// Optional message to display below the loading indicator
    let message: String?
    
    /// Creates a loading view with an optional message
    /// - Parameter message: Optional text to display below the spinner
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .scaleEffect(1.5)
            
            if let message = message {
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message ?? "Loading")
    }
}

// MARK: - Previews

#Preview("Loading without message") {
    LoadingView()
}

#Preview("Loading with message") {
    LoadingView(message: "Fetching pull requests...")
}

#Preview("Loading in frame") {
    LoadingView(message: "Authenticating...")
        .frame(width: 400, height: 300)
}
