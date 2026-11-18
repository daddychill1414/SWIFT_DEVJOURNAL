//
//  InsightsView.swift
//  DevJournal
//

import SwiftUI
import SwiftData
import Charts

struct FocusTimeData: Identifiable {
    let id = UUID()
    let day: String
    let hours: Double
}

struct DailyCommitData: Identifiable {
    let id = UUID()
    let date: Date
    let dayLabel: String
    let count: Int
}

struct ActiveRepoSummary: Identifiable {
    var id: String { fullName }
    let name: String
    let fullName: String
    let activityCount: Int
    let commitCount: Int
    let language: String?
    let description: String?
    let stargazersCount: Int
    let forksCount: Int
}

struct LanguageStat: Identifiable {
    var id: String { name }
    let name: String
    let count: Int
    let percentage: Double
    let color: Color
}

struct InsightsView: View {
    @Environment(AppState.self) private var appState
    @StateObject private var gitHubAuth = GitHubAuthService.shared
    
    @Query(sort: \JournalEntry.date, order: .reverse) private var journalEntries: [JournalEntry]
    @Query(sort: \FocusSession.startTime, order: .reverse) private var focusSessions: [FocusSession]
    @Query(sort: \GitHubActivityItem.timestamp, order: .reverse) private var storedActivities: [GitHubActivityItem]
    
    private var userJournalEntries: [JournalEntry] {
        guard let currentUsername = appState.currentUser?.username, !currentUsername.isEmpty else {
            return journalEntries.filter { $0.ownerUsername == nil }
        }
        return journalEntries.filter { $0.ownerUsername == currentUsername }
    }
    
    private var userFocusSessions: [FocusSession] {
        guard let currentUsername = appState.currentUser?.username, !currentUsername.isEmpty else {
            return focusSessions.filter { $0.ownerUsername == nil }
        }
        return focusSessions.filter { $0.ownerUsername == currentUsername }
    }
    
    enum InsightsSection: String, CaseIterable {
        case all = "Overview"
        case git = "Git Activity"
        case focus = "Focus & Time"
    }
    
    enum DateRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    @State private var selectedSection: InsightsSection = .all
    @State private var selectedRange: DateRange = .week
    
    // GitHub live-fetched data
    @State private var fetchedActivities: [GitHubActivityItem] = []
    @State private var fetchedRepos: [GitHubRepository] = []
    @State private var isLoadingGitHub = false
    @State private var gitHubError: String? = nil
    
    private var allActivities: [GitHubActivityItem] {
        if !fetchedActivities.isEmpty {
            return fetchedActivities
        }
        guard let currentUsername = appState.currentUser?.username, !currentUsername.isEmpty else {
            return []
        }
        return storedActivities.filter { $0.author.isEmpty || $0.author.lowercased() == currentUsername.lowercased() }
    }
    
    // MARK: - Daily Commits (Last 30 Days)
    
