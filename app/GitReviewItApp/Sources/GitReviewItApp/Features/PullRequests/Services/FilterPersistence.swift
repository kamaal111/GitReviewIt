//
//  FilterPersistence.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 23/12/2025.
//

import Foundation

protocol FilterPersistence: Sendable {
    func save(_ configuration: FilterConfiguration) async throws
    func load() async throws -> FilterConfiguration?
    func clear() async throws
}

actor UserDefaultsFilterPersistence: FilterPersistence {
    private let defaults: UserDefaults
    private let key = "com.gitreviewit.filter.configuration"

    init(suiteName: String? = nil) {
        if let suiteName {
            self.defaults = UserDefaults(suiteName: suiteName) ?? .standard
        } else {
            self.defaults = .standard
        }
    }

    func save(_ configuration: FilterConfiguration) async throws {
        let data = try JSONEncoder().encode(configuration)
        defaults.set(data, forKey: key)
    }

    func load() async throws -> FilterConfiguration? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(FilterConfiguration.self, from: data)
    }

    func clear() async throws {
        defaults.removeObject(forKey: key)
    }
}
