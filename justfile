# Default recipe - shows available commands
default:
    @just --list --unsorted

# Build a signed .pkg for distribution (runs `app/create-pkg`)
create-pkg:
    just app/create-pkg

# Build and export the macOS `.app` (runs `app/create-app`)
create-app:
    just app/create-app

# Publish the web package (delegates to `web/publish`)
publish:
    just web/publish

# Run the test suite (delegates to `app/test`)
test:
    just app/test

# Clean build artifacts (delegates to `app/clean`)
clean:
    just app/clean

# Open the Xcode project (delegates to `app/open`)
open:
    just app/open

# Run linters and style checks (delegates to `app/lint`)
lint:
    just app/lint

# Generate Sparkle update keys for app signing (delegates to `app/generate-sparkle-keys`)
generate-sparkle-keys:
    just app/generate-sparkle-keys

# Bootstrap app and web for development
bootstrap:
    just app/bootstrap
    just web/bootstrap
