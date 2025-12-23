//
//  Team.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 23/12/2025.
//

import Foundation

struct Team: Codable, Equatable, Identifiable {
    let slug: String
    let name: String
    let organizationLogin: String
    let repositories: [String]

    var id: String { slug }

    var fullSlug: String {
        "\(organizationLogin)/\(slug)"
    }
}
