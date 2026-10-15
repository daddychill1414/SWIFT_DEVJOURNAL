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
    
    func fetchRecentCommits(repoOwner: String, repoName: String, page: Int, perPage: Int) async throws -> [GitHubCommit] {
        if shouldThrowError { throw GitHubError.requestFailed(500) }
        return mockCommits
    }
    
    func fetchUserActivity() async throws -> [GitHubActivityItem] {
        if shouldThrowError { throw GitHubError.unauthenticated }
        return mockActivities
    }
    
    func fetchUserActivity(page: Int) async throws -> [GitHubActivityItem] {
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