    private var dailyCommits: [DailyCommitData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let commitActivities = allActivities.filter { $0.type.lowercased() == "commit" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        
        return (0..<30).reversed().compactMap { daysAgo in
            guard let dayDate = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { return nil }
            let nextDay = calendar.date(byAdding: .day, value: 1, to: dayDate) ?? dayDate
            
            let count = commitActivities.filter { act in
                act.timestamp >= dayDate && act.timestamp < nextDay
            }.count
            
            return DailyCommitData(
                date: dayDate,
                dayLabel: formatter.string(from: dayDate),
                count: count
            )
        }
    }
    
    private var effectiveDailyCommits: [DailyCommitData] {
        if gitHubAuth.isAuthenticated {
            return dailyCommits
        } else {
            // Preview pattern when not authenticated
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM"
            let mockPattern = [2, 0, 4, 1, 5, 3, 0, 1, 6, 4, 2, 7, 3, 0, 2, 5, 8, 4, 3, 1, 0, 6, 5, 9, 4, 2, 1, 7, 5, 3]
            return (0..<30).reversed().enumerated().compactMap { index, daysAgo in
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { return nil }
                return DailyCommitData(
                    date: date,
                    dayLabel: formatter.string(from: date),
                    count: mockPattern[index % mockPattern.count]
                )
            }
        }
    }
    
    private var totalCommitsIn30Days: Int {
        effectiveDailyCommits.reduce(0) { $0 + $1.count }
    }
    
    private var peakDailyCommits: Int {
        effectiveDailyCommits.map { $0.count }.max() ?? 0
    }
    
    // MARK: - Most Active Repositories
    
    private var mostActiveRepos: [ActiveRepoSummary] {
        if gitHubAuth.isAuthenticated {
            var counts: [String: (total: Int, commits: Int)] = [:]
            for act in allActivities {
                let key = act.repoName
                let isCommit = act.type.lowercased() == "commit"
                counts[key, default: (0, 0)].total += 1
                if isCommit {
                    counts[key, default: (0, 0)].commits += 1
                }
            }
            
            let reposByName = Dictionary(uniqueKeysWithValues: fetchedRepos.map { ($0.name, $0) })
            let reposByFullName = Dictionary(uniqueKeysWithValues: fetchedRepos.map { ($0.fullName, $0) })
            
            var list: [ActiveRepoSummary] = []
            for (repoKey, stat) in counts {
                let matchedRepo = reposByFullName[repoKey]
                    ?? reposByName[repoKey]
                    ?? reposByName[repoKey.components(separatedBy: "/").last ?? ""]
                
                let displayName = repoKey.components(separatedBy: "/").last ?? repoKey
                list.append(
                    ActiveRepoSummary(
                        name: displayName,
                        fullName: matchedRepo?.fullName ?? repoKey,
                        activityCount: stat.total,
                        commitCount: stat.commits,
                        language: matchedRepo?.language,
                        description: matchedRepo?.description,
                        stargazersCount: matchedRepo?.stargazersCount ?? 0,
                        forksCount: matchedRepo?.forksCount ?? 0
                    )
                )
            }
            
            list.sort { $0.activityCount > $1.activityCount }
            
            if list.isEmpty && !fetchedRepos.isEmpty {
                return fetchedRepos.prefix(5).map { repo in
                    ActiveRepoSummary(
                        name: repo.name,
                        fullName: repo.fullName,
                        activityCount: max(1, repo.stargazersCount + repo.openIssuesCount),
                        commitCount: 0,
                        language: repo.language,
                        description: repo.description,
                        stargazersCount: repo.stargazersCount,
                        forksCount: repo.forksCount
                    )
                }
            }
            return list
        } else {
            return [
                ActiveRepoSummary(
                    name: "DevJournal",
                    fullName: "developer/DevJournal",
                    activityCount: 24,
                    commitCount: 18,
                    language: "Swift",
                    description: "VisionOS-inspired Developer Journal & Focus Tracker for iOS",
                    stargazersCount: 128,
                    forksCount: 14
                ),
                ActiveRepoSummary(
                    name: "NeuralEngine",
                    fullName: "developer/NeuralEngine",
                    activityCount: 11,
                    commitCount: 8,
                    language: "Python",
                    description: "High-performance inference engine for local LLMs",
                    stargazersCount: 84,
                    forksCount: 9
                ),
                ActiveRepoSummary(
                    name: "WebPortal",
                    fullName: "developer/WebPortal",
                    activityCount: 6,
                    commitCount: 4,
                    language: "TypeScript",
                    description: "Dashboard web interface and documentation portal",
                    stargazersCount: 32,
                    forksCount: 3
                )
            ]
        }
    }
    
    // MARK: - Language Breakdown
    
    private var languageBreakdown: [LanguageStat] {
        let sourceRepos: [GitHubRepository]
        if gitHubAuth.isAuthenticated && !fetchedRepos.isEmpty {
            sourceRepos = fetchedRepos
        } else if !gitHubAuth.isAuthenticated {
            return [
                LanguageStat(name: "Swift", count: 8, percentage: 53.3, color: colorForLanguage("Swift")),
                LanguageStat(name: "TypeScript", count: 4, percentage: 26.7, color: colorForLanguage("TypeScript")),
                LanguageStat(name: "Python", count: 2, percentage: 13.3, color: colorForLanguage("Python")),
                LanguageStat(name: "Rust", count: 1, percentage: 6.7, color: colorForLanguage("Rust"))
            ]
        } else {
            return []
        }
        
        var counts: [String: Int] = [:]
        for repo in sourceRepos {
            if let lang = repo.language, !lang.isEmpty {
                counts[lang, default: 0] += 1
            }
        }
        
        let total = counts.values.reduce(0, +)
        guard total > 0 else { return [] }
        
        return counts
            .sorted { $0.value > $1.value }
            .map { (name, count) in
                let pct = (Double(count) / Double(total)) * 100.0
                return LanguageStat(
                    name: name,
                    count: count,
                    percentage: pct,
                    color: colorForLanguage(name)
                )
            }
    }
    
    private func colorForLanguage(_ language: String) -> Color {
        switch language.lowercased() {
        case "swift":
            return Color(red: 0.98, green: 0.33, blue: 0.22)
        case "typescript":
            return Color(red: 0.19, green: 0.47, blue: 0.78)
        case "javascript":
            return Color(red: 0.95, green: 0.85, blue: 0.25)
        case "python":
            return Color(red: 0.21, green: 0.47, blue: 0.69)
        case "rust":
            return Color(red: 0.87, green: 0.35, blue: 0.17)
        case "go":
            return Color(red: 0.00, green: 0.68, blue: 0.85)
        case "c++", "cpp":
            return Color(red: 0.96, green: 0.28, blue: 0.54)
        case "c#", "csharp":
            return Color(red: 0.10, green: 0.60, blue: 0.20)
        case "html":
            return Color(red: 0.89, green: 0.30, blue: 0.18)
        case "css":
            return Color(red: 0.34, green: 0.22, blue: 0.84)
        case "kotlin":
            return Color(red: 0.65, green: 0.31, blue: 0.84)
        case "ruby":
            return Color(red: 0.80, green: 0.15, blue: 0.15)
        default:
            return AppColors.accentCyan
        }
    }
    
    // MARK: - Focus Time Data
    
    private var filteredFocusData: [FocusTimeData] {
        let calendar = Calendar.current
        let today = Date()
        let dayFormatter = DateFormatter()
        
        if selectedRange == .year {
            dayFormatter.dateFormat = "MMM"
            return (0..<12).reversed().map { monthsAgo in
                guard let monthDate = calendar.date(byAdding: .month, value: -monthsAgo, to: today),
                      let interval = calendar.dateInterval(of: .month, for: monthDate) else {
                    return FocusTimeData(day: "", hours: 0)
                }
                let monthEntries = userJournalEntries.filter { $0.date >= interval.start && $0.date < interval.end }
                let monthFocus  = userFocusSessions.filter  { $0.startTime >= interval.start && $0.startTime < interval.end && $0.isCompleted }
                let totalHours = monthEntries.reduce(0.0) { $0 + $1.hoursSpent }
                    + Double(monthFocus.reduce(0) { $0 + $1.durationMinutes }) / 60.0
                return FocusTimeData(day: dayFormatter.string(from: monthDate), hours: totalHours)
            }
        } else {
            let daysBack = selectedRange == .week ? 7 : 30
            dayFormatter.dateFormat = selectedRange == .week ? "EEE" : "d"
            return (0..<daysBack).reversed().map { daysAgo in
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else {
                    return FocusTimeData(day: "", hours: 0)
                }
                let dayEntries = userJournalEntries.filter { calendar.isDate($0.date, inSameDayAs: date) }
                let dayFocus   = userFocusSessions.filter  { calendar.isDate($0.startTime, inSameDayAs: date) && $0.isCompleted }
                let totalHours = dayEntries.reduce(0.0) { $0 + $1.hoursSpent }
                    + Double(dayFocus.reduce(0) { $0 + $1.durationMinutes }) / 60.0
                return FocusTimeData(day: dayFormatter.string(from: date), hours: totalHours)
            }
        }
    }
    
    private var totalWeeklyHours: Double {
        filteredFocusData.reduce(0.0) { $0 + $1.hours }
    }
    
    private var dailyAvgHours: Double {
        let activeDays = filteredFocusData.filter { $0.hours > 0 }.count
        return activeDays > 0 ? totalWeeklyHours / Double(activeDays) : 0
    }
    
    private var longestFocusMinutes: Int {
        userFocusSessions.filter { $0.isCompleted }.map { $0.durationMinutes }.max() ?? 0
    }
    
    private var productivityScore: Int {
        let hoursScore = min(totalWeeklyHours / 35.0, 1.0) * 60
        let consistencyScore = Double(filteredFocusData.filter { $0.hours > 0 }.count) / Double(filteredFocusData.count) * 40
        return min(Int(hoursScore + consistencyScore), 100)
    }
    
    private func formatDuration(_ totalMinutes: Int) -> String {
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        return "\(h)h \(m)m"
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackgroundView()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title Header
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Insights")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                Text("Activity, focus, and development patterns")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if isLoadingGitHub {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        // Section Scope Picker
                        Picker("Insights Section", selection: $selectedSection) {
                            ForEach(InsightsSection.allCases, id: \.self) { section in
                                Text(section.rawValue).tag(section)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 20)
                        
                        // Not authenticated preview banner
                        if !gitHubAuth.isAuthenticated && selectedSection != .focus {
                            GlassCard(style: .thin, strokeColor: AppColors.accentCyan.opacity(0.3)) {
                                HStack(spacing: 12) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(AppColors.accentCyan)
                                        .font(.title3)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Sample Preview Mode")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                        Text("Connect GitHub in Settings to display your live commit trends and repository analytics.")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // MARK: - Git & GitHub Analytics Sections
                        if selectedSection == .all || selectedSection == .git {
                            gitAnalyticsSection
                        }
                        
                        // MARK: - Focus & Productivity Sections
                        if selectedSection == .all || selectedSection == .focus {
                            focusAnalyticsSection
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .task {
                await loadGitHubData()
            }
            .refreshable {
                await loadGitHubData()
            }
            .onChange(of: gitHubAuth.isAuthenticated) { _, isAuthed in
                if isAuthed {
                    Task {
                        await loadGitHubData()
                    }
                } else {
                    fetchedActivities = []
                    fetchedRepos = []
                }
            }
            .onChange(of: appState.currentUser?.username) { _, newUsername in
                if newUsername != nil {
                    Task {
                        await loadGitHubData()
                    }
                }
            }
        }
    }
    
    // MARK: - Git Analytics View
    
    @ViewBuilder
    private var gitAnalyticsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Section Header
            HStack {
                Text("GIT ACTIVITY & REPOSITORIES")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Spacer()
                if gitHubAuth.isAuthenticated {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(AppColors.successGreen)
                            .frame(width: 6, height: 6)
                        Text("Live GitHub")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
            
            // 1. Commits-per-day Chart (Last 30 Days)
            VStack(alignment: .leading, spacing: 10) {
                Text("Commits (Last 30 Days)")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 24)
                
                GlassCard(style: .thin) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Total Commits")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text("\(totalCommitsIn30Days)")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(AppColors.accentCyan)
                                    Text("commits")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 16) {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Daily Avg")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.1f", Double(totalCommitsIn30Days) / 30.0))
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                }
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Peak Day")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("\(peakDailyCommits)")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(AppColors.warningOrange)
                                }
                            }
                        }
                        
