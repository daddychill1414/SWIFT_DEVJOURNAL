# DevJournal — Complete Application Documentation

A comprehensive reference covering every feature, integration, and architectural decision in the DevJournal iOS application.

---

## Table of Contents

1. [Application Overview](#application-overview)
2. [Technical Architecture](#technical-architecture)
3. [GitHub OAuth 2.0 Integration](#github-oauth-20-integration)
4. [GitHub REST API Service](#github-rest-api-service)
5. [Supabase Cloud Synchronization](#supabase-cloud-synchronization)
6. [Data Persistence with SwiftData](#data-persistence-with-swiftdata)
7. [Security — Keychain Token Storage](#security--keychain-token-storage)
8. [Views & Navigation Architecture](#views--navigation-architecture)
9. [Configuration & Environment Secrets](#configuration--environment-secrets)
10. [Project Structure](#project-structure)
11. [Build & Run Instructions](#build--run-instructions)
12. [Recent Changes Summary](#recent-changes-summary)
13. [Remaining Roadmap](#remaining-roadmap)

---

## Application Overview

DevJournal is a native iOS productivity application built entirely in Swift and SwiftUI. It is designed for developers who want to track their coding sessions, manage project portfolios, analyze productivity patterns, and synchronize everything with GitHub and Supabase.

### Core Capabilities

| Feature | Description |
|---|---|
| **Dashboard Home** | Real-time progress ring, focus time tracker, completed task count, live GitHub activity feed |
| **Journal Logs** | Structured developer journal entries with mood selector, focus level, hours spent, tags, and repo linking |
| **Projects Portfolio** | Active/Archived/Starred project classification with commit, PR, issue, and star metrics |
| **Productivity Insights** | Weekly focus time bar charts (Swift Charts), dynamically computed productivity score, and data-driven developer insights |
| **Settings** | Dark/Light/System theme toggle, GitHub OAuth connection, Supabase sync controls |

### Design Language

- Inspired by Apple visionOS glassmorphism and Human Interface Guidelines
- `ultraThinMaterial` glass cards with soft stroke overlays
- Gradient-filled progress rings and capsule-shaped interactive elements
- Atmospheric animated background with floating gradient orbs

---

## Technical Architecture

```
┌──────────────────────────────────────────────────────┐
│                    SwiftUI Views                     │
│  HomeView · JournalView · ProjectsView · InsightsView│
│  SettingsView · LandingView · LoginView              │
├──────────────────────────────────────────────────────┤
│                   ViewModels                         │
│               HomeViewModel (@Observable)            │
├──────────────────────────────────────────────────────┤
│                  Service Layer                       │
│  GitHubService · GitHubAuthService · SupabaseService │
│  KeychainService · NotificationService               │
├──────────────────────────────────────────────────────┤
│                 Data / Models                        │
│  JournalEntry · Project · FocusSession               │
│  GitHubActivityItem · GitHubRepository · GitHubCommit│
│  UserProfile                                         │
├──────────────────────────────────────────────────────┤
│              Persistence & Security                  │
│        SwiftData (local)  ·  Apple Keychain           │
│        Supabase REST API (cloud sync)                │
└──────────────────────────────────────────────────────┘
```

- **Architecture Pattern**: MVVM with `@Observable` macro (Swift 5.9+)
- **State Management**: `AppState` as a shared `@Observable` environment object
- **Concurrency**: Swift structured concurrency (`async/await`)
- **Minimum Deployment**: iOS 17.0+

---

## GitHub OAuth 2.0 Integration

### Authentication Flow

DevJournal uses Apple's `ASWebAuthenticationSession` to perform a secure OAuth 2.0 authorization code flow with GitHub.

**Flow Sequence:**

1. User taps "Sign in with GitHub" on `LoginView` or `SettingsView`
2. App constructs the GitHub authorization URL with `client_id`, `redirect_uri`, and requested scopes (`repo`, `user`, `read:org`)
3. `ASWebAuthenticationSession` opens the GitHub consent page in a secure browser sheet
4. User authorizes → GitHub redirects to `devjournal://oauth-callback?code=AUTHORIZATION_CODE`
5. App extracts the `code` from the callback URL
6. `GitHubAuthService.exchangeCodeForToken()` performs a `POST` to `https://github.com/login/oauth/access_token` with:
   - `client_id`
   - `client_secret`
   - `code`
   - `redirect_uri`
7. GitHub returns the `access_token` in JSON
8. Token is saved to the iOS Keychain via `KeychainService`
9. `AppState.isGitHubConnected` and `AppState.isAuthenticated` are set to `true`

**Key Files:**

| File | Role |
|---|---|
| `GitHubAuthService.swift` | Manages the full OAuth lifecycle: session launch, code extraction, token exchange, sign out |
| `LoginView.swift` | Primary login UI with "Sign in with GitHub" button and `ASWebAuthenticationPresentationContextProviding` |
| `SettingsView.swift` | Secondary GitHub connect UI in Settings with its own presentation context provider |
| `Configuration.swift` | Stores `gitHubClientID` and `gitHubClientSecret` (from Xcode environment variables) |

**Custom URL Scheme:**

The app registers `devjournal` as a custom URL scheme so GitHub can redirect back after authorization. This must be configured in the Xcode project's Info.plist under URL Types.

---

## GitHub REST API Service

`GitHubService.swift` provides authenticated access to GitHub's REST API v3.

### Available Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `fetchRepositories()` | `GET /user/repos?sort=updated&per_page=20` | Fetches the authenticated user's repositories sorted by last update |
| `fetchRecentCommits(repoOwner:repoName:)` | `GET /repos/{owner}/{repo}/commits?per_page=10` | Fetches the 10 most recent commits for a specific repository |
| `fetchUserActivity()` | `GET /user/events?per_page=10` | Fetches the authenticated user's recent events/activity feed |

### Authentication

All requests include:
- `Authorization: Bearer {access_token}` header
- `Accept: application/vnd.github.v3+json` header

The access token is retrieved from the Keychain at request time. If no token is found, `GitHubError.unauthenticated` is thrown.

### Error Handling

| Error | Condition |
|---|---|
| `GitHubError.invalidURL` | Malformed API URL |
| `GitHubError.unauthenticated` | No token in Keychain or empty token |
| `GitHubError.requestFailed(statusCode)` | Non-2xx HTTP response |
| `GitHubError.decodingError` | JSON parsing failure |

### Data Models

- **`GitHubRepository`** — Codable struct mapping GitHub repo JSON (id, name, full_name, description, stars, forks, issues, language, private flag)
- **`GitHubCommit`** — Codable struct with nested `CommitDetail` and `CommitAuthor` (sha, message, author name, date)
- **`GitHubActivityItem`** — SwiftData `@Model` persisted locally for offline display (message, repoName, timestamp, type, author)

---

## Supabase Cloud Synchronization

`SupabaseService.swift` handles cloud persistence via Supabase's PostgREST API.

### REST API Integration

All requests are authenticated with:
- `Authorization: Bearer {anon_key}`
- `apikey: {anon_key}`
- `Content-Type: application/json`
- `Prefer: return=representation`

### Available Operations

| Method | Endpoint | Description |
|---|---|---|
| `syncJournalEntry(_:)` | `POST /rest/v1/journal_entries` | Upserts a journal entry to the cloud database |
| `syncProject(_:)` | `POST /rest/v1/projects` | Upserts a project record to the cloud database |
| `fetchCloudJournalEntries()` | `GET /rest/v1/journal_entries?order=date.desc&limit=50` | Fetches the 50 most recent journal entries from cloud |

### Supabase Table Schema (Expected)

**`journal_entries`**
| Column | Type |
|---|---|
| id | UUID (PK) |
| title | TEXT |
| content | TEXT |
| date | TIMESTAMPTZ |
| mood | TEXT |
| focus_level | TEXT |
| hours_spent | FLOAT |
| tags | TEXT[] |
| github_repo_name | TEXT |

**`projects`**
| Column | Type |
|---|---|
| id | UUID (PK) |
| name | TEXT |
| description | TEXT |
| category | TEXT |
| progress | FLOAT |
| status | TEXT |
| github_repo_name | TEXT |

---

## Data Persistence with SwiftData

All local data is persisted using Apple's SwiftData framework with `@Model` annotated classes.

### Models

| Model | Key Fields | Notes |
|---|---|---|
| `JournalEntry` | title, content, date, mood, focusLevel, hoursSpent, tags, gitHubRepoName, isSyncedWithSupabase | Primary journaling entity |
| `Project` | name, projectDescription, category, progress, status, gitHubRepoName, commitsCount, prsCount, issuesCount, starsCount | Project portfolio entity |
| `FocusSession` | startTime, endTime, durationMinutes, notes, isCompleted | Timer-based focus tracking |
| `GitHubActivityItem` | message, repoName, timestamp, type, author | Cached GitHub events |

### Query Patterns

- `@Query(sort: \JournalEntry.date, order: .reverse)` — Reverse chronological journal entries
- `@Query(sort: \FocusSession.startTime, order: .reverse)` — Recent focus sessions
- `@Query(sort: \Project.updatedAt, order: .reverse)` — Recently updated projects

---

## Security — Keychain Token Storage

`KeychainService.swift` wraps the iOS Keychain Services API for secure credential storage.

### API

| Method | Description |
|---|---|
| `save(key:string:)` | Stores a string value under a key in the Keychain |
| `loadString(key:)` | Retrieves a string value by key from the Keychain |
| `delete(key:)` | Removes a key-value pair from the Keychain |

### Stored Keys

| Key | Purpose |
|---|---|
| `github_access_token` | GitHub OAuth access token for API authentication |

---

## Views & Navigation Architecture

### Tab-Based Navigation

The app uses a custom `GlassTabBar` with 5 tabs managed by `AppState.selectedTab`:

| Tab | View | Description |
|---|---|---|
| Home | `HomeView` | Dashboard with progress ring, activity feed |
| Projects | `ProjectsView` | Filterable project portfolio list |
| Journal | `JournalView` | Journal entry list with "New Entry" sheet |
| Insights | `InsightsView` | Charts and analytics dashboard |
| Settings | `SettingsView` | Profile, theme, GitHub, Supabase controls |

### Authentication Views

| View | Purpose |
|---|---|
| `LandingView` | Onboarding splash with animated feature cards and "Get Started" CTA |
| `LoginView` | GitHub OAuth sign-in form with `ASWebAuthenticationSession` |

### Sheet Presentations

| State Property | Sheet View |
|---|---|
| `appState.isNewJournalSheetPresented` | `NewJournalView` |
| `appState.isNewProjectSheetPresented` | `NewProjectView` |
| `appState.isGitHubConnectSheetPresented` | GitHub Connect sheet in `SettingsView` |

### Dynamic Data in Views

All views now pull data exclusively from SwiftData queries and live API calls. There is **zero hardcoded mock data** anywhere in the codebase. Empty states are shown with appropriate placeholder UI when no data exists.

---

## Configuration & Environment Secrets

All sensitive configuration is managed through `AppConfiguration` in `Configuration.swift`.

### Environment Variables

Set these in Xcode: **Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables**

| Variable | Description | Required |
|---|---|---|
| `SUPABASE_URL` | Your Supabase project URL (e.g., `https://xyz.supabase.co`) | Yes |
| `SUPABASE_ANON_KEY` | Supabase anonymous/public API key | Yes |
| `GITHUB_CLIENT_ID` | GitHub OAuth App client ID | Yes |
| `GITHUB_CLIENT_SECRET` | GitHub OAuth App client secret | Yes |

### GitHub OAuth App Setup

1. Go to GitHub → Settings → Developer Settings → OAuth Apps → New OAuth App
2. Set **Authorization callback URL** to: `devjournal://oauth-callback`
3. Copy the **Client ID** and **Client Secret** into Xcode environment variables

---

## Project Structure

```
DevJournal/
├── App/
│   ├── DevJournalApp.swift          # App entry point, SwiftData container setup
│   └── AppState.swift               # Shared @Observable state (tabs, auth, theme)
├── Core/
│   ├── Theme/
│   │   ├── AppColors.swift          # Design system color palette
│   │   └── GlassMaterial.swift      # Atmospheric background & glass effects
│   └── Components/
│       ├── GlassCard.swift          # Reusable glassmorphism card component
│       ├── ProgressRing.swift       # Circular progress indicator
│       └── GlassTabBar.swift        # Custom frosted glass tab bar
├── Models/
│   ├── JournalEntry.swift           # SwiftData journal entry model
│   ├── Project.swift                # SwiftData project model
│   ├── FocusSession.swift           # SwiftData focus session + UserProfile struct
│   └── GitHubActivity.swift         # GitHub API Codable models + SwiftData activity
├── Services/
│   ├── KeychainService.swift        # iOS Keychain wrapper for secure storage
│   ├── GitHubService.swift          # GitHub REST API v3 client
│   ├── GitHubAuthService.swift      # GitHub OAuth 2.0 authentication
│   ├── SupabaseService.swift        # Supabase PostgREST cloud sync
│   └── NotificationService.swift    # Local notification scheduling
├── ViewModels/
│   └── HomeViewModel.swift          # Dashboard data fetching & progress computation
├── Views/
│   ├── Auth/
│   │   ├── LandingView.swift        # Onboarding splash screen
│   │   └── LoginView.swift          # GitHub OAuth login screen
│   ├── Home/
│   │   └── HomeView.swift           # Dashboard with progress + activity feed
│   ├── Journal/
│   │   ├── JournalView.swift        # Journal entries list
│   │   └── NewJournalView.swift     # New journal entry creation form
│   ├── Projects/
│   │   ├── ProjectsView.swift       # Project portfolio with filters
│   │   ├── ProjectDetailView.swift  # Individual project detail page
│   │   └── NewProjectView.swift     # New project creation form
│   ├── Insights/
│   │   └── InsightsView.swift       # Analytics dashboard with Swift Charts
│   ├── Calendar/
│   │   └── CalendarView.swift       # Calendar-based activity view
│   ├── Settings/
│   │   └── SettingsView.swift       # App settings & GitHub connection
│   └── Root/
│       └── ContentView.swift        # Root view with tab bar routing
└── Resources/
    └── Configuration.swift          # Centralized environment configuration
```

---

## Build & Run Instructions

### Prerequisites

- macOS Sonoma 14.0+
- Xcode 15.4+
- iOS 17.0+ Simulator or physical device

### Steps

1. Clone the repository
2. Open `DevJournal.xcodeproj` in Xcode
3. Configure environment variables (see [Configuration](#configuration--environment-secrets))
4. Select an iOS Simulator or connected device
5. Build and Run (`Cmd + R`)

### URL Scheme Configuration

Ensure the custom URL scheme `devjournal` is registered in Info.plist:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>devjournal</string>
        </array>
    </dict>
</array>
```

---

## Recent Changes Summary

### Mock Data Elimination
- Removed all hardcoded sample data, dummy seeding functions, and fake token injections
- `HomeViewModel` progress stats are now computed dynamically from live SwiftData queries
- `InsightsView` weekly chart data, metrics, and productivity score are all derived from persisted `JournalEntry` and `FocusSession` records
- `SettingsView` GitHub connect now triggers real OAuth flow instead of saving a mock token
- `UserProfile.sample` static instance removed — profile is populated only from authenticated API data
- All fallback display names changed from personal names to generic "Developer" defaults

### Real API Integrations
- `GitHubAuthService.exchangeCodeForToken()` now performs an actual HTTP POST to GitHub's token endpoint
- `SupabaseService` methods now make real REST API calls to Supabase PostgREST instead of using `Task.sleep` simulations
- `GitHubService` fetches live repository, commit, and activity data from GitHub API v3

### Authentication Flow
- `ASWebAuthenticationSession` integrated in both `LoginView` and `SettingsView`
- Guest/skip login bypass buttons removed from `LandingView` and `LoginView`
- `AppConfiguration` expanded with `gitHubClientSecret` for real token exchange

---

## Remaining Roadmap

### Phase 1 — Cloud Sync Engine
- [ ] Create Supabase tables matching the schema documented above
- [ ] Implement upsert conflict resolution (ON CONFLICT DO UPDATE)
- [ ] Add offline queue that caches mutations and syncs when connectivity resumes
- [ ] Add pull-to-refresh cloud sync on HomeView and JournalView

### Phase 2 — GitHub API Enhancements
- [ ] Parse `fetchUserActivity()` response into `GitHubActivityItem` models
- [ ] Implement pagination with `Link` header parsing for large result sets
- [ ] Add `BGTaskScheduler` background fetch for periodic activity refresh
- [ ] Build repository selector to filter activity by specific repos
- [ ] Fetch authenticated user profile (`GET /user`) to populate `UserProfile`

### Phase 3 — Analytics & Features
- [ ] Add date range picker (Weekly/Monthly/Yearly) to InsightsView
- [ ] Export journal entries as PDF or Markdown
- [ ] Configure `UserNotifications` for daily journaling reminders
- [ ] Add focus session timer with live countdown UI

### Phase 4 — Testing & CI/CD
- [ ] Write XCTest unit tests for `HomeViewModel`, `GitHubService`, `KeychainService`
- [ ] Add UI tests for authentication flow
- [ ] Create GitHub Actions workflow for automated builds and test runs
- [ ] Configure Xcode Cloud or Fastlane for release packaging
