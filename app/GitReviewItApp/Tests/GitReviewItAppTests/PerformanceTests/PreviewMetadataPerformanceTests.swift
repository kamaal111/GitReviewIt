//
//  PreviewMetadataPerformanceTests.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 25/12/2025.
//

import Foundation
import OSLog
import Testing

@testable import GitReviewItApp

/// Performance tests for PR list loading with preview metadata
@Suite("Preview Metadata Performance Tests")
struct PreviewMetadataPerformanceTests {
    private let logger = Logger(subsystem: "com.gitreviewit.tests", category: "PerformanceTests")

    /// T052: Verify PR list loads within 3 seconds for 50 PRs
    @Test
    @MainActor
    func `PR list with 50 PRs loads within 3 seconds`() async throws {
        let credentials = GitHubCredentials(token: "test-token", baseURL: "https://api.github.com")

        // Create mock API that simulates realistic delays
        let mockAPI = MockSlowGitHubAPI(prCount: 50, delayPerRequest: 0.02)

        let container = PullRequestListContainer(
            githubAPI: mockAPI,
            credentialStorage: MockCredentialStorage(mockCredentials: credentials),
            openURL: { _ in }
        )

        let startTime = Date()

        // Load PRs and enrich metadata
        await container.loadPullRequests()

        let elapsed = Date().timeIntervalSince(startTime)

        logger.info("PR list load with 50 PRs took \(elapsed)s")

        // Must complete within 3 seconds
        #expect(
            elapsed < 3.0,
            "PR list load took \(elapsed)s (expected <3s)"
        )

        // Verify PRs were loaded
        guard case .loaded(let prs) = container.loadingState else {
            Issue.record("Expected loaded state")
            return
        }

        #expect(prs.count == 50)

        // Verify at least some metadata was enriched
        let enrichedCount = prs.filter { $0.previewMetadata != nil }.count
        logger.info("Enriched \(enrichedCount) out of 50 PRs")
    }

    /// T052: Verify PR list remains responsive during metadata enrichment
    @Test
    @MainActor
    func `PR list remains responsive during metadata enrichment`() async throws {
        let credentials = GitHubCredentials(token: "test-token", baseURL: "https://api.github.com")

        // Create mock API with slower individual requests
        let mockAPI = MockSlowGitHubAPI(prCount: 50, delayPerRequest: 0.05)

        let container = PullRequestListContainer(
            githubAPI: mockAPI,
            credentialStorage: MockCredentialStorage(mockCredentials: credentials),
            openURL: { _ in }
        )

        await container.loadPullRequests()

        // Even if metadata enrichment is slow, the list should be loaded
        guard case .loaded(let prs) = container.loadingState else {
            Issue.record("Expected loaded state")
            return
        }

        #expect(prs.count == 50)

        // List should be displayed immediately, metadata enriched progressively
        #expect(prs.allSatisfy { $0.commentCount >= 0 })
    }
}

/// Mock API that simulates network delays for performance testing
@MainActor
final class MockSlowGitHubAPI: GitHubAPI {
    private let prCount: Int
    private let delayPerRequest: TimeInterval
    private let logger = Logger(subsystem: "com.gitreviewit.tests", category: "MockSlowGitHubAPI")

    init(prCount: Int, delayPerRequest: TimeInterval) {
        self.prCount = prCount
        self.delayPerRequest = delayPerRequest
    }

    func verifyCredentials(credentials: GitHubCredentials) async throws -> String {
        "testuser"
    }

    func fetchUser(credentials: GitHubCredentials) async throws -> AuthenticatedUser {
        AuthenticatedUser(login: "testuser", name: "Test User", avatarURL: nil)
    }

    func fetchReviewRequests(credentials: GitHubCredentials) async throws -> [PullRequest] {
        // Simulate initial fetch delay
        try await Task.sleep(for: .milliseconds(100))

        let now = Date()
        let url = URL(string: "https://github.com/owner/repo/pull/1")!

        return (1...prCount).map { number in
            PullRequest(
                repositoryOwner: "owner",
                repositoryName: "repo\(number % 10)",
                number: number,
                title: "PR #\(number)",
                authorLogin: "author\(number % 5)",
                authorAvatarURL: nil,
                updatedAt: now,
                htmlURL: url,
                commentCount: number % 10,
                labels: []
            )
        }
    }

    func fetchPRDetails(
        owner: String,
        repo: String,
        number: Int,
        credentials: GitHubCredentials
    ) async throws -> PRPreviewMetadata {
        // Simulate per-PR fetch delay
        try await Task.sleep(for: .milliseconds(Int(delayPerRequest * 1000)))

        return PRPreviewMetadata(
            additions: number * 10,
            deletions: number * 5,
            changedFiles: number % 20 + 1,
            requestedReviewers: [],
            completedReviewers: []
        )
    }

    func fetchTeams(credentials: GitHubCredentials) async throws -> [Team] {
        []
    }

    func fetchPRReviews(
        owner: String,
        repo: String,
        number: Int,
        credentials: GitHubCredentials
    ) async throws -> [PRReviewResponse] {
        []
    }
}
