# Human Help Needed

Quick actions that require Xcode or manual configuration:

## 1. Info.plist Configuration (Task T002)

**When**: Before implementing OAuth (Phase 3)

```xml
Add to Info.plist:

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>gitreviewit</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.gitreviewit.oauth</string>
    </dict>
</array>
```

**How**: Xcode → Target → Info tab → URL Types → Add `gitreviewit://`

---

## 2. Add Test Target (After T042)

**When**: After creating first test file `AuthenticationFlowTests.swift`

**How**: 
1. Xcode → File → New → Target
2. Choose "Unit Testing Bundle"
3. Name: `GitReviewItTests`
4. Add test files to this target

---

## 3. Configure Test Scheme (After T042)

**When**: After test target exists

**How**:
1. Xcode → Product → Scheme → Edit Scheme
2. Test tab → Add `GitReviewItTests` target
3. Enable tests for ⌘U

---

## 4. Add GitHub OAuth Credentials (Task T023)

**When**: Before running OAuth flow

Create: `GitReviewIt/Infrastructure/OAuth/GitHubOAuthConfig.swift`

```swift
enum GitHubOAuthConfig {
    static let clientId = "YOUR_GITHUB_CLIENT_ID"
    static let clientSecret = "YOUR_GITHUB_CLIENT_SECRET"
    static let callbackURLScheme = "gitreviewit"
    static let scopes = ["repo"]
}
```

**Get credentials**: https://github.com/settings/developers → New OAuth App

---

## 5. Add App Capabilities (If Needed)

**When**: If keychain access issues occur

**How**: Xcode → Target → Signing & Capabilities → Add Keychain Sharing

---

That's it! I'll handle the rest. 🚀
