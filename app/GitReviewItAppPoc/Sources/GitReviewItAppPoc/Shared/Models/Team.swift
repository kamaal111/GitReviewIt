//
//  Team.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 23/12/2025.
//

import Foundation

struct Team: Codable, Equatable, Identifiable, Hashable {
    let slug: String
    let name: String
    let organizationLogin: String
    let repositories: [String]

    var id: String { fullSlug }

    var fullSlug: String {
        "\(organizationLogin)/\(slug)"
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case slug
        case name
        case organization
        case repositories
    }

    enum OrganizationKeys: String, CodingKey {
        case login
    }

    init(slug: String, name: String, organizationLogin: String, repositories: [String]) {
        self.slug = slug
        self.name = name
        self.organizationLogin = organizationLogin
        self.repositories = repositories
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.slug = try container.decode(String.self, forKey: .slug)
        self.name = try container.decode(String.self, forKey: .name)

        // Handle nested organization object from GitHub API
        let orgContainer = try container.nestedContainer(keyedBy: OrganizationKeys.self, forKey: .organization)
        self.organizationLogin = try orgContainer.decode(String.self, forKey: .login)

        // Repositories might not be present in all responses, default to empty array
        self.repositories = try container.decodeIfPresent([String].self, forKey: .repositories) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(slug, forKey: .slug)
        try container.encode(name, forKey: .name)

        // Encode organization as nested object
        var orgContainer = container.nestedContainer(keyedBy: OrganizationKeys.self, forKey: .organization)
        try orgContainer.encode(organizationLogin, forKey: .login)

        try container.encode(repositories, forKey: .repositories)
    }
}
