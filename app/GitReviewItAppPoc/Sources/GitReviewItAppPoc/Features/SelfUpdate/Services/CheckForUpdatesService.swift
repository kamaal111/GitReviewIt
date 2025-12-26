//
//  CheckForUpdatesService.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 12/25/25.
//

import Sparkle

final class CheckForUpdatesService: ObservableObject {
    @Published private(set) var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        updater
            .publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}
