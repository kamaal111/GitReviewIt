//
//  GitReviewItAppScene.swift
//  GitReviewItApp
//
//  Created by Kamaal M Farah on 12/26/25.
//

import SwiftUI
import GitReviewItSelfUpdate

public struct GitReviewItAppScene: Scene {
    public init() { }

    public var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .withSelfUpdateCommand()
    }
}
