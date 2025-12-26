//
//  TeamTests.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 23/12/2025.
//

import Foundation
import Testing

@testable import GitReviewItAppPoc

struct TeamTests {
    @Test
    func `Team decodes correctly from GitHub API format`() throws {
        let json = Data(
            """
            [
                {
                    "slug": "justice-league",
                    "name": "Justice League",
                    "organization": {
                        "login": "dc"
                    },
                    "repositories": ["dc/batmobile", "dc/watchtower"]
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
        #expect(justiceLeague.repositories == ["dc/batmobile", "dc/watchtower"])
    }

    @Test
    func `Team decodes without repositories field`() throws {
        let json = Data(
            """
            [
                {
                    "slug": "avengers",
                    "name": "Avengers",
                    "organization": {
                        "login": "marvel"
                    }
                }
            ]
            """.utf8)

        let teams = try JSONDecoder().decode([Team].self, from: json)

        #expect(teams.count == 1)

        let avengers = teams[0]
        #expect(avengers.name == "Avengers")
        #expect(avengers.slug == "avengers")
        #expect(avengers.organizationLogin == "marvel")
        #expect(avengers.repositories == [])
    }

    @Test
    func `Team encodes and decodes round-trip correctly`() throws {
        let original = Team(
            slug: "test-team",
            name: "Test Team",
            organizationLogin: "testorg",
            repositories: ["testorg/repo1", "testorg/repo2"]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode([original])

        let decoder = JSONDecoder()
        let decoded = try decoder.decode([Team].self, from: data)

        #expect(decoded.count == 1)
        #expect(decoded[0] == original)
    }

    @Test
    func `Team ID uses fullSlug for uniqueness across organizations`() {
        let team1 = Team(
            slug: "backend-team",
            name: "Backend Team A",
            organizationLogin: "CompanyA",
            repositories: ["CompanyA/backend"]
        )

        let team2 = Team(
            slug: "backend-team",
            name: "Backend Team B",
            organizationLogin: "CompanyB",
            repositories: ["CompanyB/backend"]
        )

        // Teams with same slug but different orgs should have different IDs
        #expect(team1.id != team2.id)
        #expect(team1.id == "CompanyA/backend-team")
        #expect(team2.id == "CompanyB/backend-team")

        // Verify they are distinguishable by ID
        let teams = [team1, team2]
        let uniqueIDs = Set(teams.map { $0.id })
        #expect(uniqueIDs.count == 2)
    }

    @Test
    func `Teams with same slug in different orgs are not equal`() {
        let team1 = Team(
            slug: "backend-team",
            name: "Backend Team",
            organizationLogin: "CompanyA",
            repositories: []
        )

        let team2 = Team(
            slug: "backend-team",
            name: "Backend Team",
            organizationLogin: "CompanyB",
            repositories: []
        )

        #expect(team1 != team2)
    }

    @Test
    func `Teams with different slugs in same org are not equal`() {
        let team1 = Team(
            slug: "backend-team",
            name: "Backend Team",
            organizationLogin: "CompanyA",
            repositories: []
        )

        let team2 = Team(
            slug: "frontend-team",
            name: "Frontend Team",
            organizationLogin: "CompanyA",
            repositories: []
        )

        #expect(team1 != team2)
        #expect(team1.id != team2.id)
    }
}
