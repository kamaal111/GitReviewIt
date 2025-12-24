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
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Filter Pull Requests")
                    .font(.headline)
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
                            }
                        }
                    }

                    // Repositories section
                    if !metadata.repositories.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Repositories")
                                .font(.subheadline)
                                .fontWeight(.semibold)

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
                            }
                        }
                    }
                }
                .padding()
            }

            Divider()

            // Action buttons
            HStack {
                Button("Clear All") {
                    selectedOrganizations.removeAll()
                    selectedRepositories.removeAll()
                    onClearAll()
                }
                .disabled(selectedOrganizations.isEmpty && selectedRepositories.isEmpty)

                Spacer()

                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("Apply") {
                    let newConfiguration = FilterConfiguration(
                        version: 1,
                        selectedOrganizations: selectedOrganizations,
                        selectedRepositories: selectedRepositories,
                        selectedTeams: []
                    )
                    onApply(newConfiguration)
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 400, height: 500)
    }
}

#Preview {
    let metadata = FilterMetadata(
        organizations: ["CompanyA", "CompanyB", "PersonalOrg"],
        repositories: ["CompanyA/backend", "CompanyB/frontend", "PersonalOrg/hobby"],
        teams: .idle
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
