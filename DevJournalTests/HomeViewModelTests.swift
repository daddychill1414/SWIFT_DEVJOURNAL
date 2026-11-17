import XCTest
@testable import DevJournal

// Mock GitHubService for testing
final class MockGitHubService: GitHubServiceProtocol {
    var mockRepos: [GitHubRepository] = []
    var mockCommits: [GitHubCommit] = []
    var mockActivities: [GitHubActivityItem] = []
    var shouldThrowError = false
    var mockUserProfile: UserProfile?
    
    func fetchUserProfile() async throws -> UserProfile {
        if shouldThrowError { throw GitHubError.unauthenticated }
        return mockUserProfile ?? UserProfile(id: "1", name: "Test User", username: "testuser")
    }
    
    func fetchRepositories() async throws -> [GitHubRepository] {
        if shouldThrowError { throw GitHubError.unauthenticated }
        return mockRepos
    }
    
    func fetchRecentCommits(repoOwner: String, repoName: String) async throws -> [GitHubCommit] {
        if shouldThrowError { throw GitHubError.requestFailed(500) }
        return mockCommits
    }
    
    func fetchRecentCommits(repoOwner: String, repoName: String, page: Int, perPage: Int) async throws -> [GitHubCommit] {
        if shouldThrowError { throw GitHubError.requestFailed(500) }
        return mockCommits
    }
    
    func fetchUserActivity(username: String?, page: Int) async throws -> [GitHubActivityItem] {
        if shouldThrowError { throw GitHubError.unauthenticated }
        return mockActivities
    }
}

@MainActor
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
        XCTAssertEqual(viewModel.availableRepos, ["user/repo"])
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
    
    func testDynamicGreeting() {
        let viewModel = HomeViewModel()
        let calendar = Calendar.current
        
        // 8 AM -> Morning
        var morningComponents = DateComponents()
        morningComponents.hour = 8
        morningComponents.minute = 0
        if let morningDate = calendar.date(from: morningComponents) {
            XCTAssertEqual(viewModel.greeting(for: morningDate), "Good morning,")
        }
        
        // 2 PM (14:00) -> Afternoon
        var afternoonComponents = DateComponents()
        afternoonComponents.hour = 14
        afternoonComponents.minute = 0
        if let afternoonDate = calendar.date(from: afternoonComponents) {
            XCTAssertEqual(viewModel.greeting(for: afternoonDate), "Good afternoon,")
        }
        
        // 8 PM (20:00) -> Evening
        var eveningComponents = DateComponents()
        eveningComponents.hour = 20
        eveningComponents.minute = 0
        if let eveningDate = calendar.date(from: eveningComponents) {
            XCTAssertEqual(viewModel.greeting(for: eveningDate), "Good evening,")
        }
        
        // 2 AM (02:00) -> Evening / Night
        var nightComponents = DateComponents()
        nightComponents.hour = 2
        nightComponents.minute = 0
        if let nightDate = calendar.date(from: nightComponents) {
            XCTAssertEqual(viewModel.greeting(for: nightDate), "Good evening,")
        }
    }
    
    func testRepoFilteringAndSearch() async {
        let mockService = MockGitHubService()
        mockService.mockActivities = [
            GitHubActivityItem(message: "Add SwiftData container", repoName: "user/DevJournal", type: "commit"),
            GitHubActivityItem(message: "Fix layout bug", repoName: "user/DevJournal", type: "commit"),
            GitHubActivityItem(message: "Update README", repoName: "user/DocVault", type: "commit")
        ]
        
        let viewModel = HomeViewModel(gitHubService: mockService)
        await viewModel.fetchRecentActivities()
        
        XCTAssertEqual(viewModel.availableRepos.count, 2)
        XCTAssertTrue(viewModel.availableRepos.contains("user/DevJournal"))
        XCTAssertTrue(viewModel.availableRepos.contains("user/DocVault"))
        
        // No filter: 3 items
        XCTAssertEqual(viewModel.filteredActivities().count, 3)
        
        // Filter by user/DevJournal: 2 items
        viewModel.toggleRepoFilter("user/DevJournal")
        XCTAssertEqual(viewModel.selectedRepoFilter, "user/DevJournal")
        XCTAssertEqual(viewModel.filteredActivities().count, 2)
        
        // Filter by user/DevJournal + search "SwiftData": 1 item
        viewModel.searchText = "SwiftData"
        XCTAssertEqual(viewModel.filteredActivities().count, 1)
        
        // Clear repo filter by toggling again:
        viewModel.toggleRepoFilter("user/DevJournal")
        XCTAssertNil(viewModel.selectedRepoFilter)
        XCTAssertEqual(viewModel.filteredActivities().count, 1) // still searching SwiftData
        
        viewModel.searchText = ""
        XCTAssertEqual(viewModel.filteredActivities().count, 3)
    }
}
