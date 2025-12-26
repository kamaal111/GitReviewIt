//
//  FuzzyMatcherTests.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 23/12/2025.
//

import Testing
import Foundation
@testable import GitReviewItAppPoc

@Suite("Fuzzy Matcher Tests")
struct FuzzyMatcherTests {
    private let matcher = FuzzyMatcher()
    private let now = Date()
    private let url = URL(string: "https://github.com")!

    @Test
    func `match returns exact matches with highest score`() {
        let pr1 = makePR(title: "Fix bug")
        let pr2 = makePR(title: "Other")
        let prs = [pr1, pr2]

        let results = matcher.match(query: "Fix bug", in: prs)

        #expect(results.count == 1)
        #expect(results.first?.title == "Fix bug")
    }

    @Test
    func `match returns prefix matches with high score`() {
        let pr1 = makePR(title: "Fixing things")
        let pr2 = makePR(title: "Other")
        let prs = [pr1, pr2]

        let results = matcher.match(query: "Fix", in: prs)

        #expect(results.count == 1)
        #expect(results.first?.title == "Fixing things")
    }

    @Test
    func `match returns substring matches with medium score`() {
        let pr1 = makePR(title: "Huge Fix here")
        let pr2 = makePR(title: "Other")
        let prs = [pr1, pr2]

        let results = matcher.match(query: "Fix", in: prs)

        #expect(results.count == 1)
        #expect(results.first?.title == "Huge Fix here")
    }

    @Test
    func `match handles typos with fuzzy scoring`() {
        let pr1 = makePR(title: "Fix bug")
        let pr2 = makePR(title: "Other")
        let prs = [pr1, pr2]

        let results = matcher.match(query: "Fux bug", in: prs)

        #expect(results.count == 1)
        #expect(results.first?.title == "Fix bug")
    }

    @Test
    func `match filters out PRs with no match`() {
        let pr1 = makePR(title: "Apples")
        let pr2 = makePR(title: "Bananas")
        let prs = [pr1, pr2]

        let results = matcher.match(query: "Oranges", in: prs)

        #expect(results.isEmpty)
    }

    @Test
    func `match tie-breaks by PR number when scores are equal`() {
        // Same title, different numbers. Expected order: ascending by number?
        // Wait, normally search results are sorted by relevance. If relevance is same?
        // Task says: "tie-breaking by PR number".
        // Usually lower number means older PR. Or maybe higher number means newer.
        // Spec or Plan says "tie-breaking by PR number ascending".
        // Let's assume ascending.

        let pr1 = makePR(number: 100, title: "Same Title")
        let pr2 = makePR(number: 200, title: "Same Title")
        let prs = [pr2, pr1]

        let results = matcher.match(query: "Same Title", in: prs)

        #expect(results.count == 2)
        #expect(results[0].number == 100)
        #expect(results[1].number == 200)
    }

    @Test
    func `match returns empty array for empty query`() {
        let pr1 = makePR(title: "Something")
        let results = matcher.match(query: "", in: [pr1])
        #expect(results.isEmpty)
    }

    @Test
    func `match prioritizes title over repo over author`() {
        // Title weight: 3.0, Repo: 2.0, Author: 1.5
        // "common" in title -> 3.0 * 1.0 = 3.0
        // "common" in repo -> 2.0 * 1.0 = 2.0
        // "common" in author -> 1.5 * 1.0 = 1.5

        let prTitle = makePR(number: 1, title: "common")
        let prRepo = makePR(repo: "common", number: 2)
        let prAuthor = makePR(number: 3, author: "common")
        let prs = [prRepo, prAuthor, prTitle]

        let results = matcher.match(query: "common", in: prs)

        #expect(results.count == 3)
        #expect(results[0].id == prTitle.id)
        #expect(results[1].id == prRepo.id)
        #expect(results[2].id == prAuthor.id)
    }

    // Helper
    private func makePR(
        repo: String = "repo",
        number: Int = 1,
        title: String = "Title",
        author: String = "author"
    ) -> PullRequest {
        PullRequest(
            repositoryOwner: "owner",
            repositoryName: repo,
            number: number,
            title: title,
            authorLogin: author,
            authorAvatarURL: nil,
            updatedAt: now,
            htmlURL: url
        )
    }
}
