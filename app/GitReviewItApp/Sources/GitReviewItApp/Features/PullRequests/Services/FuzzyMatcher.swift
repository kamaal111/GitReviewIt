//
//  FuzzyMatcher.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 23/12/2025.
//

import Foundation

/// Protocol for fuzzy matching and ranking pull requests by search relevance.
///
/// Fuzzy matching enables users to find PRs even with partial or misspelled queries.
/// Results are ranked by match quality, with exact matches ranked highest.
protocol FuzzyMatcherProtocol {
    /// Matches and ranks pull requests by search query relevance.
    ///
    /// - Parameters:
    ///   - query: The search query string
    ///   - pullRequests: PRs to search within
    /// - Returns: Matching PRs ranked by relevance (highest score first)
    func match(query: String, in pullRequests: [PullRequest]) -> [PullRequest]
}

/// Implementation of fuzzy matching with weighted field scoring.
///
/// **Scoring weights** (applied to match quality):
/// - Title: 3.0x (most important)
/// - Repository: 2.0x (medium importance)
/// - Author: 1.5x (least important)
///
/// **Match types** (descending quality):
/// 1. Exact match: score = 1.0
/// 2. Prefix match: score = 0.9
/// 3. Substring match: score = 0.7
/// 4. Fuzzy match (Levenshtein): score = similarity × 0.6 (if similarity > 0.3)
///
/// **Tie-breaking**: When scores are equal, PRs are ordered by PR number (ascending).
///
/// **Example**:
/// ```swift
/// let matcher = FuzzyMatcher()
/// let results = matcher.match(query: "fix bug", in: allPRs)
/// // Returns: PRs with "fix bug" in title ranked highest,
/// //          then PRs with "fix" or "bug" in repo/author,
/// //          sorted by match quality
/// ```
struct FuzzyMatcher: FuzzyMatcherProtocol {
    /// Matches PRs against query and returns them ranked by relevance.
    ///
    /// Searches across three fields with different weights:
    /// - PR title (weight: 3.0x)
    /// - Repository name (weight: 2.0x) - checks both full name and short name
    /// - Author login (weight: 1.5x)
    ///
    /// For each PR, the highest scoring field determines the overall score.
    /// PRs with very low scores are filtered out entirely.
    ///
    /// - Parameters:
    ///   - query: Search string (case-insensitive, whitespace-trimmed)
    ///   - pullRequests: PRs to search through
    /// - Returns: Matching PRs sorted by score (descending), then by PR number (ascending)
    ///
    /// - Note: Empty or whitespace-only queries return empty array.
    func match(query: String, in pullRequests: [PullRequest]) -> [PullRequest] {
        guard !query.isEmpty else { return [] }

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        /// Internal struct for tracking PRs with their computed relevance scores
        struct ScoredPR {
            let pr: PullRequest
            let score: Double
        }

        // Compute weighted scores for each PR
        let scoredPRs = pullRequests.compactMap { pr -> ScoredPR? in
            // Title matching (highest weight: 3.0x)
            let titleScore = calculateScore(text: pr.title, query: trimmedQuery) * 3.0

            // Repository matching (medium weight: 2.0x)
            // Check both "owner/repo" and "repo" for better matches
            let repoFullNameScore = calculateScore(text: pr.repositoryFullName, query: trimmedQuery)
            let repoNameScore = calculateScore(text: pr.repositoryName, query: trimmedQuery)
            let repoScore = max(repoFullNameScore, repoNameScore) * 2.0

            // Author matching (lowest weight: 1.5x)
            let authorScore = calculateScore(text: pr.authorLogin, query: trimmedQuery) * 1.5

            // Use the highest scoring field as the PR's overall score
            let maxScore = max(titleScore, repoScore, authorScore)

            // Filter out PRs with no meaningful match
            // A score of 0 means no match was found in any field
            guard maxScore > 0 else { return nil }

            return ScoredPR(pr: pr, score: maxScore)
        }

        // Sort by score descending, with deterministic tie-breaking by PR number
        let sorted = scoredPRs.sorted { (lhs, rhs) in
            // Use epsilon comparison for floating point scores
            if abs(lhs.score - rhs.score) > 0.001 {
                return lhs.score > rhs.score
            }
            // Tie-breaker: lower PR number first (older PRs)
            return lhs.pr.number < rhs.pr.number
        }

        return sorted.map { $0.pr }
    }

    /// Calculates match score between text and query.
    ///
    /// Returns scores based on match type:
    /// - 1.0: Exact match (case-insensitive)
    /// - 0.9: Prefix match
    /// - 0.7: Substring match
    /// - 0.0-0.6: Fuzzy match (Levenshtein similarity × 0.6, if similarity > 0.3)
    /// - 0.0: No match
    ///
    /// - Parameters:
    ///   - text: The text to search in (e.g., PR title)
    ///   - query: The search query
    /// - Returns: Match quality score from 0.0 to 1.0
    private func calculateScore(text: String, query: String) -> Double {
        // Case insensitive comparison
        let lowerText = text.localizedLowercase
        let lowerQuery = query.localizedLowercase

        if lowerText == lowerQuery {
            return 1.0  // Exact match
        }

        if lowerText.hasPrefix(lowerQuery) {
            return 0.9  // Prefix match
        }

        if lowerText.contains(lowerQuery) {
            return 0.7  // Substring match
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
