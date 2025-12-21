import SwiftUI

/// Login screen where users enter their GitHub Personal Access Token
/// and optionally specify a custom GitHub Enterprise base URL.
struct LoginView: View {

    // MARK: - State Container

    @State private var container: AuthenticationContainer

    // MARK: - Local State

    @State private var token: String = ""
    @State private var baseURL: String = "https://api.github.com"
    @State private var showValidationError: Bool = false
    @State private var validationMessage: String = ""

    // MARK: - Initialization

    init(container: AuthenticationContainer) {
        self.container = container
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Sign in to GitHub")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Enter your Personal Access Token to get started")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 8)

            // Form Fields
            VStack(spacing: 16) {
                // Personal Access Token Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Personal Access Token")
                        .font(.headline)

                    SecureField("ghp_xxxxxxxxxxxxxxxxxxxx", text: $token)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()

                    Link(
                        "Need a token? Create one →",
                        destination: URL(string: "https://github.com/settings/tokens")!
                    )
                    .font(.caption)
                    .foregroundStyle(.blue)
                }

                // GitHub API Base URL Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Base URL (Optional)")
                        .font(.headline)

                    TextField("https://api.github.com", text: $baseURL)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()

                    Text("For GitHub Enterprise, use: https://github.company.com/api/v3")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)

            // Validation Error
            if showValidationError {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            // API Error
            if let error = container.error {
                ErrorView(error: error)
                    .padding(.horizontal)
            }

            // Sign In Button
            Button(action: signIn) {
                if container.isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(container.isLoading)
            .padding(.horizontal)
            .padding(.top, 8)

            Spacer()
        }
        .padding()
        .frame(minWidth: 400, minHeight: 500)
    }

    // MARK: - Actions

    private func signIn() {
        // Validate inputs
        guard validateInputs() else {
            return
        }

        // Clear any previous errors
        showValidationError = false

        // Attempt to sign in
        Task {
            await container.validateAndSaveCredentials(token: token, baseURL: baseURL)
        }
    }

    // MARK: - Validation

    private func validateInputs() -> Bool {
        // Validate token is not empty
        guard !token.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationMessage = "Personal Access Token is required"
            showValidationError = true
            return false
        }

        // Validate baseURL is not empty
        guard !baseURL.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationMessage = "API Base URL cannot be empty"
            showValidationError = true
            return false
        }

        // Validate baseURL format
        guard let url = URL(string: baseURL),
            url.scheme == "http" || url.scheme == "https",
            url.host != nil
        else {
            validationMessage = "Invalid URL format. Must start with http:// or https://"
            showValidationError = true
            return false
        }

        showValidationError = false
        return true
    }
}
