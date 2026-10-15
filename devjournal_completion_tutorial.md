# DevJournal — Complete Project Tutorial

> [!IMPORTANT]
> This tutorial is tailored to **your actual codebase**. Every file path, model field, and service method references real code in your repo. Follow each phase in order — later phases depend on earlier ones.

---

## Phase 1: Live Cloud Synchronization & Sync Engine

### What you're building
Right now your [SupabaseService.swift](file:///z:/CODES%21%21%21%21%20SSD/DEVJOURNAL/DevJournal/Services/SupabaseService.swift) can push journal entries and projects to Supabase and fetch cloud journal entries, but there's **no table schema set up**, **no UPSERT logic** (it only POSTs — duplicates will fail), and **no offline queue**.

---

### Step 1A: Create Supabase Tables

Go to your Supabase dashboard → **SQL Editor** and run these:

```sql
-- Table: journal_entries
CREATE TABLE IF NOT EXISTS journal_entries (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    date TIMESTAMPTZ NOT NULL DEFAULT now(),
    mood TEXT DEFAULT '😄',
    focus_level TEXT DEFAULT 'Medium',
    hours_spent DOUBLE PRECISION DEFAULT 0,
    tags TEXT[] DEFAULT '{}',
    github_repo_name TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Table: projects
CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT DEFAULT 'Personal',
    progress DOUBLE PRECISION DEFAULT 0.0,
    status TEXT DEFAULT 'Active',
    github_repo_name TEXT,
    commits_count INT DEFAULT 0,
    prs_count INT DEFAULT 0,
    issues_count INT DEFAULT 0,
    stars_count INT DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Table: user_profiles
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT,
    username TEXT UNIQUE,
    avatar_url TEXT,
    bio TEXT,
    github_username TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable Row Level Security (users can only access their own data)
ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can CRUD their own journal entries"
    ON journal_entries FOR ALL
    USING (auth.uid() = user_id);

CREATE POLICY "Users can CRUD their own projects"
    ON projects FOR ALL
    USING (auth.uid() = user_id);

CREATE POLICY "Users can CRUD their own profile"
    ON user_profiles FOR ALL
    USING (auth.uid() = id);

-- Auto-update timestamp trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER journal_entries_updated_at
    BEFORE UPDATE ON journal_entries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER projects_updated_at
    BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

> [!TIP]
> After running this, go to **Table Editor** in Supabase and confirm all 3 tables appear with the correct columns.

---

### Step 1B: Fix SupabaseService to use UPSERT

Your current [SupabaseService.swift](file:///z:/CODES%21%21%21%21%20SSD/DEVJOURNAL/DevJournal/Services/SupabaseService.swift) uses `POST` which will **fail on duplicate UUIDs**. You need to switch to Supabase's UPSERT by adding a `Prefer: resolution=merge-duplicates` header.

**What to change in `makeRequest`:**

```swift
// In SupabaseService.swift — update makeRequest to accept optional extra headers
private func makeRequest(
    endpoint: String,
    method: String,
    body: Data? = nil,
    extraHeaders: [String: String] = [:]
) async throws -> Data {
    guard !supabaseURL.isEmpty, !supabaseAnonKey.isEmpty else {
        throw SupabaseError.configMissing
    }
    
    guard let url = URL(string: "\(supabaseURL)/rest/v1/\(endpoint)") else {
        throw SupabaseError.networkError
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
    request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("return=representation", forHTTPHeaderField: "Prefer")
    
    // Apply any extra headers (like upsert resolution)
    for (key, value) in extraHeaders {
        request.addValue(value, forHTTPHeaderField: key)
    }
    
    request.httpBody = body
    
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
        throw SupabaseError.invalidResponse(statusCode)
    }
    
    return data
}
```

**Then update `syncJournalEntry` and `syncProject` to use UPSERT:**

```swift
func syncJournalEntry(_ entry: JournalEntry) async throws {
    let payload: [String: Any] = [
        "id": entry.id.uuidString,
        "title": entry.title,
        "content": entry.content,
        "date": ISO8601DateFormatter().string(from: entry.date),
        "mood": entry.mood,
        "focus_level": entry.focusLevel,
        "hours_spent": entry.hoursSpent,
        "tags": entry.tags,
        "github_repo_name": entry.gitHubRepoName ?? ""
    ]
    let body = try JSONSerialization.data(withJSONObject: payload)
    _ = try await makeRequest(
        endpoint: "journal_entries",
        method: "POST",
        body: body,
        extraHeaders: ["Prefer": "return=representation,resolution=merge-duplicates"]
    )
    entry.isSyncedWithSupabase = true
}

func syncProject(_ project: Project) async throws {
    let payload: [String: Any] = [
        "id": project.id.uuidString,
        "name": project.name,
        "description": project.projectDescription,
        "category": project.category,
        "progress": project.progress,
        "status": project.status,
        "github_repo_name": project.gitHubRepoName ?? "",
        "commits_count": project.commitsCount,
        "prs_count": project.prsCount,
        "issues_count": project.issuesCount,
        "stars_count": project.starsCount
    ]
    let body = try JSONSerialization.data(withJSONObject: payload)
    _ = try await makeRequest(
        endpoint: "projects",
        method: "POST",
        body: body,
        extraHeaders: ["Prefer": "return=representation,resolution=merge-duplicates"]
    )
}
```

---

### Step 1C: Build the Offline Sync Queue

Create a new file: `DevJournal/Services/SyncEngine.swift`

**Concept:** When the user saves a journal entry or project, it goes into SwiftData immediately (instant local experience). A `SyncEngine` runs in the background and pushes unsynced items to Supabase. If the network is down, changes stay queued locally until the next attempt.

```swift
// SyncEngine.swift
import Foundation
import SwiftData
import Network

@Observable
final class SyncEngine {
    static let shared = SyncEngine()
    
    var isSyncing: Bool = false
    var lastSyncDate: Date?
    
    private let monitor = NWPathMonitor()
    private var isConnected: Bool = false
    
    private init() {
        // Monitor network connectivity
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = (path.status == .satisfied)
            if path.status == .satisfied {
                // Network came back — auto-sync
                Task { await self?.syncAll() }
            }
        }
        monitor.start(queue: DispatchQueue(label: "SyncEngine.NetworkMonitor"))
    }
    
    /// Call this after any local save to push unsynced items
    @MainActor
    func syncAll(using modelContext: ModelContext? = nil) async {
        guard isConnected, !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }
        
        // If no modelContext provided, you'll need to get one from your app's container
        guard let context = modelContext else { return }
        
        // 1. Sync unsynced journal entries
        do {
            let unsyncedPredicate = #Predicate<JournalEntry> { $0.isSyncedWithSupabase == false }
            let descriptor = FetchDescriptor<JournalEntry>(predicate: unsyncedPredicate)
            let unsyncedEntries = try context.fetch(descriptor)
            
            for entry in unsyncedEntries {
                do {
                    try await SupabaseService.shared.syncJournalEntry(entry)
                    // entry.isSyncedWithSupabase is set to true inside syncJournalEntry
                } catch {
                    print("SyncEngine: Failed to sync entry \(entry.id): \(error)")
                    // Don't stop — continue trying other items
                }
            }
        } catch {
            print("SyncEngine: Failed to fetch unsynced entries: \(error)")
        }
        
        // 2. Sync projects (add an isSyncedWithSupabase field to Project model first!)
        // Similar pattern as above
        
        try? context.save()
        lastSyncDate = Date()
    }
}
```

> [!IMPORTANT]
> You'll need to add `var isSyncedWithSupabase: Bool = false` to your [Project.swift](file:///z:/CODES%21%21%21%21%20SSD/DEVJOURNAL/DevJournal/Models/Project.swift) model, just like [JournalEntry.swift](file:///z:/CODES%21%21%21%21%20SSD/DEVJOURNAL/DevJournal/Models/JournalEntry.swift) already has it.

**Where to call `SyncEngine.shared.syncAll()`:**
- After saving a new journal entry in `NewJournalView`
- After creating/updating a project in `NewProjectView`
- On app launch in your App's `init()` or `.onAppear` in `ContentView`
- Automatically when network connectivity is restored (already handled by `NWPathMonitor` above)

---

## Phase 2: Live GitHub API Enhancements

### What you're building
Your [GitHubService.swift](file:///z:/CODES%21%21%21%21%20SSD/DEVJOURNAL/DevJournal/Services/GitHubService.swift) currently fetches repos and commits but has **no pagination**, **`fetchUserActivity()` returns an empty array**, and there's **no background refresh**.

---

### Step 2A: Add Pagination Support

Add a generic paginated fetch helper to `GitHubService`:

```swift
// Add this to GitHubService.swift

