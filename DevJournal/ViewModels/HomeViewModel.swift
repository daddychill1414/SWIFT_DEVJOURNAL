//
//  HomeViewModel.swift
//  DevJournal
//

import SwiftUI
import Observation

@Observable
final class HomeViewModel {
    var searchText: String = ""
    var isLoading: Bool = false
    var gitHubActivities: [GitHubActivityItem] = []
    var errorMessage: String?
    
    // Sample stats for Today's Progress
    var progressPercent: Double = 0.75
    var focusHoursText: String = "6h 15m focused"
    var completedTasksCount: Int = 12
    
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
}
