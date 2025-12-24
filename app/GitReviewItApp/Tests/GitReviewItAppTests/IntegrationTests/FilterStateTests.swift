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
        #expect(state.debouncedSearchQuery.isEmpty)

        // Update query
        state.updateSearchQuery("swift")

        // Should update UI immediately
        #expect(state.searchQuery == "swift")
        // But not debounced query
        #expect(state.debouncedSearchQuery.isEmpty)

        // Await the search task completion
        await state.awaitSearchCompletion()

        #expect(state.debouncedSearchQuery == "swift")
    }

    @Test
    func `updateSearchQuery cancels previous updates`() async throws {
        let persistence = MockFilterPersistence()
        let state = FilterState(persistence: persistence, timeProvider: FakeTimeProvider())

        // Update 1
        state.updateSearchQuery("swif")

        // Update 2 immediately (cancels first)
        state.updateSearchQuery("swift")

        // Await the search task completion
        await state.awaitSearchCompletion()

        // Should be "swift", not "swif"
        #expect(state.debouncedSearchQuery == "swift")
    }

    @Test
    func `clearSearchQuery clears immediately`() async throws {
        let persistence = MockFilterPersistence()
        let state = FilterState(persistence: persistence, timeProvider: FakeTimeProvider())

        state.updateSearchQuery("something")
        await state.awaitSearchCompletion()
        #expect(state.debouncedSearchQuery == "something")

        state.clearSearchQuery()
        #expect(state.searchQuery.isEmpty)
        #expect(state.debouncedSearchQuery.isEmpty)
    }
}