/// Generic paginated GitHub API fetch
private func fetchPaginated<T: Decodable>(
    endpoint: String,
    page: Int = 1,
    perPage: Int = 30
) async throws -> [T] {
    guard let token = accessToken, !token.isEmpty else {
        throw GitHubError.unauthenticated
    }
    
    // Append pagination query params
    let separator = endpoint.contains("?") ? "&" : "?"
    let paginatedEndpoint = "\(endpoint)\(separator)page=\(page)&per_page=\(perPage)"
    
    guard let url = URL(string: "\(baseURL)\(paginatedEndpoint)") else {
        throw GitHubError.invalidURL
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw GitHubError.requestFailed((response as? HTTPURLResponse)?.statusCode ?? 500)
    }
    
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode([T].self, from: data)
}

/// Fetch commits with pagination
func fetchRecentCommits(
    repoOwner: String,
    repoName: String,
    page: Int = 1,
    perPage: Int = 30
) async throws -> [GitHubCommit] {
    return try await fetchPaginated(
        endpoint: "/repos/\(repoOwner)/\(repoName)/commits",
        page: page,
        perPage: perPage
    )
}

/// Fetch user events (ACTUALLY parse the response now)
func fetchUserActivity(page: Int = 1) async throws -> [GitHubActivityItem] {
    guard let token = accessToken, !token.isEmpty else {
        throw GitHubError.unauthenticated
    }
    
    guard let url = URL(string: "\(baseURL)/user/events?per_page=30&page=\(page)") else {
        throw GitHubError.invalidURL
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw GitHubError.requestFailed((response as? HTTPURLResponse)?.statusCode ?? 500)
    }
    
    // Parse the GitHub Events API response
    guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
        return []
    }
    
    let dateFormatter = ISO8601DateFormatter()
    
    return jsonArray.compactMap { event -> GitHubActivityItem? in
        guard let id = event["id"] as? String,
              let type = event["type"] as? String,
              let repo = event["repo"] as? [String: Any],
              let repoName = repo["name"] as? String,
              let createdAt = event["created_at"] as? String,
              let actor = event["actor"] as? [String: Any],
              let login = actor["login"] as? String else {
            return nil
        }
        
        // Map GitHub event types to human-readable messages
        let message: String
        switch type {
        case "PushEvent":
            let payload = event["payload"] as? [String: Any]
            let commits = payload?["commits"] as? [[String: Any]]
            let commitMsg = commits?.first?["message"] as? String ?? "Pushed commits"
            message = commitMsg
        case "PullRequestEvent":
            let payload = event["payload"] as? [String: Any]
            let action = payload?["action"] as? String ?? "updated"
            let pr = payload?["pull_request"] as? [String: Any]
            let title = pr?["title"] as? String ?? "Pull request"
            message = "\(action.capitalized): \(title)"
        case "IssuesEvent":
            let payload = event["payload"] as? [String: Any]
            let action = payload?["action"] as? String ?? "updated"
            let issue = payload?["issue"] as? [String: Any]
            let title = issue?["title"] as? String ?? "Issue"
            message = "\(action.capitalized): \(title)"
        case "CreateEvent":
            let payload = event["payload"] as? [String: Any]
            let refType = payload?["ref_type"] as? String ?? "resource"
            message = "Created \(refType)"
        case "WatchEvent":
            message = "Starred repository"
        default:
            message = type.replacingOccurrences(of: "Event", with: "")
        }
        
        let eventType: String
        switch type {
        case "PushEvent": eventType = "commit"
        case "PullRequestEvent": eventType = "pr"
        case "IssuesEvent": eventType = "issue"
        case "WatchEvent": eventType = "star"
        default: eventType = "commit"
        }
        
        return GitHubActivityItem(
            id: id,
            message: message,
            repoName: repoName,
            timestamp: dateFormatter.date(from: createdAt) ?? Date(),
            type: eventType,
            author: login
        )
    }
}
```

---

### Step 2B: Background Activity Refresh

Create a new file: `DevJournal/Services/BackgroundTaskService.swift`

```swift
// BackgroundTaskService.swift
import BackgroundTasks
import SwiftData

