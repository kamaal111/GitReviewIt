# Default recipe - shows available commands
default:
    @just --list --unsorted

# Build the project for macOS
build:
    just app/build

# Clean and build the project
clean-build:
    just app/clean-build

# Run tests
test:
    just app/test

# Clean the build artifacts
clean:
    just app/clean

# Open the project in Xcode
open:
    just app/open

# Lint the code
lint:
    swiftlint lint --no-cache

# Bootstrap app for development
bootstrap:
    just app/bootstrap
