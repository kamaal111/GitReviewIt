//
//  GitReviewItSelfUpdateService.swift
//  GitReviewItFeatures
//
//  Created by Kamaal M Farah on 12/26/25.
//

import Sparkle
import KamaalLogger

final class GitReviewItSelfUpdateService: ObservableObject {
    @Published private(set) var canCheckForUpdates = false

    private let updaterController: SPUStandardUpdaterController
    private let logger = KamaalLogger(from: GitReviewItSelfUpdateService.self, failOnError: true)

    convenience init() {
        let updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        self.init(updaterController: updaterController)
    }

    init(updaterController: SPUStandardUpdaterController) {
        self.updaterController = updaterController
        logger.debug("Init \(String(describing: Self.self))")

        updaterController.updater
            .publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    func checkForUpdates() {
        updaterController.updater.checkForUpdates()
    }
}