final class BackgroundTaskService {
    static let shared = BackgroundTaskService()
    
    // Use your app's bundle ID prefix
    static let refreshTaskIdentifier = "com.devjournal.app.githubRefresh"
    
    private init() {}
    
    /// Call this once in your App's init()
    func registerTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.refreshTaskIdentifier,
            using: nil
        ) { task in
            self.handleGitHubRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    /// Schedule the next background fetch
    func scheduleGitHubRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 min minimum
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("BackgroundTask: GitHub refresh scheduled")
        } catch {
            print("BackgroundTask: Failed to schedule — \(error)")
        }
    }
    
    private func handleGitHubRefresh(task: BGAppRefreshTask) {
        // Schedule the next one immediately
        scheduleGitHubRefresh()
        
        let fetchTask = Task {
            do {
                let activities = try await GitHubService.shared.fetchUserActivity()
                print("BackgroundTask: Fetched \(activities.count) activities")
                // Optionally save to SwiftData here
            } catch {
                print("BackgroundTask: Fetch failed — \(error)")
            }
        }
        
        // Handle task expiration
        task.expirationHandler = {
            fetchTask.cancel()
        }
        
        Task {
            await fetchTask.value
            task.setTaskCompleted(success: true)
        }
    }
}
```

**You also need to register the background task identifier in [Info.plist](file:///z:/CODES%21%21%21%21%20SSD/DEVJOURNAL/DevJournal/Info.plist):**

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.devjournal.app.githubRefresh</string>
</array>
```

