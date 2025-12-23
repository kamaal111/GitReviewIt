//
//  StringSimilarity.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 23/12/2025.
//

import Foundation

enum StringSimilarity {
    /// Calculate Levenshtein distance between two strings
    static func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
        let s1 = Array(str1)
        let s2 = Array(str2)
        let m = s1.count
        let n = s2.count

        if m == 0 { return n }
        if n == 0 { return m }

        var d = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)

        for i in 0...m { d[i][0] = i }
        for j in 0...n { d[0][j] = j }

        for i in 1...m {
            for j in 1...n {
                let cost = s1[i - 1] == s2[j - 1] ? 0 : 1
                d[i][j] = min(
                    d[i - 1][j] + 1,      // deletion
                    d[i][j - 1] + 1,      // insertion
                    d[i - 1][j - 1] + cost // substitution
                )
            }
        }

        return d[m][n]
    }

    /// Calculate normalized similarity score (0.0 to 1.0)
    static func similarityScore(_ str1: String, _ str2: String) -> Double {
        if str1 == str2 { return 1.0 }
        if str1.isEmpty || str2.isEmpty { return 0.0 }

        let distance = levenshteinDistance(str1, str2)
        let maxLength = Double(max(str1.count, str2.count))

        return 1.0 - (Double(distance) / maxLength)
    }
}
