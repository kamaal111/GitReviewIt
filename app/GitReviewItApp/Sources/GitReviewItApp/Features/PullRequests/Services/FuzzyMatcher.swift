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
