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
    @State private var showPATInstructions: Bool = false

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
                    HStack(spacing: 4) {
                        Text("Personal Access Token")
                            .font(.headline)

                        Button {
                            showPATInstructions = true
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("How to create a Personal Access Token")
                    }

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
        .sheet(isPresented: $showPATInstructions) {
            PATInstructionsSheet(isPresented: $showPATInstructions)
        }
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
        guard URLValidator.isValid(baseURL) else {
            validationMessage = "Invalid URL format. Must start with http:// or https://"
            showValidationError = true
            return false
        }

        showValidationError = false
        return true
    }
}

// MARK: - PAT Instructions Sheet

/// Sheet view that explains how to create a GitHub Personal Access Token
private struct PATInstructionsSheet: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("How to Create a Personal Access Token")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close instructions")
            }

            Divider()

            // Instructions
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    InstructionStep(
                        number: 1,
                        title: "Go to GitHub Settings",
                        description:
                            """
                            Click your profile picture → Settings → Developer settings →
                            Personal access tokens → Tokens (classic)
                            """
                    )

                    InstructionStep(
                        number: 2,
                        title: "Generate New Token",
                        description:
                            "Click \"Generate new token\" and select \"Generate new token (classic)\""
                    )

                    InstructionStep(
                        number: 3,
                        title: "Configure Token",
                        description:
                            "Give it a descriptive name, set an expiration, and select the following scopes:"
                    )

                    // Required scopes
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Required Scopes:")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack(spacing: 8) {
                            ScopeBadge(scope: "repo")
                            ScopeBadge(scope: "read:user")
                        }
                    }
                    .padding(.leading, 36)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Required scopes: repo, read:user")

                    InstructionStep(
                        number: 4,
                        title: "Copy Your Token",
                        description:
                            "Click \"Generate token\" and copy it immediately — you won't be able to see it again!"
                    )
                }
            }

            Spacer()

            // Open GitHub Button
            HStack {
                Spacer()

                Link(destination: URL(string: "https://github.com/settings/tokens/new")!) {
                    HStack {
                        Text("Open GitHub Token Settings")
                        Image(systemName: "arrow.up.right")
                    }
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
        }
        .padding(24)
        .frame(width: 500, height: 450)
    }
}

/// A single numbered instruction step
private struct InstructionStep: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(.blue))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number): \(title). \(description)")
    }
}

/// A badge showing a required scope
private struct ScopeBadge: View {
    let scope: String

    var body: some View {
        Text(scope)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(.blue.opacity(0.1))
            )
            .foregroundStyle(.blue)
    }
}

#if DEBUG
    private struct PreviewGitHubAPI: GitHubAPI {
        func fetchUser(credentials: GitHubCredentials) async throws -> AuthenticatedUser {
            AuthenticatedUser(login: "kamaal111", name: "Kamaal", avatarURL: nil)
        }

        func fetchTeams(credentials: GitHubCredentials) async throws -> [Team] { [] }

        func fetchReviewRequests(credentials: GitHubCredentials) async throws -> [PullRequest] { [] }

        func fetchPRDetails(
            owner: String,
            repo: String,
            number: Int,
            credentials: GitHubCredentials
        ) async throws -> PRPreviewMetadata {
            PRPreviewMetadata(
                additions: 10,
                deletions: 5,
                changedFiles: 2,
                requestedReviewers: []
            )
        }

        func fetchPRReviews(
            owner: String,
            repo: String,
            number: Int,
            credentials: GitHubCredentials
        ) async throws -> [PRReviewResponse] {
            []
        }
    }

    private struct PreviewCredentialStorage: CredentialStorage {
        func store(_ credentials: GitHubCredentials) async throws {}
        func retrieve() async throws -> GitHubCredentials? { nil }
        func delete() async throws {}
    }

    #Preview {
        LoginView(
            container: AuthenticationContainer(
                githubAPI: PreviewGitHubAPI(),
                credentialStorage: PreviewCredentialStorage()
            )
        )
    }
#endif
