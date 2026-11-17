# 🚀 DevJournal — What To Do Next (Polish & Ship)

> This file outlines everything left to polish, fix, and push before the app is fully production-ready.

---

## ✅ Already Done
- [x] GitHub OAuth login flow (ASWebAuthenticationSession)
- [x] Real GitHub profile fetch (`/user` endpoint)
- [x] Real GitHub activity feed (`/users/{username}/events`)
- [x] Repository fetch (`/user/repos`)
- [x] Fixed HTTP/3 QUIC bug (simulator timeout)
- [x] Fixed CodingKeys + convertFromSnakeCase conflict
- [x] Fixed ARC deallocation of auth session
- [x] Session persistence via Keychain
- [x] HomeView duplicate modifiers removed
- [x] Login routes through GitHub OAuth only
- [x] All commits pushed to `main`

---

## 🔐 1. Security — Do This First

### Remove Hardcoded Client Secret
The GitHub OAuth client secret is currently hardcoded in `Configuration.swift`:

```swift
// ⚠️ BAD — remove this fallback before making repo private or sharing
static var gitHubClientSecret: String {
    ProcessInfo.processInfo.environment["GITHUB_CLIENT_SECRET"]
        ?? "d58b1daccf7516ad46e6d253b662bc31aeb907d6"  // ← DELETE THIS LINE
}
```

**Fix:** Set it only via Xcode scheme environment variable:
1. In Xcode → **Product → Scheme → Edit Scheme** (`⌘<`)
2. Run → Arguments → Environment Variables
3. Add: `GITHUB_CLIENT_SECRET` = your secret
4. Never commit the actual value

### Revoke the Exposed PAT Token
Your personal access token was shared in chat. Revoke it immediately:
👉 **https://github.com/settings/tokens**

---

## 🎨 2. UI Polish

### Home Screen
- [x] Show a **skeleton loader** while activities are fetching (replace `ProgressView()` spinner)
- [x] Add **pull-to-refresh** animation feedback (haptic)
- [x] Show **repo filter chips** at the top of the activity list
- [ ] Display **commit count badge** on each repo card
- [x] Show **real avatar** in header (it loads async — placeholder shimmer)
- [x] Replace hardcoded `"Good evening,"` with dynamic time-based greeting (morning/afternoon/evening)

### Landing & Login Screen
- [x] Remove the email/password fields entirely (the app only uses GitHub auth)
- [x] Make **"Continue with GitHub"** the only button — cleaner UX
- [x] Add a subtle loading indicator while OAuth is in progress

### Settings Screen
- [x] Show **GitHub username**, **follower count**, **public repo count** after login
- [x] Add **"Refresh GitHub Data"** button
- [x] Show **last synced** timestamp

---

## 🐛 3. Known Bugs to Fix

| Bug | Where | Priority |
|-----|-------|----------|
| `CoreData: Sandbox access denied` warning on launch | DevJournalApp.swift | Low |
| Activity list shows empty after login until manual refresh | HomeViewModel | Medium |
| `"Developer"` name shown briefly before profile loads | HomeView header | Medium |
| No error shown if GitHub token is expired/invalid | GitHubService | High |
| App crashes if SwiftData schema migration fails | ModelContainer | High |

### Fix "Developer" flash on load
In `HomeView.swift`, the header shows `"Developer"` until the async profile fetch finishes. Add a loading state:

```swift
// In HomeView header:
Text(appState.currentUser?.name ?? (gitHubAuth.isAuthenticated ? "" : "Developer"))
// Add a redacted shimmer while loading:
.redacted(reason: gitHubAuth.isAuthenticated && appState.currentUser == nil ? .placeholder : [])
```

### Handle expired tokens
In `GitHubService.swift`, when a 401 is returned, auto sign-out the user:

```swift
if http.statusCode == 401 {
    await MainActor.run { GitHubAuthService.shared.signOut() }
    throw GitHubError.unauthenticated
}
```

---

## ✨ 4. Features to Add

### Repo Selector Filter
- [ ] Let users **pin favourite repos** to always show at the top
- [ ] Save selected repos to `UserDefaults` so the filter persists across launches

### Activity Feed
- [ ] Add **infinite scroll** — load more events when scrolled to bottom
- [ ] Support more event types: `ReleaseEvent`, `GollumEvent`, `MemberEvent`
- [ ] Show **diff/patch** when tapping a commit

### Insights Tab
- [x] Show a **commits-per-day chart** (last 30 days) using Swift Charts
- [x] Show **most active repo** this week
- [x] Show **language breakdown** pie chart from repos

### Notifications
- [ ] Background refresh every 30 mins via `BGAppRefreshTask`
- [ ] Local notification when new activity is detected

---

## 🧹 5. Code Quality

- [ ] Remove all `print()` debug statements before release
- [ ] Add proper `os_log` / `Logger` calls instead
- [ ] Write unit tests for `GitHubService` using a mock `URLSession`
- [ ] Add `@MainActor` annotations where missing
- [ ] Remove unused imports and dead code

---

## 📦 6. Before Final Push / Demo

```bash
# 1. Clean build folder
⌘ + Shift + K in Xcode

# 2. Run on simulator — test full OAuth flow
⌘ + R

# 3. Check for warnings in Xcode issue navigator
⌘ + 5

# 4. Stage all changes
git add -A

# 5. Commit with a clear message
git commit -m "polish: UI improvements, bug fixes, security hardening"

# 6. Push
git push origin main
```

---

## 🎯 Priority Order for Tomorrow's Demo

1. 🔴 **Fix expired token handling** (401 → auto sign-out)
2. 🔴 **Remove hardcoded client secret**
3. 🟡 **Fix "Developer" name flash** (placeholder shimmer)
4. 🟡 **Remove email/password login fields**
5. 🟢 **Add commits-per-day chart** to Insights tab
6. 🟢 **Repo filter chips** on Home screen

---

*Last updated: 2026-11-17 | Branch: `main`*
