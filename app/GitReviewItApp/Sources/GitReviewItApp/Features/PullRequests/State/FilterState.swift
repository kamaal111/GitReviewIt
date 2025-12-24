//
//  FilterState.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 23/12/2025.
//

import OSLog
import Observation
import SwiftUI

@Observable
@MainActor
final class FilterState {
    private(set) var searchQuery: String = ""
    private(set) var configuration: FilterConfiguration = .empty
    private(set) var metadata: FilterMetadata = FilterMetadata(organizations: [], repositories: [], teams: .idle)
    private(set) var errorMessage: String?
    private let persistence: FilterPersistence
    private let timeProvider: TimeProvider
    private let logger = Logger(subsystem: "com.gitreviewit.app", category: "FilterState")

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

    func updateFilterConfiguration(_ newConfiguration: FilterConfiguration) async {
        configuration = newConfiguration
        do {
            try await persistence.save(newConfiguration)
        } catch {
            logger.error("Failed to save filter configuration: \(error.localizedDescription)")
            errorMessage = "Failed to save filter preferences. Your selections may not persist after restart."
        }
    }

    func loadPersistedConfiguration() async {
        do {
            if let loaded = try await persistence.load() {
                configuration = loaded
            }
        } catch {
            logger.warning(
                "Failed to load filter configuration: \(error.localizedDescription). Clearing corrupted data."
            )
            try? await persistence.clear()
            errorMessage = "Previous filter preferences could not be loaded and have been reset."
        }
    }

    func clearAllFilters() async {
        configuration = .empty
        do {
            try await persistence.clear()
        } catch {
            logger.error("Failed to clear filter configuration: \(error.localizedDescription)")
            errorMessage = "Failed to clear filter preferences. Some filters may still be saved."
        }
    }

    func clearError() {
        errorMessage = nil
    }

    func updateMetadata(from pullRequests: [PullRequest]) {
        metadata = FilterMetadata.from(pullRequests: pullRequests)
    }
}
