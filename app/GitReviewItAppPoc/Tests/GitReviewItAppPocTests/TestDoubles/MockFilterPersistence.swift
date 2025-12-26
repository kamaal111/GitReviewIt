//
//  MockFilterPersistence.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 23/12/2025.
//

import Foundation

@testable import GitReviewItAppPoc

final class MockFilterPersistence: FilterPersistence, @unchecked Sendable {
    var savedConfiguration: FilterConfiguration?
    var shouldThrowOnSave = false
    var shouldThrowOnLoad = false

    func save(_ configuration: FilterConfiguration) async throws {
        guard !shouldThrowOnSave else { throw PersistenceError.saveFailed }
        savedConfiguration = configuration
    }

    func load() async throws -> FilterConfiguration? {
        guard !shouldThrowOnLoad else { throw PersistenceError.loadFailed }
        return savedConfiguration
    }

    func clear() async throws {
        savedConfiguration = nil
    }
}

enum PersistenceError: Error {
    case saveFailed
    case loadFailed
}
