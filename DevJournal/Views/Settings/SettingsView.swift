//
//  SettingsView.swift
//  DevJournal
//

import SwiftUI
import AuthenticationServices
import SwiftData

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @StateObject private var gitHubAuth = GitHubAuthService.shared
    @Query(sort: \JournalEntry.date, order: .reverse) private var journalEntries: [JournalEntry]
    
    // GitHub Authenticated User Metrics
    @State private var followersCount: Int? = nil
    @State private var publicReposCount: Int? = nil
    @State private var followingCount: Int? = nil
    @State private var isRefreshingGitHub: Bool = false
    @State private var refreshError: String? = nil
    @AppStorage("github_last_synced_timestamp") private var lastSyncedTimestamp: Double = 0
    
    private var lastSyncedDate: Date? {
        lastSyncedTimestamp > 0 ? Date(timeIntervalSince1970: lastSyncedTimestamp) : nil
    }
    
    @State private var reminderTime: Date = {
        var comps = DateComponents()
        comps.hour = 20; comps.minute = 0
        return Calendar.current.date(from: comps) ?? Date()
    }()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackgroundView()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title
                        Text("Settings")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        
                        // PROFILE SECTION
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PROFILE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 24)
                            
                            GlassCard(style: .regular) {
                                VStack(spacing: 16) {
                                    HStack(spacing: 16) {
                                        if let avatarUrl = appState.currentUser?.avatarUrl,
                                           let url = URL(string: avatarUrl) {
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 54, height: 54)
                                                        .clipShape(Circle())
                                                        .overlay(Circle().stroke(AppColors.primaryIndigo.opacity(0.4), lineWidth: 2))
                                                default:
                                                    Image(systemName: "person.crop.circle.fill")
                                                        .font(.system(size: 54))
                                                        .foregroundStyle(AppColors.primaryIndigo, AppColors.secondaryPurple)
                                                }
                                            }
                                        } else {
                                            Image(systemName: "person.crop.circle.fill")
                                                .font(.system(size: 54))
                                                .foregroundStyle(AppColors.primaryIndigo, AppColors.secondaryPurple)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 6) {
                                                Text(appState.currentUser?.name ?? "Developer")
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                if gitHubAuth.isAuthenticated {
                                                    Image(systemName: "checkmark.seal.fill")
                                                        .font(.caption)
                                                        .foregroundColor(AppColors.accentCyan)
                                                }
                                            }
                                            Text("@\(appState.currentUser?.username ?? "user")")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            Text(appState.currentUser?.bio ?? "iOS Developer")
                                                .font(.caption)
                                                .foregroundColor(AppColors.accentCyan)
                                                .lineLimit(2)
                                        }
                                        Spacer()
                                    }
                                    
                                    // GitHub User Metrics
                                    if gitHubAuth.isAuthenticated {
                                        Divider()
                                        
                                        HStack(spacing: 10) {
                                            userMetricItem(
                                                title: "Username",
                                                value: appState.currentUser.map { "@\($0.username)" } ?? "@user",
                                                icon: "at",
                                                color: AppColors.accentCyan
                                            )
                                            
                                            userMetricItem(
                                                title: "Followers",
                                                value: followersCount.map { "\($0)" } ?? "—",
                                                icon: "person.2.fill",
                                                color: AppColors.secondaryPurple
                                            )
                                            
                                            userMetricItem(
                                                title: "Public Repos",
                                                value: publicReposCount.map { "\($0)" } ?? "—",
                                                icon: "folder.fill",
                                                color: AppColors.primaryIndigo
                                            )
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // PREFERENCES SECTION
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PREFERENCES")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 24)
                            
                            GlassCard(style: .thin) {
                                VStack(spacing: 14) {
                                    // Appearance Picker
                                    HStack {
                                        Label("Appearance", systemImage: "paintbrush.fill")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Picker("Theme", selection: Bindable(appState).themeMode) {
                                            ForEach(AppThemeMode.allCases) { mode in
                                                Text(mode.rawValue).tag(mode)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                    }
                                    
                                    Divider()
                                    
                                    // Notifications Toggle
                                    Toggle(isOn: Bindable(appState).isNotificationsEnabled) {
                                        Label("Notifications", systemImage: "bell.fill")
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Divider()
                                    
                                    // Focus Reminders Toggle + time picker
                                    Toggle(isOn: Bindable(appState).isFocusRemindersEnabled) {
                                        Label("Focus Reminders", systemImage: "timer")
                                            .foregroundColor(.primary)
                                    }
                                    .onChange(of: appState.isFocusRemindersEnabled) { _, enabled in
                                        if enabled {
                                            Task {
                                                let granted = await NotificationService.shared.requestAuthorization()
                                                if granted {
                                                    let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
                                                    NotificationService.shared.scheduleFocusReminder(at: comps)
                                                } else {
                                                    appState.isFocusRemindersEnabled = false
                                                }
                                            }
                                        } else {
                                            NotificationService.shared.cancelReminders()
                                        }
                                    }
                                    
                                    if appState.isFocusRemindersEnabled {
                                        DatePicker(
                                            "Reminder Time",
                                            selection: $reminderTime,
                                            displayedComponents: .hourAndMinute
                                        )
                                        .onChange(of: reminderTime) { _, newTime in
                                            let comps = Calendar.current.dateComponents([.hour, .minute], from: newTime)
                                            NotificationService.shared.scheduleFocusReminder(at: comps)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // INTEGRATION & DATA
                        VStack(alignment: .leading, spacing: 8) {
                            Text("INTEGRATION & DATA")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 24)
                            
                            GlassCard(style: .thin) {
                                VStack(spacing: 14) {
                                    // GitHub OAuth Status
                                    HStack {
                                        Label("GitHub Integration", systemImage: "network")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        if gitHubAuth.isAuthenticated {
                                            Button("Connected") {
                                                gitHubAuth.signOut()
                                                withAnimation(.spring()) {
                                                    appState.currentUser = nil
                                                    appState.isGitHubConnected = false
                                                }
                                            }
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(AppColors.successGreen)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(AppColors.successGreen.opacity(0.15))
                                            .clipShape(Capsule())
                                        } else {
                                            Button("Connect Account") {
                                                appState.isGitHubConnectSheetPresented = true
                                            }
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(AppColors.accentCyan)
                                        }
                                    }
                                    
                                    if gitHubAuth.isAuthenticated {
                                        Divider()
                                        
                                        // Refresh GitHub Data button
                                        Button {
                                            Task {
                                                await refreshGitHubData()
                                            }
                                        } label: {
                                            HStack {
                                                Label {
                                                    Text(isRefreshingGitHub ? "Syncing GitHub Data..." : "Refresh GitHub Data")
                                                        .foregroundColor(.primary)
                                                } icon: {
                                                    if isRefreshingGitHub {
                                                        ProgressView()
                                                            .scaleEffect(0.8)
                                                    } else {
                                                        Image(systemName: "arrow.triangle.2.circlepath")
                                                            .foregroundColor(AppColors.accentCyan)
                                                    }
                                                }
                                                Spacer()
                                                if !isRefreshingGitHub {
                                                    Image(systemName: "chevron.right")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                        .disabled(isRefreshingGitHub)
                                        
                                        Divider()
                                        
                                        // Last synced timestamp
                                        HStack(spacing: 8) {
                                            Circle()
                                                .fill(isRefreshingGitHub ? AppColors.warningOrange : AppColors.successGreen)
                                                .frame(width: 7, height: 7)
                                            
                                            if isRefreshingGitHub {
                                                Text("Syncing repositories & events...")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            } else if let lastSync = lastSyncedDate {
                                                Text("Last synced \(lastSync.formatted(.relative(presentation: .named)))")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                Spacer()
                                                Text(lastSync.formatted(date: .omitted, time: .shortened))
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary.opacity(0.8))
                                            } else {
                                                Text("Last synced: Never")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        if let error = refreshError {
                                            Text("Sync error: \(error)")
                                                .font(.caption2)
                                                .foregroundColor(.red)
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    // Tracked Repositories Selector
                                    NavigationLink {
                                        RepoSelectorView()
                                    } label: {
                                        HStack {
                                            Label("Tracked Repositories", systemImage: "folder.badge.gearshape")
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Text(appState.selectedRepoNames.isEmpty ? "All" : "\(appState.selectedRepoNames.count) active")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    // Supabase Sync Toggle
                                    Toggle(isOn: Bindable(appState).isSupabaseSyncEnabled) {
                                        Label("Supabase Cloud Sync", systemImage: "icloud.and.arrow.up.fill")
                                            .foregroundColor(.primary)
                                    }
                                    
                                    // Supabase Sync status indicator
                                    if SyncEngine.shared.isSyncing {
                                        HStack(spacing: 8) {
                                            ProgressView().scaleEffect(0.8)
                                            Text("Syncing with Supabase...")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    } else if let lastSync = SyncEngine.shared.lastSyncDate {
                                        HStack(spacing: 6) {
                                            Circle()
                                                .fill(AppColors.successGreen)
                                                .frame(width: 7, height: 7)
                                            Text("Cloud synced \(lastSync.formatted(.relative(presentation: .named)))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // EXPORT SECTION
                        VStack(alignment: .leading, spacing: 8) {
                            Text("EXPORT")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 24)
                            
                            GlassCard(style: .thin) {
                                VStack(spacing: 14) {
                                    Button {
                                        ExportService.shareMarkdown(entries: journalEntries)
                                    } label: {
                                        HStack {
                                            Label("Export as Markdown", systemImage: "doc.text")
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Text("\(journalEntries.count) entries")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    Button {
                                        ExportService.sharePDF(entries: journalEntries)
                                    } label: {
                                        HStack {
                                            Label("Export as PDF", systemImage: "doc.richtext")
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Image(systemName: "arrow.up.doc")
                                                .foregroundColor(AppColors.accentCyan)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // ABOUT
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ABOUT")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 24)
                            
                            GlassCard(style: .ultraThin) {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("DevJournal for iOS")
                                            .fontWeight(.semibold)
                                        Spacer()
                                        Text("v1.0.0 (Build 1)")
                                            .foregroundColor(.secondary)
                                    }
                                    .font(.subheadline)
                                    
                                    Text("Designed with Swift, SwiftUI, SwiftData, and visionOS Glassmorphism.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // SIGN OUT BUTTON
                        VStack(spacing: 12) {
                            Button {
                                gitHubAuth.signOut()
                                withAnimation(.spring()) {
                                    appState.currentUser = nil
                                    appState.isGitHubConnected = false
                                    appState.isAuthenticated = false
                                    appState.selectedTab = .home
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Sign Out")
                                        .fontWeight(.bold)
                                }
                                .font(.headline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.red.opacity(0.12))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                                 )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 100)
                }
            }
            .sheet(isPresented: Bindable(appState).isGitHubConnectSheetPresented) {
                GitHubConnectSheet()
            }
            .task {
                if gitHubAuth.isAuthenticated {
                    if appState.currentUser == nil {
                        if let profile = try? await GitHubService.shared.fetchUserProfile() {
                            withAnimation(.spring()) {
                                appState.currentUser = profile
                                appState.isGitHubConnected = true
                            }
                        }
                    }
                    await fetchGitHubUserMetrics()
                    if lastSyncedTimestamp == 0 {
                        lastSyncedTimestamp = Date().timeIntervalSince1970
                    }
                }
            }
            .refreshable {
                if gitHubAuth.isAuthenticated {
                    await refreshGitHubData()
                }
            }
        }
    }
    
    @ViewBuilder
    private func userMetricItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    // MARK: - Data Fetching & Sync
    
    private func fetchGitHubUserMetrics() async {
        guard let token = KeychainService.shared.loadString(key: "github_access_token"), !token.isEmpty else {
            return
        }
        guard let url = URL(string: "https://api.github.com/user") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("DevJournal/1.0", forHTTPHeaderField: "User-Agent")
        request.assumesHTTP3Capable = false
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                await MainActor.run {
                    self.followersCount = json["followers"] as? Int
                    self.publicReposCount = json["public_repos"] as? Int
                    self.followingCount = json["following"] as? Int
                }
            }
        } catch {
            print("SettingsView: Failed to fetch user metrics: \(error)")
        }
        
        // Fallback for publicReposCount if not returned
        if self.publicReposCount == nil, let repos = try? await GitHubService.shared.fetchRepositories() {
            await MainActor.run {
                self.publicReposCount = repos.filter { !$0.isPrivate }.count
            }
        }
    }
    
    @MainActor
    private func refreshGitHubData() async {
        guard !isRefreshingGitHub else { return }
        isRefreshingGitHub = true
        refreshError = nil
        
        defer {
            isRefreshingGitHub = false
        }
        
        do {
            // 1. Fetch updated profile
            let profile = try await GitHubService.shared.fetchUserProfile()
            withAnimation(.spring()) {
                appState.currentUser = profile
                appState.isGitHubConnected = true
            }
            
            // 2. Fetch authenticated metrics (followers, public repos)
            await fetchGitHubUserMetrics()
            
            // 3. Fetch repositories
            _ = try? await GitHubService.shared.fetchRepositories()
            
            // 4. Trigger Supabase sync if enabled
            if appState.isSupabaseSyncEnabled {
                await SyncEngine.shared.syncAll(using: modelContext)
            }
            
            // 5. Update timestamp
            lastSyncedTimestamp = Date().timeIntervalSince1970
            
            #if canImport(UIKit)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            #endif
        } catch {
            refreshError = error.localizedDescription
            #if canImport(UIKit)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            #endif
        }
    }
}

struct GitHubConnectSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AtmosphericBackgroundView()
            
            VStack(spacing: 24) {
                Image(systemName: "cat.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(AppColors.primaryIndigo)
                
                VStack(spacing: 8) {
                    Text("Connect GitHub Account")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Synchronize your repositories, commits, pull requests, and issues directly into DevJournal.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                GlassButton(action: {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        GitHubAuthService.shared.startOAuthFlow(appState: appState)
                    }
                }) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                        Text("Authorize with GitHub OAuth")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 40)
                
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.secondary)
            }
            .padding(30)
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
}
