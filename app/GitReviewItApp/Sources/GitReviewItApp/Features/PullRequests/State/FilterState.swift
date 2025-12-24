//
//  FilterState.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 23/12/2025.
//

import Observation
import SwiftUI

@Observable
@MainActor
final class FilterState {
    private(set) var searchQuery: String = ""
    private(set) var configuration: FilterConfiguration = .empty
    private let persistence: FilterPersistence
    private let timeProvider: TimeProvider

    private var searchTask: Task<Void, Never>?

    init(persistence: FilterPersistence, timeProvider: TimeProvider = RealTimeProvider()) {
        self.persistence = persistence
        self.timeProvider = timeProvider
    }

    func updateSearchQuery(_ query: String) {
        searchTask?.cancel()
        searchTask = Task {
            do {
                try await timeProvider.sleep(nanoseconds: 300 * 1_000_000)
            } catch {
                return
            }

            guard !Task.isCancelled else { return }
            self.searchQuery = query
        }
    }

    func clearSearchQuery() {
        searchTask?.cancel()
        searchQuery = ""
    }
}
