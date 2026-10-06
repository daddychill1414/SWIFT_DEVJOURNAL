# DevJournal — Project Changes & Remaining Roadmap

This document outlines the recent modifications made to the DevJournal codebase, along with a structured roadmap of remaining features and tasks.

---

## 1. Summary of Recent Changes

### Authentication & OAuth Integration
- **ASWebAuthenticationSession Support**: Integrated native `ASWebAuthenticationSession` in `LoginView.swift` and `GitHubAuthService.swift` to handle OAuth 2.0 PKCE browser authentication.
- **Secure Token Storage**: Configured `KeychainService` for storing GitHub access tokens securely on iOS devices.
- **App Configuration**: Refactored `AppConfiguration` in `Configuration.swift` to dynamically pull credentials (`gitHubClientId`, `gitHubClientSecret`, `supabaseUrl`, `supabaseAnonKey`) from environment/bundles.

### Service Layer & Data Seeding Refactoring
- **Supabase Cloud Service**: Updated `SupabaseService.swift` to consume centralized configuration parameters for database sync operations.
- **Clean Persistence Seeding**: Removed legacy dummy sample data injection (`seedInitialDataIfNeeded` in `HomeView.swift` and `seedInitialProjectsIfNeeded` in `ProjectsView.swift`), transitioning the app to rely purely on live SwiftData storage and remote service synchronization.
- **Enforced Auth Flow**: Cleaned up `LandingView.swift` and `LoginView.swift` by removing temporary guest/skip login bypasses.

### Package & Build System Fixes
- **SPM Library Target Fix**: Updated `Package.swift` target definition from executable to `.library` to enable clean Swift Package Manager compilation for iOS platforms.
- **Observation Cleanups**: Removed redundant `import Observation` statements across Swift views for Swift 5.9 native macro compatibility.
- **Xcode Project Alignment**: Verified and aligned `.xcodeproj` build settings for seamless deployment to iOS simulators and physical devices.

---

## 2. Outstanding & Remaining Tasks (What More To Do)

### Phase 1: Live Cloud Synchronization & Sync Engine
- [ ] **Full Supabase REST / SDK Integration**: Complete table schema mappings in Supabase for `journal_entries`, `projects`, and `user_profiles`.
- [ ] **Conflict Resolution & Offline Queueing**: Implement offline-first caching where local SwiftData changes are queued and synced when network connection is restored.

### Phase 2: Live GitHub API Enhancements
- [ ] **API Pagination & Detailed Commit Feed**: Implement paginated fetching in `GitHubService.swift` for repository commit histories, pull requests, and issues.
- [ ] **Background Activity Refresh**: Add background fetch task via `BGTaskScheduler` to periodically fetch new GitHub commits without blocking the UI.
- [ ] **Repository Selector**: Allow users to filter activity feeds by selecting specific connected GitHub repositories.

### Phase 3: Analytics & Advanced Features
- [ ] **Interactive Productivity Analytics**: Expand `InsightsView` with interactive date range pickers (Weekly, Monthly, Yearly) using `Swift Charts`.
- [ ] **Export Journal Data**: Add option to export journal entries and project metrics as PDF or Markdown files.
- [ ] **Local Notifications**: Configure `UserNotifications` framework for daily journaling reminders and focus session alerts.

### Phase 4: Polish & Deployment
- [ ] **Automated Test Suite**: Write XCTest unit tests for `HomeViewModel`, `GitHubService`, and `KeychainService`.
- [ ] **CI/CD & Xcode Packaging**: Add GitHub Actions workflow for building the `.xcodeproj` and running automated test suites.
