//
//  HomeViewModel.swift
//  DevJournal
//

import SwiftUI

@MainActor
@Observable
final class HomeViewModel {
    var searchText: String = ""
    var isLoading: Bool = false
    var gitHubActivities: [GitHubActivityItem] = []
    var errorMessage: String?
    
    // Filtered activities based on selected repos
    var selectedRepoNames: Set<String> = []
    var selectedRepoFilter: String? = nil
    
    var availableRepos: [String] {
        var seen = Set<String>()
        var repos: [String] = []
        for activity in gitHubActivities {
            if !seen.contains(activity.repoName) {
                seen.insert(activity.repoName)
                repos.append(activity.repoName)
            }
        }
        return repos
    }
    
    func toggleRepoFilter(_ repo: String?) {
        if selectedRepoFilter == repo {
            selectedRepoFilter = nil
        } else {
            selectedRepoFilter = repo
        }
    }
    
    func filteredActivities(globalSelectedRepos: Set<String> = []) -> [GitHubActivityItem] {
        var items = gitHubActivities
        
        // 1. Repo filter chip priority (single tap selection)
        if let filter = selectedRepoFilter {
            items = items.filter { $0.repoName == filter }
        } else if !globalSelectedRepos.isEmpty {
            items = items.filter { globalSelectedRepos.contains($0.repoName) }
        } else if !selectedRepoNames.isEmpty {
            items = items.filter { selectedRepoNames.contains($0.repoName) }
        }
        
        // 2. Search filter
        if !searchText.isEmpty {
            items = items.filter {
                $0.message.localizedCaseInsensitiveContains(searchText) ||
                $0.repoName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return items
    }
    
    var filteredActivities: [GitHubActivityItem] {
        filteredActivities(globalSelectedRepos: selectedRepoNames)
    }
    
    // Dynamic Greeting based on time of day
    func greeting(for date: Date = Date()) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12:
            return "Good morning,"
        case 12..<17:
            return "Good afternoon,"
        default:
            return "Good evening,"
        }
    }
    
    var currentGreeting: String {
        greeting(for: Date())
    }
    
    // Today's Progress — populated from SwiftData queries
    var progressPercent: Double = 0.0
    var focusHoursText: String = "0h 0m focused"
    var completedTasksCount: Int = 0
    
    @ObservationIgnored
    private let gitHubService: GitHubServiceProtocol
    
    init(gitHubService: GitHubServiceProtocol = GitHubService.shared) {
        self.gitHubService = gitHubService
    }
    
    func fetchRecentActivities(username: String? = nil) async {
        isLoading = true
        errorMessage = nil
        do {
            self.gitHubActivities = try await gitHubService.fetchUserActivity(username: username, page: 1)
        } catch {
            print("HomeViewModel: Failed to fetch activities: \(error)")
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func computeTodayProgress(entries: [JournalEntry], sessions: [FocusSession]) {
        let calendar = Calendar.current
        let todayEntries = entries.filter { calendar.isDateInToday($0.date) }
        let todaySessions = sessions.filter { calendar.isDateInToday($0.startTime) }
        
        let totalHours = todayEntries.reduce(0.0) { $0 + $1.hoursSpent }
        let focusMinutes = todaySessions.filter { $0.isCompleted }.reduce(0) { $0 + $1.durationMinutes }
        
        let hours = Int(totalHours) + (focusMinutes / 60)
        let minutes = Int((totalHours.truncatingRemainder(dividingBy: 1)) * 60) + (focusMinutes % 60)
        
        self.focusHoursText = "\(hours)h \(minutes)m focused"
        self.completedTasksCount = todayEntries.count + todaySessions.filter { $0.isCompleted }.count
        self.progressPercent = min(totalHours / 8.0, 1.0) // 8-hour daily goal
    }
}
