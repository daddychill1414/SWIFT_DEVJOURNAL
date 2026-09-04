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
