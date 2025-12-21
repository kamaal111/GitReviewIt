import Foundation
import Testing

@testable import GitReviewItApp

struct TeamTests {
    @Test
    func `Team fixture decodes correctly`() throws {
        let url = Bundle.module.url(forResource: "teams-response", withExtension: "json")!
        let data = try Data(contentsOf: url)

        let teams = try JSONDecoder().decode([Team].self, from: data)

        #expect(teams.count == 2)

        let justiceLeague = teams[0]
        #expect(justiceLeague.name == "Justice League")
        #expect(justiceLeague.slug == "justice-league")
        #expect(justiceLeague.organization.login == "dc")
        #expect(justiceLeague.fullSlug == "dc/justice-league")

        let avengers = teams[1]
        #expect(avengers.name == "Avengers")
        #expect(avengers.slug == "avengers")
        #expect(avengers.organization.login == "marvel")
        #expect(avengers.fullSlug == "marvel/avengers")
    }
}
