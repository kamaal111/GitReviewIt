# GitReviewIt Build Commands
# Run with: just <command>

# Default recipe - shows available commands
default:
    @just --list

# Build the project for macOS
build:
    xcodebuild -project GitReviewIt.xcodeproj -scheme GitReviewIt -destination 'platform=macOS' build

# Clean and build the project
clean-build:
    xcodebuild -project GitReviewIt.xcodeproj -scheme GitReviewIt -destination 'platform=macOS' clean build

# Run tests (when tests are implemented)
test:
    xcodebuild -project GitReviewIt.xcodeproj -scheme GitReviewIt -destination 'platform=macOS' test

# Clean the build artifacts
clean:
    xcodebuild -project GitReviewIt.xcodeproj -scheme GitReviewIt -destination 'platform=macOS' clean

# Open the project in Xcode
open:
    open GitReviewIt.xcodeproj

# Run the app (build and launch)
run: build
    open /Users/kamaal/Library/Developer/Xcode/DerivedData/GitReviewIt-*/Build/Products/Debug/GitReviewIt.app

# Check for syntax errors without building
check:
    xcodebuild -project GitReviewIt.xcodeproj -scheme GitReviewIt -destination 'platform=macOS' -dry-run build
