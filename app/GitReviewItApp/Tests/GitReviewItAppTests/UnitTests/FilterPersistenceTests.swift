//
//  FilterPersistenceTests.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 24/12/2025.
//

import Testing
import Foundation
@testable import GitReviewItApp

@Suite struct FilterPersistenceTests {

    @Test
    func `Save and load round-trip preserves configuration`() async throws {
        let persistence = UserDefaultsFilterPersistence(suiteName: "test.filter.persistence.roundtrip")

        let configuration = FilterConfiguration(
            version: 1,
            selectedOrganizations: ["CompanyA", "CompanyB"],
            selectedRepositories: ["CompanyA/backend", "CompanyB/frontend"],
            selectedTeams: ["backend-team"]
        )

        try await persistence.save(configuration)
        let loaded = try await persistence.load()

        #expect(loaded == configuration)
    }

    @Test
    func `Load returns nil when no data saved`() async throws {
        let persistence = UserDefaultsFilterPersistence(suiteName: "test.filter.persistence.nodata")

        let loaded = try await persistence.load()

        #expect(loaded == nil)
    }

    @Test
    func `Clear removes saved configuration`() async throws {
        let persistence = UserDefaultsFilterPersistence(suiteName: "test.filter.persistence.clear")

        let configuration = FilterConfiguration(
            version: 1,
            selectedOrganizations: ["CompanyA"],
            selectedRepositories: [],
            selectedTeams: []
        )

        try await persistence.save(configuration)
        let loadedBeforeClear = try await persistence.load()
        #expect(loadedBeforeClear != nil)

        try await persistence.clear()
        let loadedAfterClear = try await persistence.load()

        #expect(loadedAfterClear == nil)
    }

    @Test
    func `Load throws on corrupted data`() async throws {
        let suiteName = "test.filter.persistence.corrupted"
        let persistence = UserDefaultsFilterPersistence(suiteName: suiteName)

        // Manually inject corrupted data
        let defaults = UserDefaults(suiteName: suiteName)!
        let corruptedData = Data("not valid json".utf8)
        defaults.set(corruptedData, forKey: "com.gitreviewit.filter.configuration")

        await #expect(throws: Error.self) {
            try await persistence.load()
        }
    }

    @Test
    func `Save empty configuration succeeds`() async throws {
        let persistence = UserDefaultsFilterPersistence(suiteName: "test.filter.persistence.empty")

        let emptyConfiguration = FilterConfiguration(
            version: 1,
            selectedOrganizations: [],
            selectedRepositories: [],
            selectedTeams: []
        )

        try await persistence.save(emptyConfiguration)
        let loaded = try await persistence.load()

        #expect(loaded == emptyConfiguration)
    }

    @Test
    func `Multiple save operations overwrite previous configuration`() async throws {
        let persistence = UserDefaultsFilterPersistence(suiteName: "test.filter.persistence.overwrite")

        let firstConfig = FilterConfiguration(
            version: 1,
            selectedOrganizations: ["OrgA"],
            selectedRepositories: [],
            selectedTeams: []
        )

        let secondConfig = FilterConfiguration(
            version: 1,
            selectedOrganizations: ["OrgB"],
            selectedRepositories: ["OrgB/repo"],
            selectedTeams: []
        )

        try await persistence.save(firstConfig)
        try await persistence.save(secondConfig)
        let loaded = try await persistence.load()

        #expect(loaded == secondConfig)
    }
}
