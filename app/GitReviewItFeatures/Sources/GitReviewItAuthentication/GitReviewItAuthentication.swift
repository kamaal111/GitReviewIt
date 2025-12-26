//
//  GitReviewItAuthentication.swift
//  GitReviewItFeatures
//
//  Created by Kamaal M Farah on 12/26/25.
//

import SwiftUI

extension View {
    public func withAuth() -> some View {
        modifier(GitReviewItAuthenticationModifier())
    }
}

private struct GitReviewItAuthenticationModifier: ViewModifier {
    @State private var servive = GitReviewItAuthenticationService()

    func body(content: Content) -> some View {
        content
    }
}
