//
//  TimeProvider.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 24/12/2025.
//

import Foundation

/// Protocol for providing time-based operations (used for testing)
protocol TimeProvider: Sendable {
    func sleep(nanoseconds: UInt64) async throws
}

/// Production time provider that uses real Task.sleep
struct RealTimeProvider: TimeProvider {
    func sleep(nanoseconds: UInt64) async throws {
        try await Task.sleep(nanoseconds: nanoseconds)
    }
}

/// Test time provider that doesn't actually sleep
actor FakeTimeProvider: TimeProvider {
    func sleep(nanoseconds: UInt64) async throws {
        // No-op: instant execution for tests
    }
}
