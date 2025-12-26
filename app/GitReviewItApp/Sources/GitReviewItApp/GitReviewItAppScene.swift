//
//  GitReviewItAppScene.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 12/26/25.
//

import Sparkle
import SwiftUI

public struct GitReviewItAppScene: Scene {
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    public init() { }

    public var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
