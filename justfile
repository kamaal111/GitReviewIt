# Default recipe - shows available commands
default:
    @just --list

# Build the project for macOS
build:
    just app/build

# Run tests
test:
    just app/test

# Lint the code
lint:
    swiftlint lint --no-cache
