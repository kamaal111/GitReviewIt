//
//  FilterStateTests.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 23/12/2025.
//

import Foundation
import Observation
import SwiftUI
import Testing

@testable import GitReviewItApp

@MainActor
struct FilterStateTests {
    @Test
    func `updateSearchQuery debounces updates`() async throws {
        let persistence = MockFilterPersistence()
        let state = FilterState(persistence: persistence, timeProvider: FakeTimeProvider())

        // Initial state
        #expect(state.searchQuery.isEmpty)

        // Update query
        state.updateSearchQuery("swift")

        // Should not update immediately (task scheduled but not awaited)
        #expect(state.searchQuery.isEmpty)

        // Give the task a chance to complete
        await Task.yield()

        #expect(state.searchQuery == "swift")
    }

    @Test
    func `updateSearchQuery cancels previous updates`() async throws {
        let persistence = MockFilterPersistence()
        let state = FilterState(persistence: persistence, timeProvider: FakeTimeProvider())

        // Update 1
        state.updateSearchQuery("swif")

        // Update 2 immediately (cancels first)
        state.updateSearchQuery("swift")

        // Give the task a chance to complete
        await Task.yield()

        // Should be "swift", not "swif"
        #expect(state.searchQuery == "swift")
    }

    @Test
    func `clearSearchQuery clears immediately`() async throws {
        let persistence = MockFilterPersistence()
        let state = FilterState(persistence: persistence, timeProvider: FakeTimeProvider())

        state.updateSearchQuery("something")
        await Task.yield()
        #expect(state.searchQuery == "something")

        state.clearSearchQuery()
        #expect(state.searchQuery.isEmpty)
    }
}
