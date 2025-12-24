//
//  FuzzyMatcher.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 23/12/2025.
//

import Foundation

protocol FuzzyMatcherProtocol {
    func match(query: String, in pullRequests: [PullRequest]) -> [PullRequest]
}

struct FuzzyMatcher: FuzzyMatcherProtocol {
    func match(query: String, in pullRequests: [PullRequest]) -> [PullRequest] {
        guard !query.isEmpty else { return [] }

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        struct ScoredPR {
            let pr: PullRequest
            let score: Double
        }

        let scoredPRs = pullRequests.compactMap { pr -> ScoredPR? in
            let titleScore = calculateScore(text: pr.title, query: trimmedQuery) * 3.0

            // Check both full name and just repo name
            let repoFullNameScore = calculateScore(text: pr.repositoryFullName, query: trimmedQuery)
            let repoNameScore = calculateScore(text: pr.repositoryName, query: trimmedQuery)
            let repoScore = max(repoFullNameScore, repoNameScore) * 2.0

            let authorScore = calculateScore(text: pr.authorLogin, query: trimmedQuery) * 1.5

            let maxScore = max(titleScore, repoScore, authorScore)

            // Filter out weak matches
            // If raw score (before weight) was 0, weighted is 0.
            // If raw score was fuzzy (e.g. 0.3 * 0.6 = 0.18) * weight.
            // Let's say minimum acceptable weighted score is > 0.
            guard maxScore > 0 else { return nil }

            return ScoredPR(pr: pr, score: maxScore)
        }

        let sorted = scoredPRs.sorted { (lhs, rhs) in
            if abs(lhs.score - rhs.score) > 0.001 {
                return lhs.score > rhs.score
            }
            return lhs.pr.number < rhs.pr.number
        }

        return sorted.map { $0.pr }
    }

    private func calculateScore(text: String, query: String) -> Double {
        // Case insensitive comparison
        let lowerText = text.localizedLowercase
        let lowerQuery = query.localizedLowercase

        if lowerText == lowerQuery {
            return 1.0 // Exact match
        }

        if lowerText.hasPrefix(lowerQuery) {
            return 0.9 // Prefix match
        }

        if lowerText.contains(lowerQuery) {
            return 0.7 // Substring match
        }

        // Fuzzy match
        let similarity = StringSimilarity.similarityScore(lowerText, lowerQuery)
        // Only consider fuzzy matches that are somewhat similar
        if similarity > 0.3 {
            return similarity * 0.6
        }

        return 0.0
    }
}
