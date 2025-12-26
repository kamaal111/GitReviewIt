//
//  CommentCountBugTests.swift
//  GitReviewItApp
//
//  Created for bug fix: Review comments not counted in comment totals
//

import Foundation
import Testing

@testable import GitReviewItApp

/// Tests to reproduce and verify fix for comment count bug
///
/// Bug: Review comments (inline code comments) were not being counted
/// in the total comment count shown in the PR list. The count only
/// reflected issue comments from the PR conversation.
@Suite("Comment Count Bug Tests")
struct CommentCountBugTests {

    /// Test that reproduces the bug where review comments are not counted
    ///
    /// Scenario: A PR has 7 total comments (5 issue comments + 2 review comments)
    /// but the UI shows only 5 because review comments are not fetched/aggregated.
    @Test
    @MainActor
    func `comment count includes both issue and review comments`() async throws {
        // Setup: Mock HTTP client that returns PR details with issue comments
        // and review comments
        let mockHTTPClient = MockHTTPClient()
        let api = GitHubAPIClient(httpClient: mockHTTPClient)

        // Mock PR details response with 5 issue comments (from Search API)
        let prDetailsJSON = Data(
            """
            {
                "additions": 10,
                "deletions": 5,
                "changed_files": 3,
                "requested_reviewers": [],
                "head": {
                    "sha": "abc123"
                },
                "mergeable": true,
                "mergeable_state": "clean",
                "comments": 5
            }
            """.utf8)

        // Mock reviews response (empty, these are approval/changes_requested reviews)
        let reviewsJSON = Data(
            """
            []
            """.utf8)

        // Mock review comments response with 2 inline comments
        let reviewCommentsJSON = Data(
            """
            [
                {
                    "id": 1,
                    "user": {
                        "login": "reviewer1",
                        "avatar_url": "https://avatars.githubusercontent.com/u/1"
                    },
                    "body": "Please fix this",
                    "created_at": "2023-01-01T00:00:00Z"
                },
                {
                    "id": 2,
                    "user": {
                        "login": "currentuser",
                        "avatar_url": "https://avatars.githubusercontent.com/u/2"
                    },
                    "body": "Fixed",
                    "created_at": "2023-01-02T00:00:00Z"
                }
            ]
            """.utf8)

        // Mock check runs response
        let checkRunsJSON = Data(
            """
            {
                "total_count": 0,
                "check_runs": []
            }
            """.utf8)

        let credentials = GitHubCredentials(
            token: "test_token",
            baseURL: "https://api.github.com"
        )

        // Setup mock responses
        mockHTTPClient.setResponse(
            for: "https://api.github.com/repos/owner/repo/pulls/123",
            data: prDetailsJSON,
            statusCode: 200
        )
        mockHTTPClient.setResponse(
            for: "https://api.github.com/repos/owner/repo/pulls/123/reviews",
            data: reviewsJSON,
            statusCode: 200
        )
        mockHTTPClient.setResponse(
            for: "https://api.github.com/repos/owner/repo/pulls/123/comments",
            data: reviewCommentsJSON,
            statusCode: 200
        )
        mockHTTPClient.setResponse(
            for: "https://api.github.com/repos/owner/repo/commits/abc123/check-runs",
            data: checkRunsJSON,
            statusCode: 200
        )

        // Execute: Fetch PR details
        let metadata = try await api.fetchPRDetails(
            owner: "owner",
            repo: "repo",
            number: 123,
            credentials: credentials
        )

        // Verify: Total comment count should be 7 (5 issue + 2 review)
        // Currently fails because review comments are not fetched
        #expect(metadata.totalCommentCount == 7)
    }

