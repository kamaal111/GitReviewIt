//
//  GitReviewItAppPocScene.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 12/21/25.
//

import Sparkle
import SwiftUI

/// The main scene for the GitReviewIt application
public struct GitReviewItAppPocScene: Scene {
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    /// Creates a new instance of the app scene
    public init() {}

    public var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesButton(updater: updaterController.updater)
            }
        }
    }
}
