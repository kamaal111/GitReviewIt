//
//  StringSimilarityTests.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 23/12/2025.
//

import Testing
@testable import GitReviewItAppPoc

@Suite("String Similarity Tests")
struct StringSimilarityTests {
    @Test
    func `levenshteinDistance matches known values for standard test pairs`() {
        #expect(StringSimilarity.levenshteinDistance("kitten", "sitting") == 3)
        #expect(StringSimilarity.levenshteinDistance("book", "back") == 2)
        #expect(StringSimilarity.levenshteinDistance("sunday", "saturday") == 3)
    }

    @Test
    func `levenshteinDistance returns 0 for identical strings`() {
        #expect(StringSimilarity.levenshteinDistance("hello", "hello") == 0)
        #expect(StringSimilarity.levenshteinDistance("", "") == 0)
    }

    @Test
    func `levenshteinDistance returns length for completely different strings`() {
        #expect(StringSimilarity.levenshteinDistance("abc", "") == 3)
        #expect(StringSimilarity.levenshteinDistance("", "abc") == 3)
    }

    @Test
    func `similarityScore returns 1.0 for identical strings`() {
        #expect(StringSimilarity.similarityScore("test", "test") == 1.0)
    }

    @Test
    func `similarityScore returns values between 0.0 and 1.0`() {
        let score = StringSimilarity.similarityScore("kitten", "sitting")
        // distance is 3, max length is 7. Score = 1 - 3/7 = 4/7 ~= 0.57
        #expect(score > 0.5 && score < 0.6)
    }

    @Test
    func `similarityScore returns 0.0 for empty vs non-empty`() {
        #expect(StringSimilarity.similarityScore("", "test") == 0.0)
        #expect(StringSimilarity.similarityScore("test", "") == 0.0)
    }
}
