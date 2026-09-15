# DevJournal — Native SwiftUI Developer Productivity Application

DevJournal is a native iOS application designed for developer productivity, combining elements of developer activity tracking, journal logging, project portfolio management, and productivity analytics.

The application visual identity is inspired by Apple Human Interface Guidelines and visionOS glassmorphism materials.

---

## Technical Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI (iOS 18+)
- **Local Persistence**: SwiftData
- **Cloud Infrastructure**: Supabase (PostgreSQL Database & Auth)
- **Integrations**: GitHub REST API & GitHub OAuth 2.0
- **Security**: Apple Keychain Services for secure credential storage
- **Analytics**: Swift Charts Framework
- **Architecture**: MVVM with Observable state management

---

## Features

1. **Dashboard Home**:
   - Daily progress tracker with circular completion gauge
   - Focus time and completed task counters
   - Real-time GitHub commit and activity feed

2. **Journal Logs**:
   - Structured developer journal entry logging
   - Mood selector, focus level rating, and hours spent tracking
   - Tag indexing and repository linking

3. **Projects Portfolio**:
   - Active, archived, and starred project classification
   - Commit, pull request, issue, and star counter metrics
   - Progress bar tracking

4. **Productivity Insights**:
   - Weekly focus time bar charts built with Swift Charts
   - Productivity score calculation out of 100
   - Automated recommendations based on peak work hours

5. **Settings and Configuration**:
   - Dynamic system, dark, and light mode color schemes
   - GitHub OAuth authorization toggle
   - Supabase cloud synchronization controls

---

## Project Structure

```text
DevJournal/
├── App/
│   ├── DevJournalApp.swift
│   └── AppState.swift
├── Core/
│   ├── Theme/
│   │   ├── AppColors.swift
│   │   └── GlassMaterial.swift
│   └── Components/
│       ├── GlassCard.swift
│       ├── ProgressRing.swift
│       └── GlassTabBar.swift
├── Models/
│   ├── JournalEntry.swift
│   ├── Project.swift
│   ├── GitHubActivity.swift
│   └── FocusSession.swift
├── Services/
│   ├── KeychainService.swift
│   ├── GitHubService.swift
│   ├── GitHubAuthService.swift
│   └── SupabaseService.swift
├── ViewModels/
│   └── HomeViewModel.swift
├── Views/
│   ├── Home/
│   ├── Journal/
│   ├── Projects/
│   ├── Insights/
│   ├── Calendar/
│   └── Settings/
└── Resources/
    └── Configuration.swift
```

---

## Getting Started

### Prerequisites

- macOS Sonoma 14.0 or later
- Xcode 15.4 or later
- iOS 17.0+ Simulator or physical device

### Building in Xcode

1. Clone the repository:
   ```bash
   git clone https://github.com/daddychill1414/SWIFT_DEVJOURNAL.git
   ```

2. Open the project folder or `Package.swift` in Xcode.

3. Select an iOS Simulator destination and press `Cmd + R` to build and run.

---

## Configuration

Refer to `SETUP_GUIDE.md` for detailed instructions on configuring:
- Supabase PostgreSQL schema and API credentials
- GitHub Developer OAuth App settings
- Xcode environment variables for secure API key injection

---

## Web Preview Suite

An interactive web simulator is available for testing without macOS:
- Web App Simulator: `web_app/index.html`
- Interactive Device Preview: `web_preview/index.html`

---

## Midterm Learning Reflection

### 1. What I Learned While Developing the Application
During the development of **DevJournal**, I gained hands-on experience in building a full-featured, architecture-driven native iOS application from the ground up using modern Swift 5.9+ and SwiftUI. Key takeaways include:
- **Architectural Structuring (MVVM + Observable)**: Designing clean separation of concerns using `@Observable` state management, decoupled view models, and service layer abstractions.
- **Data Persistence & Cloud Synchronization**: Integrating **SwiftData** for fast, offline-first local storage while linking asynchronous network pipelines to **Supabase** for backend cloud sync.
- **REST APIs & Security**: Implementing GitHub OAuth 2.0 authentication flows, querying GitHub REST API endpoints for user activities, and securely storing sensitive user tokens using Apple's **Keychain Services**.

### 2. Challenges Encountered
- **State Synchronization between Local & Cloud Data**: Keeping SwiftData models seamlessly synchronized with remote Supabase tables without causing duplicate records or UI race conditions.
- **Glassmorphism & Complex UI Performance**: Crafting custom visual effects (glass translucent card overlays and visionOS-style blur backdrops) while avoiding layout frame drops or expensive redrawing cycles on older iOS devices.
- **Secure OAuth Token Lifecycle**: Handling OAuth token exchange, storage, and auto-refresh securely across app launches without blocking the main UI thread.

### 3. How I Addressed Those Challenges
- **Unified Service Layer**: Built dedicated service controllers (`GitHubAuthService`, `SupabaseService`, and `KeychainService`) to isolate side-effects and network handling outside the view hierarchy.
- **Optimized View Rendering & Reusable Components**: Extracted glassmorphism styles into modular, lightweight SwiftUI views (`GlassCard`, `GlassTabBar`, `ProgressRing`), minimizing nested body calculations.
- **Keychain Integration**: Wrapped iOS Security framework primitives in `KeychainService` using generic queries to ensure credentials remain encrypted in hardware enclave storage.

### 4. SwiftUI Concepts & Development Skills Improved
- **Modern State Management**: Replaced legacy `@ObservedObject` / `@Published` patterns with Swift 5.9’s macro-powered `@Observable` domain state model.
- **Data Visualization**: Leveraged **Swift Charts** to construct interactive bar graphs, focus time analytics, and trend visualization with custom mark styling.
- **Layout & Animations**: Mastered `GeometryReader`, custom canvas/ring gauges, layout stacks (`VStack`, `HStack`, `ZStack`), and smooth implicit animations (`.withAnimation`).

### 5. Plans for Final Project Completion & Improvement
- **Real-Time WebSockets Sync**: Implement Supabase Realtime subscriptions to update journal entries and activity feeds instantly across devices.
- **Offline Sync Queue**: Build an offline mutation queue manager to defer database sync when network connection is lost.
- **Background GitHub Polling**: Integrate `BGTaskScheduler` to fetch repository updates in the background and trigger periodic productivity summary notifications.
- **Expanded Analytics & Export**: Add PDF / Markdown journal export options and deeper productivity metrics using custom Swift Charts extensions.

