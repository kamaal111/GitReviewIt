//
//  GitReviewItAppPocScene.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 12/21/25.
//

import SwiftUI
import GitReviewItSelfUpdate

/// The main scene for the GitReviewIt application
public struct GitReviewItAppPocScene: Scene {
    /// Creates a new instance of the app scene
    public init() {}

    public var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .withSelfUpdateCommand()
    }
}
