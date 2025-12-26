//
//  FilterRestoreTests.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 24/12/2025.
//

import Foundation
import Testing

@testable import GitReviewItAppPoc

@Suite("Filter Restore Integration Tests")
struct FilterRestoreTests {

    @Test
    func `Filter configuration persists across container recreations`() async throws {
        let suiteName = "test.filter.restore.persistence"
        let persistence = UserDefaultsFilterPersistence(suiteName: suiteName)
        let timeProvider = FakeTimeProvider()

        // Create initial configuration
        let initialConfig = FilterConfiguration(
            version: 1,
            selectedOrganizations: ["OrgA", "OrgB"],
            selectedRepositories: ["OrgA/repo1"],
            selectedTeams: []
        )

        // Save through FilterState
        let filterState1 = await FilterState(persistence: persistence, timeProvider: timeProvider)
        await filterState1.updateFilterConfiguration(initialConfig)

        // Create new FilterState instance (simulates app restart)
        let filterState2 = await FilterState(persistence: persistence, timeProvider: timeProvider)
        await filterState2.loadPersistedConfiguration()

        // Verify configuration was restored
        let restoredConfig = await filterState2.configuration
        #expect(restoredConfig == initialConfig)
    }

    @Test
    func `Clear all filters removes persisted configuration`() async throws {
        let suiteName = "test.filter.restore.clear"
        let persistence = UserDefaultsFilterPersistence(suiteName: suiteName)
        let timeProvider = FakeTimeProvider()

        // Save initial configuration
        let initialConfig = FilterConfiguration(
            version: 1,
            selectedOrganizations: ["OrgA"],
            selectedRepositories: [],
            selectedTeams: []
        )

        let filterState = await FilterState(persistence: persistence, timeProvider: timeProvider)
        await filterState.updateFilterConfiguration(initialConfig)

        // Clear filters
        await filterState.clearAllFilters()

        // Create new instance and verify empty
        let filterState2 = await FilterState(persistence: persistence, timeProvider: timeProvider)
        await filterState2.loadPersistedConfiguration()

        let restoredConfig = await filterState2.configuration
        #expect(restoredConfig == .empty)
    }

    @Test
    func `Multiple filter updates preserve latest configuration`() async throws {
        let suiteName = "test.filter.restore.multiple"
        let persistence = UserDefaultsFilterPersistence(suiteName: suiteName)
        let timeProvider = FakeTimeProvider()

        let filterState = await FilterState(persistence: persistence, timeProvider: timeProvider)

        // First update
        let config1 = FilterConfiguration(
            version: 1,
            selectedOrganizations: ["OrgA"],
            selectedRepositories: [],
            selectedTeams: []
        )
        await filterState.updateFilterConfiguration(config1)

        // Second update
        let config2 = FilterConfiguration(
            version: 1,
            selectedOrganizations: ["OrgA", "OrgB"],
            selectedRepositories: ["OrgA/repo"],
            selectedTeams: []
        )
        await filterState.updateFilterConfiguration(config2)

        // Verify latest is persisted
        let filterState2 = await FilterState(persistence: persistence, timeProvider: timeProvider)
        await filterState2.loadPersistedConfiguration()

        let restoredConfig = await filterState2.configuration
        #expect(restoredConfig == config2)
    }

    @Test
    func `Empty filter configuration can be saved and restored`() async throws {
        let suiteName = "test.filter.restore.empty"
        let persistence = UserDefaultsFilterPersistence(suiteName: suiteName)
        let timeProvider = FakeTimeProvider()

        let emptyConfig = FilterConfiguration.empty

        let filterState1 = await FilterState(persistence: persistence, timeProvider: timeProvider)
        await filterState1.updateFilterConfiguration(emptyConfig)

        let filterState2 = await FilterState(persistence: persistence, timeProvider: timeProvider)
        await filterState2.loadPersistedConfiguration()

        let restoredConfig = await filterState2.configuration
        #expect(restoredConfig == emptyConfig)
    }
}
