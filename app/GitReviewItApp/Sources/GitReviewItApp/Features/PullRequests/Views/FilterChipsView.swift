//
//  FilterChipsView.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 24/12/2025.
//

import SwiftUI

struct FilterChipsView: View {
    let configuration: FilterConfiguration
    let onRemoveOrganization: (String) -> Void
    let onRemoveRepository: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Organization chips
                ForEach(Array(configuration.selectedOrganizations).sorted(), id: \.self) { org in
                    FilterChip(
                        title: org,
                        type: "org",
                        onRemove: { onRemoveOrganization(org) }
                    )
                }

                // Repository chips (hide when organizations are selected)
                if configuration.selectedOrganizations.isEmpty {
                    ForEach(Array(configuration.selectedRepositories).sorted(), id: \.self) { repo in
                        FilterChip(
                            title: repo,
                            type: "repo",
                            onRemove: { onRemoveRepository(repo) }
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct FilterChip: View {
    let title: String
    let type: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(typeLabel)
                .font(.caption2)
                .foregroundColor(.secondary)

            Text(title)
                .font(.caption)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Remove filter")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.2))
        .cornerRadius(12)
    }

    private var typeLabel: String {
        switch type {
        case "org": return "ORG"
        case "repo": return "REPO"
        case "team": return "TEAM"
        default: return ""
        }
    }
}

#Preview {
    let config = FilterConfiguration(
        version: 1,
        selectedOrganizations: ["CompanyA", "CompanyB"],
        selectedRepositories: ["CompanyA/backend", "PersonalOrg/hobby"],
        selectedTeams: []
    )

    return FilterChipsView(
        configuration: config,
        onRemoveOrganization: { _ in },
        onRemoveRepository: { _ in }
    )
    .frame(height: 40)
}
