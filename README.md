# GitReviewIt

GitReviewIt is a native macOS application built with SwiftUI that helps developers track GitHub Pull Requests waiting for their review. It supports both GitHub.com and GitHub Enterprise instances, providing a focused, native experience for code review management.

## Features

- **Personal Access Token Authentication**: Securely log in using GitHub PATs.
- **GitHub Enterprise Support**: Configurable API base URL for self-hosted GitHub instances.
- **Review Dashboard**: View a list of all Pull Requests where your review has been requested.
- **Rich PR Context**: Get immediate context before opening a PR:
  - **Size Preview**: See additions, deletions, and file counts to estimate review effort.
  - **Discussion Activity**: View total comment counts (issue + review comments) to gauge discussion complexity.
  - **Reviewer Status**: See both requested reviewers AND completed reviewers with their review states (Approved, Changes Requested, Commented).
  - **Labels**: View PR labels with their GitHub colors for quick categorization.
  - **Draft Status**: Clearly identify which PRs are still in draft state.
  - **CI/Check Status**: See at-a-glance status of CI checks (Passing, Failing, Pending, Unknown).
  - **Merge Conflicts**: Identify PRs with merge conflicts that need author attention.
- **PR Filtering**: Find PRs quickly with powerful filtering capabilities:
  - **Fuzzy Search**: Search by PR title, repository name, or author with intelligent ranking
  - **Organization Filter**: Filter by GitHub organization (persistent)
  - **Repository Filter**: Filter by specific repositories (persistent)
  - **Team Filter**: Filter by GitHub teams (when available with proper permissions)
  - **Combined Filtering**: Use search and structured filters together for precise results
- **Secure Storage**: Credentials are stored safely in the macOS Keychain.
- **Native Experience**: Built with SwiftUI for a fast, responsive macOS interface.
- **Direct Access**: Open PRs directly in your default browser with a single click.

## Getting Started

### Prerequisites

- macOS 14.0 or later
- Xcode 15.0 or later (for development)
- [Just](https://github.com/casey/just) (optional, for running task commands)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/GitReviewIt.git
   cd GitReviewIt
   ```

2. Open the project in Xcode:
   ```bash
   cd app && just open
   # OR
   open app/GitReviewIt.xcodeproj
   ```

3. Build and Run via Xcode.

## Usage

1. **Launch the App**: On first launch, you will be prompted to log in.
2. **Authenticate**:
   - Enter your GitHub Personal Access Token (PAT).
   - (Optional) Enter your GitHub Enterprise API URL if not using GitHub.com.
3. **View PRs**: Once authenticated, the app displays all PRs awaiting your review with rich context:
   - **Draft Badge**: PRs in draft state are clearly labeled
   - **Size Metrics**: Additions, deletions, and file count for each PR
   - **Comments**: Total comment count (issue + review comments)
   - **Reviewers**: Both requested reviewers and completed reviews with their states
   - **Labels**: PR labels with GitHub colors
   - **CI Status**: Check status (Passing/Failing/Pending)
   - **Merge Status**: Conflicts indicator when merge conflicts exist
4. **Filter PRs**:
   - **Search**: Type in the search box to find PRs by title, repository, or author. Results update as you type with intelligent ranking.
   - **Structured Filters**: Click the Filter button to open the filter sheet:
     - Select organizations to show only PRs from those orgs
     - Select repositories to narrow down to specific repos
     - Select teams (if available) to filter by team repositories
   - **Active Filters**: View and remove active filters using the filter chips displayed above the PR list.
   - **Clear All**: Use "Clear Filters" or "Clear All" to reset your selections.
5. **Refresh**: The list refreshes automatically on launch.
6. **Open PR**: Click any PR in the list to open it in your browser.

### Filter Persistence

Structured filters (organization, repository, team) are automatically saved and restored when you relaunch the app. Search queries are transient and do not persist across sessions.

## Development

The project is structured as a thin Xcode project wrapper around a local Swift Package (`GitReviewItApp`), which contains all the application logic, views, and tests.

### Common Commands

We use `just` to manage common development tasks. Run these commands from the `app/` directory:

- **Build**: Compile the project
  ```bash
  just build
  ```

- **Test**: Run the test suite
  ```bash
  just test
  ```

- **Clean Build**: Clean artifacts and rebuild
  ```bash
  just clean-build
  ```

- **Lint**: Check code style (requires SwiftLint)
  ```bash
  just lint
  ```

## License

This project is licensed under the MIT License.

