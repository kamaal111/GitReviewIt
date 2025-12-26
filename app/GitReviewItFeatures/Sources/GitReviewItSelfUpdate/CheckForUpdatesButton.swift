//
//  CheckForUpdatesButton.swift
//  GitReviewItFeatures
//
//  Created by Kamaal M Farah on 12/26/25.
//

import SwiftUI
import Sparkle

struct CheckForUpdatesButton: View {
    @ObservedObject private var service: GitReviewItSelfUpdateService

    init(service: GitReviewItSelfUpdateService) {
        self.service = service
    }

    var body: some View {
        Button("Check for Updates…", action: service.checkForUpdates)
            .disabled(!service.canCheckForUpdates)
    }
}

#Preview {
    let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )
    let service = GitReviewItSelfUpdateService(updaterController: updaterController)

    CheckForUpdatesButton(service: service)
        .padding(.all, 16)
}
