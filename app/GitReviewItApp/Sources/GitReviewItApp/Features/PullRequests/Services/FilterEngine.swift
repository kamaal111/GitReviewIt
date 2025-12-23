//
//  FilterEngine.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 23/12/2025.
//

import Foundation

protocol FilterEngineProtocol {
    func apply(
        configuration: FilterConfiguration,
        searchQuery: String,
        to pullRequests: [PullRequest],
        teamMetadata: [Team]
    ) -> [PullRequest]
}
