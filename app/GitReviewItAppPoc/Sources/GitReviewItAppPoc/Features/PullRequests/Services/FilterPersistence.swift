//
//  FilterPersistence.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 23/12/2025.
//

import Foundation

/// Protocol defining persistence operations for filter configuration.
///
/// Allows saving, loading, and clearing filter settings.
/// Implementations should handle the underlying storage mechanism (e.g., UserDefaults, FileSystem).
protocol FilterPersistence: Sendable {
    /// Saves the filter configuration to persistent storage.
    /// - Parameter configuration: The configuration to save
    /// - Throws: Error if saving fails
    func save(_ configuration: FilterConfiguration) async throws

    /// Loads the filter configuration from persistent storage.
    /// - Returns: The loaded configuration, or nil if no configuration exists
    /// - Throws: Error if loading fails
    func load() async throws -> FilterConfiguration?

    /// Clears the stored filter configuration.
    /// - Throws: Error if clearing fails
    func clear() async throws
}

/// Implementation of filter persistence using UserDefaults.
///
/// Stores the configuration as JSON data under a specific key.
/// Thread-safe implementation using actor isolation.
actor UserDefaultsFilterPersistence: FilterPersistence {
    private let defaults: UserDefaults
    private let key = "com.gitreviewit.filter.configuration"

    /// Creates a new persistence instance.
    /// - Parameter suiteName: Optional suite name for UserDefaults (defaults to standard)
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
