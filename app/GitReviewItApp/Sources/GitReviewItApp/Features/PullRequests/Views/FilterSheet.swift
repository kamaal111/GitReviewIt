//
//  FilterSheet.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 24/12/2025.
//

import SwiftUI

struct FilterSheet: View {
    let metadata: FilterMetadata
    let currentConfiguration: FilterConfiguration
    let onApply: (FilterConfiguration) -> Void
    let onCancel: () -> Void
    let onClearAll: () -> Void

    @State private var selectedOrganizations: Set<String>
    @State private var selectedRepositories: Set<String>
    @State private var selectedTeams: Set<String>

    private let syncService: FilterSyncService

    init(
        metadata: FilterMetadata,
        currentConfiguration: FilterConfiguration,
        onApply: @escaping (FilterConfiguration) -> Void,
        onCancel: @escaping () -> Void,
        onClearAll: @escaping () -> Void
    ) {
        self.metadata = metadata
        self.currentConfiguration = currentConfiguration
        self.onApply = onApply
        self.onCancel = onCancel
        self.onClearAll = onClearAll
        self.syncService = FilterSyncService(metadata: metadata)

        self._selectedOrganizations = State(initialValue: currentConfiguration.selectedOrganizations)
        self._selectedRepositories = State(initialValue: currentConfiguration.selectedRepositories)
        self._selectedTeams = State(initialValue: currentConfiguration.selectedTeams)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Filter Pull Requests")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }
            .padding()

            Divider()

            // Filter sections
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Organizations section
                    if !metadata.organizations.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Organizations")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .accessibilityAddTraits(.isHeader)

                            ForEach(metadata.sortedOrganizations, id: \.self) { org in
                                Toggle(
                                    isOn: Binding(
                                        get: { selectedOrganizations.contains(org) },
                                        set: { isSelected in
                                            if isSelected {
                                                selectedOrganizations.insert(org)
                                                selectedRepositories = syncService.selectAllRepositories(
                                                    from: org,
                                                    currentRepositories: selectedRepositories
                                                )
                                            } else {
                                                selectedOrganizations.remove(org)
                                                selectedRepositories = syncService.deselectAllRepositories(
                                                    from: org,
                                                    currentRepositories: selectedRepositories
                                                )
                                            }
                                        }
                                    )
                                ) {
                                    Text(org)
                                }
                                .accessibilityLabel("Filter by organization \(org)")
                            }
                        }
                    }

                    // Repositories section
                    if !metadata.repositories.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Repositories")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .accessibilityAddTraits(.isHeader)

                            ForEach(metadata.sortedRepositories, id: \.self) { repo in
                                Toggle(
                                    isOn: Binding(
                                        get: { selectedRepositories.contains(repo) },
                                        set: { isSelected in
                                            if isSelected {
                                                selectedRepositories.insert(repo)
                                            } else {
                                                selectedRepositories.remove(repo)
                                            }
                                            selectedOrganizations = syncService.syncOrganizations(
                                                basedOn: selectedRepositories,
                                                currentOrganizations: selectedOrganizations
                                            )
                                        }
                                    )
                                ) {
                                    Text(repo)
                                }
                                .accessibilityLabel("Filter by repository \(repo)")
                            }
                        }
                    }

                    // Teams section
                    teamsSection
                }
                .padding()
            }

            Divider()

            // Action buttons
            HStack {
                Button("Clear All") {
                    selectedOrganizations.removeAll()
                    selectedRepositories.removeAll()
                    selectedTeams.removeAll()
                    onClearAll()
                }
                .disabled(selectedOrganizations.isEmpty && selectedRepositories.isEmpty && selectedTeams.isEmpty)
                .accessibilityHint("Removes all active filters")

                Spacer()

                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                .accessibilityHint("Dismisses the filter sheet without applying changes")

                Button("Apply") {
                    let newConfiguration = FilterConfiguration(
                        version: 1,
                        selectedOrganizations: selectedOrganizations,
                        selectedRepositories: selectedRepositories,
                        selectedTeams: selectedTeams
                    )
                    onApply(newConfiguration)
                }
                .keyboardShortcut(.defaultAction)
                .accessibilityHint("Applies the selected filters")
            }
            .padding()
        }
        .frame(width: 400, height: 500)
    }

    @ViewBuilder
    private var teamsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Teams")
                .font(.subheadline)
                .fontWeight(.semibold)
                .accessibilityAddTraits(.isHeader)

            switch metadata.teams {
            case .idle:
                Text("Loading teams...")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .accessibilityLabel("Waiting to load teams")
            case .loading:
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading teams...")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Loading teams")
            case .loaded(let teams):
                if teams.isEmpty {
                    Text("No teams available")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .accessibilityLabel("No teams found")
                } else {
                    ForEach(teams.sorted(by: { $0.name < $1.name }), id: \.fullSlug) { team in
                        Toggle(
                            isOn: Binding(
                                get: { selectedTeams.contains(team.fullSlug) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedTeams.insert(team.fullSlug)
                                    } else {
                                        selectedTeams.remove(team.fullSlug)
                                    }
                                }
                            )
                        ) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(team.name)
                                Text(team.organizationLogin)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityLabel("Filter by team \(team.name) from \(team.organizationLogin)")
                    }
                }
            case .failed(let error):
                VStack(alignment: .leading, spacing: 4) {
                    Label("Team filtering unavailable", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text(teamUnavailableMessage(for: error))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Team filtering unavailable: \(teamUnavailableMessage(for: error))")
            }
        }
    }

    private func teamUnavailableMessage(for error: APIError) -> String {
        switch error {
        case .unauthorized:
            return "Authentication required. Please sign in again."
        case .httpError(let statusCode, _) where statusCode == 403:
            return """
                Requires additional permissions (read:org scope). Team filtering will work when you have access to \
                organization data.
                """
        case .networkUnreachable:
            return "Network unavailable. Team filtering will be available when connection is restored."
        case .rateLimitExceeded:
            return "API rate limit exceeded. Team filtering will be available after the limit resets."
        default:
            return "Unable to load teams. Organization and repository filters are still available."
        }
    }
}

#Preview {
    let metadata = FilterMetadata(
        organizations: ["CompanyA", "CompanyB", "PersonalOrg"],
        repositories: ["CompanyA/backend", "CompanyB/frontend", "PersonalOrg/hobby"],
        teams: .loaded([
            Team(slug: "backend-team", name: "Backend Team", organizationLogin: "CompanyA", repositories: []),
            Team(slug: "frontend-team", name: "Frontend Team", organizationLogin: "CompanyB", repositories: [])
        ])
    )

    let config = FilterConfiguration(
        version: 1,
        selectedOrganizations: ["CompanyA"],
        selectedRepositories: [],
        selectedTeams: []
    )

    return FilterSheet(
        metadata: metadata,
        currentConfiguration: config,
        onApply: { _ in },
        onCancel: {},
        onClearAll: {}
    )
}