    @Test
    @MainActor
    func `comment count is zero when no comments exist`() async throws {
        let mockHTTPClient = MockHTTPClient()
        let api = GitHubAPIClient(httpClient: mockHTTPClient)

        let prDetailsJSON = Data(
            """
            {
                "additions": 10,
                "deletions": 5,
                "changed_files": 3,
                "requested_reviewers": [],
                "head": {
                    "sha": "abc123"
                },
                "mergeable": true,
                "mergeable_state": "clean",
                "comments": 0
            }
            """.utf8)

        let reviewsJSON = Data("[]".utf8)
        let reviewCommentsJSON = Data("[]".utf8)
        let checkRunsJSON = Data(
            """
            {
                "total_count": 0,
                "check_runs": []
            }
            """.utf8)

        let credentials = GitHubCredentials(
            token: "test_token",
            baseURL: "https://api.github.com"
        )

        mockHTTPClient.setResponse(
            for: "https://api.github.com/repos/owner/repo/pulls/456",
            data: prDetailsJSON,
            statusCode: 200
        )
        mockHTTPClient.setResponse(
            for: "https://api.github.com/repos/owner/repo/pulls/456/reviews",
            data: reviewsJSON,
            statusCode: 200
        )
        mockHTTPClient.setResponse(
            for: "https://api.github.com/repos/owner/repo/pulls/456/comments",
            data: reviewCommentsJSON,
            statusCode: 200
        )
        mockHTTPClient.setResponse(
            for: "https://api.github.com/repos/owner/repo/commits/abc123/check-runs",
            data: checkRunsJSON,
            statusCode: 200
        )

        let metadata = try await api.fetchPRDetails(
            owner: "owner",
            repo: "repo",
            number: 456,
            credentials: credentials
        )

        #expect(metadata.totalCommentCount == 0)
    }

    @Test
    @MainActor
    func `comment count includes only review comments when no issue comments`() async throws {
        let mockHTTPClient = MockHTTPClient()
        let api = GitHubAPIClient(httpClient: mockHTTPClient)

        // 0 issue comments but 3 review comments
        let prDetailsJSON = Data(
            """
            {
                "additions": 10,
                "deletions": 5,
                "changed_files": 3,
                "requested_reviewers": [],
                "head": {
                    "sha": "abc123"
                },
                "mergeable": true,
                "mergeable_state": "clean",
                "comments": 0
            }
            """.utf8)

        let reviewsJSON = Data("[]".utf8)
        let reviewCommentsJSON = Data(
            """
            [
                {
                    "id": 1,
                    "user": {"login": "user1", "avatar_url": null},
                    "body": "Comment 1",
                    "created_at": "2023-01-01T00:00:00Z"
                },
                {
                    "id": 2,
                    "user": {"login": "user2", "avatar_url": null},
                    "body": "Comment 2",
                    "created_at": "2023-01-02T00:00:00Z"
                },
                {
                    "id": 3,
                    "user": {"login": "user3", "avatar_url": null},
                    "body": "Comment 3",
                    "created_at": "2023-01-03T00:00:00Z"
                }
            ]
            """.utf8)
        let checkRunsJSON = Data(
            """
            {
                "total_count": 0,
                "check_runs": []
            }
            """.utf8)

        let credentials = GitHubCredentials(
            token: "test_token",
            baseURL: "https://api.github.com"
        )

        mockHTTPClient.setResponse(
            for: "https://api.github.com/repos/owner/repo/pulls/789",
            data: prDetailsJSON,
            statusCode: 200
        )
        mockHTTPClient.setResponse(
            for: "https://api.github.com/repos/owner/repo/pulls/789/reviews",
            data: reviewsJSON,
            statusCode: 200
        )
        mockHTTPClient.setResponse(
            for: "https://api.github.com/repos/owner/repo/pulls/789/comments",
            data: reviewCommentsJSON,
            statusCode: 200
        )
        mockHTTPClient.setResponse(
            for: "https://api.github.com/repos/owner/repo/commits/abc123/check-runs",
            data: checkRunsJSON,
            statusCode: 200
        )

        let metadata = try await api.fetchPRDetails(
            owner: "owner",
            repo: "repo",
            number: 789,
            credentials: credentials
        )

        #expect(metadata.totalCommentCount == 3)
    }
}
