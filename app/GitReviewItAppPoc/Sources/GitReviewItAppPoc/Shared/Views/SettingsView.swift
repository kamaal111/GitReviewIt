import OSLog
import SwiftUI

/// Settings view displaying app information and logout option
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    private let onLogout: () async -> Void
    private let logger = Logger(subsystem: "com.gitreviewit.app", category: "Settings")

    /// Creates a new settings view
    /// - Parameter onLogout: Closure to execute when user requests logout
    init(onLogout: @escaping () async -> Void) {
        self.onLogout = onLogout
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close settings")
            }
            .padding()

            Divider()

            // Settings content
            Form {
                Section {
                    HStack {
                        Text("Version")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(appVersion)
                    }

                    HStack {
                        Text("Build")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(buildNumber)
                    }
                } header: {
                    Text("App Information")
                }

                Section {
                    Button(role: .destructive) {
                        Task {
                            logger.info("User initiated logout from settings")
                            await onLogout()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                            Spacer()
                        }
                    }
                    .accessibilityLabel("Log out of GitReviewIt")
                } header: {
                    Text("Account")
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 400, height: 300)
    }

    // MARK: - Computed Properties

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
}

#Preview {
    SettingsView(onLogout: {})
}
