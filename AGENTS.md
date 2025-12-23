# Repository Guidelines

## Project Structure & Module Organization
- App Code: `app/` folder contains the macOS SwiftUI app
  - Swift Package: `app/GitReviewItApp/` contains all source code as a Swift Package
  - Sources: `app/GitReviewItApp/Sources/GitReviewItApp/` for app code (`GitReviewItApp.swift`, `ContentView.swift`)
  - Tests: `app/GitReviewItApp/Tests/GitReviewItAppTests/` for test code
  - Xcode Project: `app/GitReviewIt.xcodeproj/` manages build settings
- Future Server: Root-level `server/` can be added later for OAuth proxy or backend services
- Automation & Specs: `.github/` (agents/prompts), `.specify/` (templates), and `specs/` (feature specs) support planning and review workflows.

## Build, Test, and Development Commands
- **Justfile Available**: Use `just` to run common build commands from `app/` folder. See `just --list` for all available commands.
- Quick build: `cd app && just build` (compiles the app).
- Clean build: `cd app && just clean-build` (removes artifacts and compiles fresh).
- Run tests: `cd app && just test` (when tests exist).
- Open in Xcode: `cd app && just open` or `open app/GitReviewIt.xcodeproj` (build and run with the default scheme).
- CLI build (manual): `cd app && xcodebuild -project GitReviewIt.xcodeproj -scheme GitReviewIt -destination 'platform=macOS' build` (compiles the app).
- CLI tests (manual): `cd app && xcodebuild -project GitReviewIt.xcodeproj -scheme GitReviewIt -destination 'platform=macOS' test`.
- **Swift Package**: All code is in a Swift Package, so no manual target management needed - just add files to the package.

## Coding Style & Naming Conventions
- Language: Swift (SwiftUI). Use 4-space indentation and limit line length to ~120 chars.
- Names: PascalCase for types, camelCase for variables/functions, SCREAMING_SNAKE_CASE for constants.
- Files: One primary type per file; filename matches type name.
- Architecture: Prefer MVVM for features; keep views declarative and business logic in view models/services.
- Control Flow: Avoid nesting by using `guard` statements and early exits wherever possible. Each `guard` statement must hold only one condition. This improves readability and prevents linting/formatting conflicts with multi-line conditions.
- Imports: Keep UI separated from domain logic; avoid unnecessary cross-layer dependencies.
- **Swift Concurrency**: Project uses Swift 6 with strict concurrency checking enabled:
  - NEVER use `nonisolated(unsafe)` in production code - it disables Swift's data race safety guarantees
  - Use proper actor isolation (`@MainActor`, `actor`) to protect shared mutable state
  - For UI components and AppKit/UIKit types, use `@MainActor` since they must run on the main thread
  - Mark protocols with `Sendable` when they cross actor boundaries
  - Prefer `async/await` over completion handlers for asynchronous operations

## Testing Guidelines
- Framework: Swift Testing (using `@Test` attribute). Tests are in the Swift Package at `app/GitReviewItApp/Tests/GitReviewItAppTests/`.
- **Test Syntax**: Use backtick function names for readable test descriptions:
  ```swift
  @Test
  func `User response fixture decodes to AuthenticatedUser`() throws {
      // test implementation
  }
  ```
  - **DO**: Use `@Test` with backtick function names containing spaces and natural language
  - **DON'T**: Use `@Test("description")` with separate function names like `testSomething()`
  - Benefits: More readable test names in results, eliminates redundant naming, clearer intent
- **No Conditional Logic**: Tests must be linear and declarative.
  - **NEVER** use `if`, `guard`, `switch`, or `if case` statements to verify outcomes. Conditional test logic hides failures and makes tests hard to read.
  - **ALWAYS** use `#expect` directly with equality checks to assert state.
  - If a type is an enum with associated values, ensure it conforms to `Equatable` so you can compare it directly: `#expect(state == .loaded(value))`.
  - If conditional logic seems necessary, the test or the type's `Equatable` conformance likely needs refactoring. Tests should read like documentation.
- Naming: Test structs use `FeatureNameTests` format (e.g., `FixtureTests`, `AuthenticationTests`)
- Scope: Focus on view models and pure logic; UI verified via snapshots or previews as needed.
- Running: From Xcode's Test action, via `just test`, or the CLI command above.
- **No manual target setup needed**: Swift Package manages test targets automatically.

## Commit & Pull Request Guidelines
- Commits: Write imperative, scoped messages (e.g., `Add commit list view`). Keep changes focused and incremental.
- PRs: Include clear description, linked issues, and screenshots for UI changes. Add testing notes and risk assessment for non-trivial changes.
- Reviews: Address comments with follow-up commits; avoid force-push after reviews start unless requested.

## Security & Configuration Tips
- Secrets: Do not commit tokens or credentials. Store GitHub Personal Access Tokens securely in macOS Keychain.
- Authentication: App uses Personal Access Token approach (not OAuth) for maximum flexibility with GitHub Enterprise.
- GitHub Enterprise Support: Users can specify custom API base URLs (e.g., `https://github.company.com/api/v3`) for self-hosted instances.
- Info.plist is generated by the project; prefer build settings over manual plist edits where possible.

## Agent-Specific Notes
- **MANDATORY**: Before completing any task that involves code changes, YOU MUST RUN `cd app && just test` to verify that the project builds and all tests pass. Fix any errors before proceeding.
- **MANDATORY**: Run `just lint` to check for style violations and fix them before finishing your task. Ensure that `just lint` succeeds (no warnings or errors).
- The repository ships with Speckit prompts/templates (`.github`, `.specify`). Keep templates intact; add feature specs/plans under the provided structure when expanding the app.