                        Divider()
                        
                        Chart(effectiveDailyCommits) { item in
                            BarMark(
                                x: .value("Day", item.date, unit: .day),
                                y: .value("Commits", item.count)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppColors.accentCyan, AppColors.primaryIndigo],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(3)
                        }
                        .frame(height: 180)
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                                if let date = value.as(Date.self) {
                                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        
                        if gitHubAuth.isAuthenticated && totalCommitsIn30Days == 0 {
                            Text("No commit events detected in recent 30-day activity feed. Push code to your repositories to see live spikes!")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // 2. Most Active Repository Summary
            if let topRepo = mostActiveRepos.first {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Most Active Repository")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 24)
                    
                    GlassCard(style: .regular, strokeColor: AppColors.accentCyan.opacity(0.35)) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: "flame.fill")
                                        .foregroundColor(AppColors.warningOrange)
                                    Text("TOP PROJECT")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(AppColors.warningOrange)
                                }
                                
                                Spacer()
                                
                                if let lang = topRepo.language {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(colorForLanguage(lang))
                                            .frame(width: 8, height: 8)
                                        Text(lang)
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.white.opacity(0.08))
                                    .clipShape(Capsule())
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(topRepo.name)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                if let desc = topRepo.description, !desc.isEmpty {
                                    Text(desc)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            
                            Divider()
                            
                            HStack(spacing: 16) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.triangle.branch")
                                        .font(.caption)
                                        .foregroundColor(AppColors.accentCyan)
                                    Text("\(topRepo.activityCount) activities")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                }
                                
                                if topRepo.commitCount > 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(AppColors.successGreen)
                                        Text("\(topRepo.commitCount) commits")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                    }
                                }
                                
                                Spacer()
                                
                                HStack(spacing: 10) {
                                    HStack(spacing: 2) {
                                        Image(systemName: "star.fill")
                                            .font(.caption2)
                                            .foregroundColor(AppColors.warningOrange)
                                        Text("\(topRepo.stargazersCount)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack(spacing: 2) {
                                        Image(systemName: "tuningfork")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text("\(topRepo.forksCount)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            // Secondary active repositories list
                            if mostActiveRepos.count > 1 {
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Other Active Repositories")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                    
                                    ForEach(Array(mostActiveRepos.dropFirst().prefix(3))) { repo in
                                        HStack {
                                            Text(repo.name)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                            
                                            Spacer()
                                            
                                            if let lang = repo.language {
                                                HStack(spacing: 3) {
                                                    Circle()
                                                        .fill(colorForLanguage(lang))
                                                        .frame(width: 6, height: 6)
                                                    Text(lang)
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            
                                            Text("\(repo.activityCount) events")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(AppColors.accentCyan)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            // 3. Language Breakdown Chart
            if !languageBreakdown.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Language Breakdown")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 24)
                    
                    GlassCard(style: .thin) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Repository Languages")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(languageBreakdown.count) detected")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 20) {
                                // Swift Charts Donut Chart (SectorMark)
                                Chart(languageBreakdown) { item in
                                    SectorMark(
                                        angle: .value("Percentage", item.percentage),
                                        innerRadius: .ratio(0.62),
                                        angularInset: 1.5
                                    )
                                    .foregroundStyle(item.color)
                                    .cornerRadius(4)
                                }
                                .frame(width: 125, height: 125)
                                .overlay {
                                    VStack(spacing: 2) {
                                        Text("\(Int(languageBreakdown.first?.percentage ?? 0))%")
                                            .font(.system(size: 20, weight: .bold, design: .rounded))
                                            .foregroundColor(.primary)
                                        Text(languageBreakdown.first?.name ?? "")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                
                                // Legend
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(languageBreakdown.prefix(5)) { item in
                                        HStack(spacing: 8) {
                                            Circle()
                                                .fill(item.color)
                                                .frame(width: 8, height: 8)
                                            
                                            Text(item.name)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                            
                                            Spacer()
                                            
                                            Text(String(format: "%.0f%%", item.percentage))
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    // MARK: - Focus & Productivity View
    
    @ViewBuilder
    private var focusAnalyticsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Section Header
            HStack {
                Text("FOCUS & PRODUCTIVITY")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Spacer()
                Picker("Range", selection: $selectedRange) {
                    ForEach(DateRange.allCases, id: \.self) { r in
                        Text(r.rawValue).tag(r)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 180)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
            
            // Productivity Score Card
            GlassCard(style: .regular) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Productivity Score")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(productivityScore)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.accentCyan)
                            Text("/ 100")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(productivityScore >= 80 ? "Outstanding productivity this week!" : productivityScore >= 50 ? "Good progress — keep building momentum." : "Log more sessions to boost your score.")
                            .font(.caption)
                            .foregroundColor(productivityScore >= 80 ? AppColors.successGreen : .secondary)
                    }
                    Spacer()
                    
                    Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                        .font(.system(size: 54))
                        .foregroundStyle(AppColors.primaryIndigo, AppColors.accentCyan)
                }
            }
            .padding(.horizontal, 20)
            
            // Key Metrics Row
            HStack(spacing: 12) {
                metricBox(title: "Longest Focus", value: formatDuration(longestFocusMinutes), icon: "bolt.fill")
                metricBox(title: "Total Focus", value: formatDuration(Int(totalWeeklyHours * 60)), icon: "clock.fill")
                metricBox(title: "Daily Avg", value: formatDuration(Int(dailyAvgHours * 60)), icon: "flame.fill")
            }
            .padding(.horizontal, 20)
            
            // Focus Time Trend Chart
            VStack(alignment: .leading, spacing: 12) {
                Text("Focus Time Trend (\(selectedRange.rawValue))")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 24)
                
                GlassCard(style: .thin) {
                    Chart(filteredFocusData) { data in
                        BarMark(
                            x: .value("Day", data.day),
                            y: .value("Hours", data.hours)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.primaryIndigo, AppColors.accentCyan],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(6)
                    }
                    .frame(height: 180)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Developer Insight Card
            GlassCard(style: .regular, strokeColor: AppColors.secondaryPurple.opacity(0.4)) {
                HStack(spacing: 16) {
                    Image(systemName: "lightbulb.max.fill")
                        .font(.system(size: 32))
                        .foregroundColor(AppColors.warningOrange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Developer Insight")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.warningOrange)
                        
                        Text(totalWeeklyHours > 0 ? "You logged \(String(format: "%.1f", totalWeeklyHours)) hours this week." : "Start logging focus sessions to see insights.")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(totalWeeklyHours > 0 ? "Keep consistent daily sessions to maximize productivity." : "Add journal entries or complete focus sessions to track your progress.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    private func metricBox(title: String, value: String, icon: String) -> some View {
        GlassCard(style: .ultraThin, padding: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(AppColors.accentCyan)
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Data Loading
    
    private func loadGitHubData() async {
        guard gitHubAuth.isAuthenticated else { return }
        isLoadingGitHub = true
        gitHubError = nil
        defer { isLoadingGitHub = false }
        
        do {
            if appState.currentUser == nil {
                if let profile = try? await GitHubService.shared.fetchUserProfile() {
                    withAnimation(.spring()) {
                        appState.currentUser = profile
                        appState.isGitHubConnected = true
                    }
                }
            }
            
            async let activitiesTask = GitHubService.shared.fetchUserActivity(username: appState.currentUser?.username)
            async let reposTask = GitHubService.shared.fetchRepositories()
            
            let (acts, repos) = try await (activitiesTask, reposTask)
            await MainActor.run {
                self.fetchedActivities = acts
                self.fetchedRepos = repos
            }
        } catch {
            print("InsightsView: Failed to load GitHub data: \(error)")
            self.gitHubError = error.localizedDescription
        }
    }
}

#Preview {
    InsightsView()
        .environment(AppState())
}
