//
//  GitReviewItApp.swift
//  GitReviewIt
//
//  Created by Kamaal M Farah on 12/20/25.
//

import SwiftUI
import GitReviewItApp
import GitReviewItAppPoc

@main
struct GitReviewItApp: App {
    var body: some Scene {
        #if DEBUG
        GitReviewItAppScene()
        #else
        GitReviewItAppPocScene()
        #endif
    }
}
