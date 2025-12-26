//
//  CheckForUpdatesButton.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 12/25/25.
//

import SwiftUI
import Sparkle

struct CheckForUpdatesButton: View {
    @ObservedObject private var checkForUpdatesService: CheckForUpdatesService

    private let updater: SPUUpdater

    init(updater: SPUUpdater) {
        self.updater = updater
        self.checkForUpdatesService = CheckForUpdatesService(updater: updater)
    }

    var body: some View {
        Button("Check for Updates…", action: updater.checkForUpdates)
            .disabled(!checkForUpdatesService.canCheckForUpdates)
    }
}

#Preview {
    let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    CheckForUpdatesButton(updater: updaterController.updater)
        .padding(.all, 16)
}
