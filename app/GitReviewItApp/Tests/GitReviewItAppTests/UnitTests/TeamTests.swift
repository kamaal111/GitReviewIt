//
//  TeamTests.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 23/12/2025.
//

import Foundation
import Testing

@testable import GitReviewItApp

struct TeamTests {
    @Test
    func `Team decodes correctly`() throws {
        let json = Data("""
        [
            {
                "slug": "justice-league",
                "name": "Justice League",
                "organizationLogin": "dc",
                "repositories": ["batmobile", "watchtower"]
            }
        ]
        """.utf8)

        let teams = try JSONDecoder().decode([Team].self, from: json)

        #expect(teams.count == 1)

        let justiceLeague = teams[0]
        #expect(justiceLeague.name == "Justice League")
        #expect(justiceLeague.slug == "justice-league")
        #expect(justiceLeague.organizationLogin == "dc")
        #expect(justiceLeague.fullSlug == "dc/justice-league")
        #expect(justiceLeague.repositories == ["batmobile", "watchtower"])
    }
}
