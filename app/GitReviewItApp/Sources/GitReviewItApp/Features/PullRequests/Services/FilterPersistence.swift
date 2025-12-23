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
