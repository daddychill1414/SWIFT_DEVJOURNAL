//
//  HomeViewModel.swift
//  DevJournal
//

import SwiftUI

@Observable

final class HomeViewModel {
    var searchText: String = ""
    var isLoading: Bool = false
    var gitHubActivities: [GitHubActivityItem] = []
    var errorMessage: String?
    
    // Today's Progress — populated from SwiftData queries
    var progressPercent: Double = 0.0
    var focusHoursText: String = "0h 0m focused"
    var completedTasksCount: Int = 0
    
    @ObservationIgnored
    private let gitHubService: GitHubServiceProtocol
    
    init(gitHubService: GitHubServiceProtocol = GitHubService.shared) {
        self.gitHubService = gitHubService
    }
    
    func fetchRecentActivities() async {
        isLoading = true
        errorMessage = nil
        do {
            self.gitHubActivities = try await gitHubService.fetchUserActivity()
        } catch {
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
