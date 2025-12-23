//
//  FilterConfiguration.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 23/12/2025.
//

import Foundation

struct FilterConfiguration: Codable, Equatable {
    let version: Int
    let selectedOrganizations: Set<String>
    let selectedRepositories: Set<String>
    let selectedTeams: Set<String>

    static let empty = FilterConfiguration(
        version: 1,
        selectedOrganizations: [],
        selectedRepositories: [],
        selectedTeams: []
    )
}
