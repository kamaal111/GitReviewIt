//
//  GitReviewItSelfUpdate.swift
//  GitReviewItFeatures
//
//  Created by Kamaal M Farah on 12/26/25.
//

import SwiftUI

extension Scene {
    public func withSelfUpdateCommand() -> some Scene {
        let service = GitReviewItSelfUpdateService()

        return self
            .commands {
                CommandGroup(after: .appInfo) {
                    CheckForUpdatesButton(service: service)
                }
            }
    }
}
