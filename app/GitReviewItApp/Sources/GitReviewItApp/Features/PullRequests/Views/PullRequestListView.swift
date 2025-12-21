import SwiftUI

/// Displays a list of pull requests awaiting the user's review.
/// This is a placeholder view that will be fully implemented in User Story 2.
struct PullRequestListView: View {
    var body: some View {
        VStack {
            Text("Pull Requests")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Coming soon...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    PullRequestListView()
}
