PROJECT_FILE := "app/GitReviewIt.xcodeproj/project.pbxproj"
APP_PATH := "app/out/GitReviewIt.app"

# Default recipe - shows available commands
default:
    @just --list --unsorted

# Build a signed .pkg for distribution (runs `app/create-pkg`)
create-pkg:
    just app/create-pkg

# Build and export the macOS `.app` (runs `app/create-app`)
create-app:
    just app/create-app

# Publish: ensure GitHub release exists, then publish web package
publish: ensure-github-release web-publish

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

# Auto-fix linting issues (delegates to `app/lint-fix`)
lint-fix:
    just app/lint-fix

# Generate Sparkle update keys for app signing (delegates to `app/generate-sparkle-keys`)
generate-sparkle-keys:
    just app/generate-sparkle-keys

# Store NotaryTool credentials for Apple notarization (delegates to `app/create-notary-profile`)
create-notary-profile:
    just app/create-notary-profile

# Bump app version and build number in Xcode project (delegates to `app/bump-version`)
bump-version app_version build_number:
    just app/bump-version {{ app_version }} {{ build_number }}

# Bootstrap app and web for development
bootstrap:
    just app/bootstrap
    just web/bootstrap

[private]
web-publish:
    just web/publish

[private]
ensure-github-release: verify-gh-cli verify-repository-state
    #!/bin/zsh

    set -e

    PROJECT_VERSION=$(just get-project-version)

    just check-release-exists "$PROJECT_VERSION"
    just ensure-pkg-built "$PROJECT_VERSION"
    just create-github-release "$PROJECT_VERSION"

[private]
verify-gh-cli:
    #!/bin/zsh
    if ! command -v gh &> /dev/null
    then
        echo "❌ GitHub CLI (gh) is not installed. Install it with: brew install gh"
        exit 1
    fi

[private]
get-project-version:
    #!/bin/zsh
    project_version=$(grep -m 1 "MARKETING_VERSION" {{ PROJECT_FILE }} | sed -E 's/.*MARKETING_VERSION = ([^;]+);/\1/')
    if [[ -z "$project_version" ]]
    then
        echo "❌ Could not extract version from Xcode project" >&2
        exit 1
    fi
    echo "📋 Xcode project version: $project_version" >&2
    echo "$project_version"

[private]
verify-repository-state:
    #!/bin/zsh
    set -e
    echo "🔍 Verifying repository state..."
    
    # Check for uncommitted changes
    if [[ -n $(git status --porcelain) ]]
    then
        echo "❌ Uncommitted changes detected. Commit or stash changes before publishing."
        exit 1
    fi
    
    # Fetch latest from origin
    git fetch origin main
    
    # Check if local main is in sync with origin/main
    LOCAL=$(git rev-parse main)
    REMOTE=$(git rev-parse origin/main)
    
    if [[ "$LOCAL" != "$REMOTE" ]]
    then
        echo "❌ Local main branch is out of sync with origin/main"
        echo "   Local:  $LOCAL"
        echo "   Remote: $REMOTE"
        echo "💡 Run 'git pull' or 'git push' to sync before publishing"
        exit 1
    fi
    
    echo "✅ Repository state verified - local matches origin/main"

[private]
check-release-exists version:
    #!/bin/zsh
    version="{{ version }}"
    if gh release view "$version" &> /dev/null
    then
        echo "⚠️  Release v$version already exists on GitHub - nothing to publish"
        exit 1
    fi

[private]
ensure-pkg-built version:
    #!/bin/zsh
    set -e
    project_version="{{ version }}"
    needs_rebuild=false
    
    if [[ ! -d {{ APP_PATH }} ]]
    then
        echo "⚠️  Built app not found - needs initial build"
        needs_rebuild=true
    else
        built_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "{{ APP_PATH }}/Contents/Info.plist")
        echo "📦 Built app version: $built_version"
        
        if [[ "$built_version" != "$project_version" ]]
        then
            echo "⚠️  Version mismatch - built app ($built_version) != project ($project_version)"
            needs_rebuild=true
        fi
    fi
    
    if [[ "$needs_rebuild" == "true" ]]
    then
        echo "🔨 Building new package for version $project_version..."
        just create-pkg
    fi

[private]
create-github-release version:
    #!/bin/zsh
    set -e
    project_version="{{ version }}"
    
    echo "🚀 Creating GitHub release for version v$project_version..."
    
    # Find the .pkg file
    pkg_file="app/out/GitReviewIt.pkg"
    if [[ ! -f "$pkg_file" ]]
    then
        echo "❌ PKG file not found at: $pkg_file"
        exit 1
    fi
    
    # Create the release with auto-generated notes (creates tag from main branch)
    gh release create "$project_version" \
        "$pkg_file" \
        --title "v$project_version" \
        --generate-notes \
        --target main
    
    echo "✅ Successfully created release v$project_version"
