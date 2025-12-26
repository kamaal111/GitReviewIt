//
//  GitReviewItAuthenticationService.swift
//  GitReviewItFeatures
//
//  Created by Kamaal M Farah on 12/26/25.
//

import Observation
import KamaalLogger

@Observable
final class GitReviewItAuthenticationService {
    private let logger = KamaalLogger(from: GitReviewItAuthenticationService.self, failOnError: true)

    init() {
        logger.debug("Init \(String(describing: Self.self))")
    }
}