**Then in your main App struct**, call:

```swift
init() {
    BackgroundTaskService.shared.registerTasks()
}

// And in the body, on first appear:
.onAppear {
    BackgroundTaskService.shared.scheduleGitHubRefresh()
}
```

---

### Step 2C: Repository Selector

This lets users pick which GitHub repos to track in their activity feed.

**1. Add a stored selection to [AppState.swift](file:///z:/CODES%21%21%21%21%20SSD/DEVJOURNAL/DevJournal/App/AppState.swift):**

```swift
// Add to AppState
var selectedRepoNames: Set<String> = []  // empty = show all
```

**2. Create a new view** `DevJournal/Views/Settings/RepoSelectorView.swift`:

```swift
import SwiftUI

struct RepoSelectorView: View {
    @Environment(AppState.self) private var appState
    @State private var repos: [GitHubRepository] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    ProgressView("Loading repositories...")
                } else {
                    ForEach(repos) { repo in
                        Button {
                            toggleRepo(repo.fullName)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(repo.name).font(.headline)
                                    if let desc = repo.description {
                                        Text(desc)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                                if appState.selectedRepoNames.contains(repo.fullName) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Repositories")
            .task {
                await loadRepos()
            }
        }
    }
    
    private func toggleRepo(_ name: String) {
        if appState.selectedRepoNames.contains(name) {
            appState.selectedRepoNames.remove(name)
        } else {
            appState.selectedRepoNames.insert(name)
        }
    }
    
    private func loadRepos() async {
        isLoading = true
        do {
            repos = try await GitHubService.shared.fetchRepositories()
        } catch {
            print("Failed to load repos: \(error)")
        }
        isLoading = false
    }
}
```

**3. Filter the activity feed** in [HomeViewModel.swift](file:///z:/CODES%21%21%21%21%20SSD/DEVJOURNAL/DevJournal/ViewModels/HomeViewModel.swift):

```swift
// Add a filtered computed property
var filteredActivities: [GitHubActivityItem] {
    guard !selectedRepoNames.isEmpty else { return gitHubActivities }
    return gitHubActivities.filter { selectedRepoNames.contains($0.repoName) }
}

// Add the property
var selectedRepoNames: Set<String> = []
```

**4. Add a navigation link to `RepoSelectorView`** from [SettingsView](file:///z:/CODES%21%21%21%21%20SSD/DEVJOURNAL/DevJournal/Views/Settings/SettingsView.swift).

---

## Phase 3: Analytics & Advanced Features

### Step 3A: Interactive Date Range Picker for InsightsView

Your [InsightsView.swift](file:///z:/CODES%21%21%21%21%20SSD/DEVJOURNAL/DevJournal/Views/Insights/InsightsView.swift) is hardcoded to "this week". Add a segmented picker:

```swift
// Add these to InsightsView
enum DateRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

@State private var selectedRange: DateRange = .week

// Replace the hardcoded weeklyData computed property with:
private var filteredData: [FocusTimeData] {
    let calendar = Calendar.current
    let today = Date()
    
    let daysBack: Int
    switch selectedRange {
    case .week: daysBack = 7
    case .month: daysBack = 30
    case .year: daysBack = 365
    }
    
    let dayFormatter = DateFormatter()
    
    switch selectedRange {
    case .week:
        dayFormatter.dateFormat = "EEE"  // Mon, Tue, etc.
    case .month:
        dayFormatter.dateFormat = "d"     // 1, 2, ... 30
    case .year:
        dayFormatter.dateFormat = "MMM"   // Jan, Feb, etc.
    }
    
    if selectedRange == .year {
        // Group by month for yearly view
        return (0..<12).reversed().map { monthsAgo in
            guard let monthDate = calendar.date(byAdding: .month, value: -monthsAgo, to: today) else {
                return FocusTimeData(day: "", hours: 0)
            }
            let monthStart = calendar.dateInterval(of: .month, for: monthDate)!
            
            let monthEntries = journalEntries.filter {
                $0.date >= monthStart.start && $0.date < monthStart.end
            }
            let monthFocus = focusSessions.filter {
                $0.startTime >= monthStart.start && $0.startTime < monthStart.end && $0.isCompleted
            }
            
            let totalHours = monthEntries.reduce(0.0) { $0 + $1.hoursSpent }
                + Double(monthFocus.reduce(0) { $0 + $1.durationMinutes }) / 60.0
            
            return FocusTimeData(day: dayFormatter.string(from: monthDate), hours: totalHours)
        }
    } else {
        return (0..<daysBack).reversed().map { daysAgo in
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else {
                return FocusTimeData(day: "", hours: 0)
            }
            
            let dayEntries = journalEntries.filter { calendar.isDate($0.date, inSameDayAs: date) }
            let dayFocus = focusSessions.filter {
                calendar.isDate($0.startTime, inSameDayAs: date) && $0.isCompleted
            }
            
            let totalHours = dayEntries.reduce(0.0) { $0 + $1.hoursSpent }
                + Double(dayFocus.reduce(0) { $0 + $1.durationMinutes }) / 60.0
            
            return FocusTimeData(day: dayFormatter.string(from: date), hours: totalHours)
        }
    }
}
```

**Add the picker to the body**, right below the title:

```swift
// Insert after the title VStack, before Productivity Score Card
Picker("Range", selection: $selectedRange) {
    ForEach(DateRange.allCases, id: \.self) { range in
        Text(range.rawValue).tag(range)
    }
}
.pickerStyle(.segmented)
.padding(.horizontal, 20)
```

Then replace all references to `weeklyData` with `filteredData`.

---

### Step 3B: Export Journal Data

Create: `DevJournal/Services/ExportService.swift`

```swift
import Foundation
import UIKit

final class ExportService {
    
    /// Export journal entries as a Markdown string
    static func exportAsMarkdown(entries: [JournalEntry]) -> String {
        var md = "# DevJournal Export\n"
        md += "**Exported:** \(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .short))\n\n"
        md += "---\n\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        for entry in entries.sorted(by: { $0.date > $1.date }) {
            md += "## \(entry.title)\n"
            md += "**Date:** \(dateFormatter.string(from: entry.date)) · "
            md += "**Mood:** \(entry.mood) · "
            md += "**Focus:** \(entry.focusLevel) · "
            md += "**Hours:** \(String(format: "%.1f", entry.hoursSpent))h\n\n"
            
            if !entry.tags.isEmpty {
                md += "**Tags:** \(entry.tags.map { "`\($0)`" }.joined(separator: " "))\n\n"
            }
            
            md += "\(entry.content)\n\n---\n\n"
        }
        
        return md
    }
    
    /// Export as PDF using UIKit's print renderer
    static func exportAsPDF(entries: [JournalEntry]) -> Data? {
        let markdown = exportAsMarkdown(entries: entries)
        
        let printFormatter = UIMarkupTextPrintFormatter(markupText: markdown)
        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)
        
        let pageSize = CGSize(width: 612, height: 792) // US Letter
        let pageRect = CGRect(origin: .zero, size: pageSize)
        let printableRect = pageRect.insetBy(dx: 36, dy: 36)
        
        renderer.setValue(NSValue(cgRect: pageRect), forKey: "paperRect")
        renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")
        
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, pageRect, nil)
        
        for i in 0..<renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }
        
        UIGraphicsEndPDFContext()
        return pdfData as Data
    }
    
    /// Present a share sheet with the exported file
    @MainActor
    static func shareMarkdown(entries: [JournalEntry]) {
        let content = exportAsMarkdown(entries: entries)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("DevJournal_Export.md")
        try? content.write(to: tempURL, atomically: true, encoding: .utf8)
        
        let activityVC = UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}
```

**Add an export button** to your Journal or Settings view:

```swift
Button {
    ExportService.shareMarkdown(entries: journalEntries)
} label: {
    Label("Export Journals", systemImage: "square.and.arrow.up")
}
```

---

### Step 3C: Local Notifications

Your [NotificationService.swift](file:///z:/CODES%21%21%21%21%20SSD/DEVJOURNAL/DevJournal/Services/NotificationService.swift) already has the foundation! You just need to **wire it to the UI**.

**In [SettingsView.swift](file:///z:/CODES%21%21%21%21%20SSD/DEVJOURNAL/DevJournal/Views/Settings/SettingsView.swift), add a toggle + time picker:**

```swift
@State private var reminderTime = Date()

// In the body:
Section("Notifications") {
    Toggle("Daily Journal Reminder", isOn: $appState.isFocusRemindersEnabled)
        .onChange(of: appState.isFocusRemindersEnabled) { _, enabled in
            if enabled {
                Task {
                    let granted = await NotificationService.shared.requestAuthorization()
                    if granted {
                        let components = Calendar.current.dateComponents(
                            [.hour, .minute], from: reminderTime
                        )
                        NotificationService.shared.scheduleFocusReminder(at: components)
                    }
                }
            } else {
                NotificationService.shared.cancelReminders()
            }
        }
    
    if appState.isFocusRemindersEnabled {
        DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
    }
}
```

> [!TIP]
> You might also want to add a second notification type for focus session completion. Add a new method to `NotificationService` like `scheduleFocusSessionAlert(afterMinutes: Int)`.

---

## Phase 4: Polish & Deployment

### Step 4A: XCTest Unit Tests

Create a test target (if it doesn't exist): In Xcode → File → New → Target → **Unit Testing Bundle** → name it `DevJournalTests`.

**Example test file: `DevJournalTests/HomeViewModelTests.swift`**

```swift
import XCTest
@testable import DevJournal

// Mock GitHubService for testing
final class MockGitHubService: GitHubServiceProtocol {
    var mockRepos: [GitHubRepository] = []
    var mockCommits: [GitHubCommit] = []
    var mockActivities: [GitHubActivityItem] = []
    var shouldThrowError = false
    
    func fetchRepositories() async throws -> [GitHubRepository] {
        if shouldThrowError { throw GitHubError.unauthenticated }
        return mockRepos
    }
    
    func fetchRecentCommits(repoOwner: String, repoName: String) async throws -> [GitHubCommit] {
        if shouldThrowError { throw GitHubError.requestFailed(500) }
        return mockCommits
    }
    
    func fetchUserActivity() async throws -> [GitHubActivityItem] {
        if shouldThrowError { throw GitHubError.unauthenticated }
        return mockActivities
    }
}

final class HomeViewModelTests: XCTestCase {
    
    func testFetchActivitiesSuccess() async {
        let mockService = MockGitHubService()
        mockService.mockActivities = [
            GitHubActivityItem(message: "Test commit", repoName: "user/repo", type: "commit")
        ]
        
        let viewModel = HomeViewModel(gitHubService: mockService)
        await viewModel.fetchRecentActivities()
        
        XCTAssertEqual(viewModel.gitHubActivities.count, 1)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testFetchActivitiesFailure() async {
        let mockService = MockGitHubService()
        mockService.shouldThrowError = true
        
        let viewModel = HomeViewModel(gitHubService: mockService)
        await viewModel.fetchRecentActivities()
        
        XCTAssertTrue(viewModel.gitHubActivities.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testComputeTodayProgress() {
        let viewModel = HomeViewModel()
        
        let entry = JournalEntry(title: "Test", content: "Testing", hoursSpent: 4.0)
        let session = FocusSession(durationMinutes: 30, isCompleted: true)
        
        viewModel.computeTodayProgress(entries: [entry], sessions: [session])
        
        XCTAssertEqual(viewModel.progressPercent, 0.5, accuracy: 0.01) // 4h / 8h goal
        XCTAssertEqual(viewModel.completedTasksCount, 2) // 1 entry + 1 session
    }
}
```

**`DevJournalTests/KeychainServiceTests.swift`:**

```swift
import XCTest
@testable import DevJournal

final class KeychainServiceTests: XCTestCase {
    let keychain = KeychainService.shared
    let testKey = "test_keychain_key"
    
    override func tearDown() {
        _ = keychain.delete(key: testKey)
        super.tearDown()
    }
    
    func testSaveAndLoadString() {
        let saved = keychain.save(key: testKey, string: "test_token_123")
        XCTAssertTrue(saved)
        
        let loaded = keychain.loadString(key: testKey)
        XCTAssertEqual(loaded, "test_token_123")
    }
    
    func testDeleteKey() {
        _ = keychain.save(key: testKey, string: "to_be_deleted")
        let deleted = keychain.delete(key: testKey)
        XCTAssertTrue(deleted)
        
        let loaded = keychain.loadString(key: testKey)
        XCTAssertNil(loaded)
    }
    
    func testLoadNonexistentKey() {
        let loaded = keychain.loadString(key: "nonexistent_key_xyz")
        XCTAssertNil(loaded)
    }
}
```

> [!NOTE]
> Your `HomeViewModel` already accepts `GitHubServiceProtocol` via dependency injection ([line 24](file:///z:/CODES%21%21%21%21%20SSD/DEVJOURNAL/DevJournal/ViewModels/HomeViewModel.swift#L24)) — this is great! It means you can inject `MockGitHubService` for testing without hitting the real API.

---

### Step 4B: GitHub Actions CI/CD

Create: `.github/workflows/build.yml`

```yaml
name: DevJournal CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-and-test:
    runs-on: macos-15   # Use latest macOS runner with Xcode 16+

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.0.app/Contents/Developer

      - name: Show Xcode Version
        run: xcodebuild -version

      - name: Resolve Swift Packages
        run: |
          xcodebuild -resolvePackageDependencies \
            -project DevJournal.xcodeproj \
            -scheme DevJournal

      - name: Build
        run: |
          xcodebuild build \
            -project DevJournal.xcodeproj \
            -scheme DevJournal \
            -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' \
            -configuration Debug \
            CODE_SIGNING_ALLOWED=NO

      - name: Run Tests
        run: |
          xcodebuild test \
            -project DevJournal.xcodeproj \
            -scheme DevJournal \
            -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' \
            -configuration Debug \
            CODE_SIGNING_ALLOWED=NO
```

> [!WARNING]
> Make sure your Xcode scheme's test action includes the `DevJournalTests` target. In Xcode: **Product → Scheme → Edit Scheme → Test → add DevJournalTests**.

---

## Quick Reference: File Map

| What to create/modify | Phase | Purpose |
|---|---|---|
| Supabase SQL (dashboard) | 1A | Create `journal_entries`, `projects`, `user_profiles` tables |
| [SupabaseService.swift](file:///z:/CODES%21%21%21%21%20SSD/DEVJOURNAL/DevJournal/Services/SupabaseService.swift) | 1B | Add UPSERT headers, fix duplicate handling |
| **NEW** `Services/SyncEngine.swift` | 1C | Offline queue + auto-sync with `NWPathMonitor` |
| [Project.swift](file:///z:/CODES%21%21%21%21%20SSD/DEVJOURNAL/DevJournal/Models/Project.swift) | 1C | Add `isSyncedWithSupabase` field |
| [GitHubService.swift](file:///z:/CODES%21%21%21%21%20SSD/DEVJOURNAL/DevJournal/Services/GitHubService.swift) | 2A | Pagination + actually parse `fetchUserActivity()` |
| **NEW** `Services/BackgroundTaskService.swift` | 2B | `BGTaskScheduler` for background GitHub refresh |
| [Info.plist](file:///z:/CODES%21%21%21%21%20SSD/DEVJOURNAL/DevJournal/Info.plist) | 2B | Register background task identifier |
| **NEW** `Views/Settings/RepoSelectorView.swift` | 2C | UI for picking tracked repos |
| [AppState.swift](file:///z:/CODES%21%21%21%21%20SSD/DEVJOURNAL/DevJournal/App/AppState.swift) | 2C | Add `selectedRepoNames` property |
| [InsightsView.swift](file:///z:/CODES%21%21%21%21%20SSD/DEVJOURNAL/DevJournal/Views/Insights/InsightsView.swift) | 3A | Date range picker + monthly/yearly charts |
| **NEW** `Services/ExportService.swift` | 3B | Markdown + PDF export |
| [SettingsView.swift](file:///z:/CODES%21%21%21%21%20SSD/DEVJOURNAL/DevJournal/Views/Settings/SettingsView.swift) | 3C | Wire notification toggle + time picker |
| **NEW** `DevJournalTests/` | 4A | Unit tests |
| **NEW** `.github/workflows/build.yml` | 4B | CI/CD pipeline |
