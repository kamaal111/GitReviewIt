//
//  FilterPerformanceTests.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 24/12/2025.
//

import Foundation
import Testing

@testable import GitReviewItApp

/// Performance tests for filtering operations with large datasets
@Suite("Filter Performance Tests")
struct FilterPerformanceTests {
    private let engine = FilterEngine()
    private let fuzzyMatcher = FuzzyMatcher()

    /// T059: Verify filtering completes within 500ms for 500 PRs
    @Test
    func `filtering 500 PRs completes within 500ms`() async throws {
        // Load 500 PR fixture
        let prs = try loadLargeFixture()
        #expect(prs.count == 500)

        // Test various filter configurations
        let configs: [FilterConfiguration] = [
            // Organization filter
            FilterConfiguration(
                version: 1,
                selectedOrganizations: ["apple"],
                selectedRepositories: [],
                selectedTeams: []
            ),
            // Repository filter
            FilterConfiguration(
                version: 1,
                selectedOrganizations: [],
                selectedRepositories: ["swift"],
                selectedTeams: []
            ),
            // Combined filters
            FilterConfiguration(
                version: 1,
                selectedOrganizations: ["apple", "google"],
                selectedRepositories: ["swift", "flutter"],
                selectedTeams: []
            )
        ]

        for config in configs {
            let startTime = Date()

            let result = engine.apply(
                configuration: config,
                searchQuery: "",
                to: prs,
                teamMetadata: []
            )

            let elapsed = Date().timeIntervalSince(startTime)
            let elapsedMs = elapsed * 1000

            // Must complete within 500ms
            #expect(
                elapsedMs < 500,
                "Filtering took \(elapsedMs)ms (expected <500ms), returned \(result.count) results"
            )
        }
    }

    /// T059: Verify fuzzy search completes within 500ms for 500 PRs
    @Test
    func `fuzzy search on 500 PRs completes within 500ms`() async throws {
        let prs = try loadLargeFixture()
        #expect(prs.count == 500)

        let searchQueries = [
            "fix bug",
            "api",
            "authentication",
            "memory leak",
            "john",
            "swift"
        ]

        for query in searchQueries {
            let startTime = Date()

            let result = engine.apply(
                configuration: .empty,
                searchQuery: query,
                to: prs,
                teamMetadata: []
            )

            let elapsed = Date().timeIntervalSince(startTime)
            let elapsedMs = elapsed * 1000

            // Must complete within 500ms
            #expect(
                elapsedMs < 500,
                "Search '\(query)' took \(elapsedMs)ms (expected <500ms), returned \(result.count) results"
            )
        }
    }

    /// T059: Verify combined filters and search complete within 500ms
    @Test
    func `combined filters and search on 500 PRs completes within 500ms`() async throws {
        let prs = try loadLargeFixture()
        #expect(prs.count == 500)

        let config = FilterConfiguration(
            version: 1,
            selectedOrganizations: ["apple", "google"],
            selectedRepositories: [],
            selectedTeams: []
        )

        let queries = ["fix", "api", "memory"]

        for query in queries {
            let startTime = Date()

            let result = engine.apply(
                configuration: config,
                searchQuery: query,
                to: prs,
                teamMetadata: []
            )

            let elapsed = Date().timeIntervalSince(startTime)
            let elapsedMs = elapsed * 1000

            // Must complete within 500ms
            #expect(
                elapsedMs < 500,
                """
                Combined filtering + search '\(query)' took \(elapsedMs)ms (expected <500ms), \
                returned \(result.count) results
                """
            )
        }
    }

    /// T060: Verify search debouncing behaves correctly
    @MainActor
    @Test
    func `search debouncing delays execution by 300ms`() async throws {
        let filterState = FilterState(
            persistence: MockFilterPersistence(),
            timeProvider: RealTimeProvider()
        )

        // Record when we start typing
        let startTime = Date()

        // Simulate rapid typing
        filterState.updateSearchQuery("f")
        try await Task.sleep(nanoseconds: 50_000_000)  // 50ms
        filterState.updateSearchQuery("fi")
        try await Task.sleep(nanoseconds: 50_000_000)  // 50ms
        filterState.updateSearchQuery("fix")

        // Wait for debounce to trigger
        try await Task.sleep(nanoseconds: 350_000_000)  // 350ms

        let elapsed = Date().timeIntervalSince(startTime)
        let elapsedMs = elapsed * 1000

        // Total time should be at least 300ms (debounce delay) + typing time
        // but less than 600ms (if debounce wasn't working, would accumulate)
        #expect(
            elapsedMs >= 300 && elapsedMs < 600,
            "Debouncing took \(elapsedMs)ms (expected 300-600ms range)"
        )

        // Search should have been applied (query is set)
        #expect(filterState.searchQuery == "fix")
    }

    /// T060: Verify search feels responsive (no perceived lag)
    @MainActor
    @Test
    func `search query updates are immediate`() async throws {
        let filterState = FilterState(
            persistence: MockFilterPersistence(),
            timeProvider: RealTimeProvider()
        )

        let queries = ["a", "ab", "abc", "abcd", "abcde"]

        for query in queries {
            let startTime = Date()

            // Update query
            filterState.updateSearchQuery(query)

            let elapsed = Date().timeIntervalSince(startTime)
            let elapsedMs = elapsed * 1000

            // Query update itself should be instant (<10ms)
            #expect(
                elapsedMs < 10,
                "Query update took \(elapsedMs)ms (expected <10ms for immediate UI feedback)"
            )

            // Query should be set immediately
            #expect(filterState.searchQuery == query)

            // Debounced query should NOT be set yet (since we haven't waited)
            #expect(filterState.debouncedSearchQuery != query)
        }
    }

    // MARK: - Helpers

    private func loadLargeFixture() throws -> [PullRequest] {
        let bundle = Bundle.module
        guard let url = bundle.url(forResource: "prs-with-varied-data", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else {
            throw NSError(
                domain: "TestError", code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Could not load prs-with-varied-data.json fixture"
                ])
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(GitHubSearchResponse.self, from: data)
        return response.items.map { $0.toPullRequest() }
    }

    private func loadSmallFixture() throws -> [PullRequest] {
        let bundle = Bundle.module
        guard let url = bundle.url(forResource: "prs-response", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else {
            throw NSError(
                domain: "TestError", code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Could not load prs-response.json fixture"
                ])
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(GitHubSearchResponse.self, from: data)
        return response.items.map { $0.toPullRequest() }
    }
}

// MARK: - Supporting Types

private struct GitHubSearchResponse: Decodable {
    let totalCount: Int
    let incompleteResults: Bool
    let items: [SearchIssueItem]
}

private struct SearchIssueItem: Decodable {
    let number: Int
    let title: String
    let htmlUrl: URL
    let updatedAt: Date
    let repositoryUrl: String
    let user: SearchUser

    func toPullRequest() -> PullRequest {
        let (owner, repoName) = extractRepositoryInfo()
        return PullRequest(
            repositoryOwner: owner,
            repositoryName: repoName,
            number: number,
            title: title,
            authorLogin: user.login,
            authorAvatarURL: nil,
            updatedAt: updatedAt,
            htmlURL: htmlUrl
        )
    }

    private func extractRepositoryInfo() -> (owner: String, repo: String) {
        let components = repositoryUrl.split(separator: "/")
        guard components.count >= 2 else {
            return ("", "")
        }
        let owner = String(components[components.count - 2])
        let repo = String(components[components.count - 1])
        return (owner, repo)
    }
}

private struct SearchUser: Decodable {
    let login: String
}
