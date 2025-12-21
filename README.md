# GitReviewIt

GitReviewIt is a native macOS application built with SwiftUI that helps developers track GitHub Pull Requests waiting for their review. It supports both GitHub.com and GitHub Enterprise instances, providing a focused, native experience for code review management.

## Features

- **Personal Access Token Authentication**: Securely log in using GitHub PATs.
- **GitHub Enterprise Support**: Configurable API base URL for self-hosted GitHub instances.
- **Review Dashboard**: View a list of all Pull Requests where your review has been requested.
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
3. **View PRs**: Once authenticated, the app will display a list of PRs awaiting your review.
4. **Refresh**: The list refreshes automatically on launch.
5. **Open PR**: Click any PR in the list to open it in your browser.

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

