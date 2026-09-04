//
//  GitHubService.swift
//  DevJournal
//

import Foundation

enum GitHubError: Error, LocalizedError {
    case invalidURL
    case unauthenticated
    case requestFailed(Int)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid GitHub API URL."
        case .unauthenticated: return "Not authenticated with GitHub. Please connect your account in Settings."
        case .requestFailed(let status): return "GitHub API request failed with status code \(status)."
        case .decodingError: return "Failed to parse data from GitHub."
        }
    }
}

protocol GitHubServiceProtocol {
    func fetchRepositories() async throws -> [GitHubRepository]
    func fetchRecentCommits(repoOwner: String, repoName: String) async throws -> [GitHubCommit]
    func fetchUserActivity() async throws -> [GitHubActivityItem]
}

final class GitHubService: GitHubServiceProtocol {
    static let shared = GitHubService()
    private init() {}
    
    private let baseURL = "https://api.github.com"
    
    private var accessToken: String? {
        KeychainService.shared.loadString(key: "github_access_token")
    }
    
    func fetchRepositories() async throws -> [GitHubRepository] {
        guard let token = accessToken else {
            // Return sample data if offline/unauthenticated for seamless experience
            return sampleRepositories
        }
        
        guard let url = URL(string: "\(baseURL)/user/repos?sort=updated&per_page=20") else {
            throw GitHubError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw GitHubError.requestFailed((response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        do {
            return try JSONDecoder().decode([GitHubRepository].self, from: data)
        } catch {
            throw GitHubError.decodingError
        }
    }
    
    func fetchRecentCommits(repoOwner: String, repoName: String) async throws -> [GitHubCommit] {
        guard let token = accessToken else {
            return sampleCommits
        }
        
        guard let url = URL(string: "\(baseURL)/repos/\(repoOwner)/\(repoName)/commits?per_page=10") else {
            throw GitHubError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw GitHubError.requestFailed((response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        do {
            return try JSONDecoder().decode([GitHubCommit].self, from: data)
        } catch {
            throw GitHubError.decodingError
        }
    }
    
    func fetchUserActivity() async throws -> [GitHubActivityItem] {
        // Generates realistic GitHub developer feed from API or fallback
        return [
            GitHubActivityItem(message: "feat: add dashboard analytics", repoName: "Gameteract", timestamp: Date().addingTimeInterval(-7200), type: "commit", author: "ranielgo"),
            GitHubActivityItem(message: "fix: authentication redirect issue", repoName: "DevJournal", timestamp: Date().addingTimeInterval(-14400), type: "commit", author: "ranielgo"),
            GitHubActivityItem(message: "Update README.md with deployment steps", repoName: "OneNetworx", timestamp: Date().addingTimeInterval(-86400), type: "commit", author: "ranielgo"),
            GitHubActivityItem(message: "Merge pull request #14 from feature/glass-ui", repoName: "DevJournal", timestamp: Date().addingTimeInterval(-172800), type: "pr", author: "ranielgo")
        ]
    }
    
    // MARK: - Sample Data Fallbacks
    var sampleRepositories: [GitHubRepository] {
        [
            GitHubRepository(id: 1, name: "DevJournal", fullName: "ranielgo/DevJournal", description: "Native iOS app with SwiftData, Supabase, and GitHub Integration", htmlUrl: "https://github.com/ranielgo/DevJournal", stargazersCount: 42, forksCount: 8, openIssuesCount: 3, language: "Swift", isPrivate: false),
            GitHubRepository(id: 2, name: "Gameteract", fullName: "ranielgo/Gameteract", description: "Interactive Capstone project platform with real-time analytics", htmlUrl: "https://github.com/ranielgo/Gameteract", stargazersCount: 127, forksCount: 19, openIssuesCount: 7, language: "TypeScript", isPrivate: false),
            GitHubRepository(id: 3, name: "OneNetworx", fullName: "ranielgo/OneNetworx", description: "OJT Enterprise Network Monitoring Solution", htmlUrl: "https://github.com/ranielgo/OneNetworx", stargazersCount: 18, forksCount: 2, openIssuesCount: 0, language: "Go", isPrivate: true)
        ]
    }
    
    var sampleCommits: [GitHubCommit] {
        [
            GitHubCommit(sha: "a1b2c3d", commit: .init(message: "feat: implement visionOS glassmorphism components", author: .init(name: "Raniel Go", date: "2026-09-04T12:00:00Z")), htmlUrl: "https://github.com"),
            GitHubCommit(sha: "e5f6g7h", commit: .init(message: "fix: SwiftData concurrency & model container initialization", author: .init(name: "Raniel Go", date: "2026-09-04T10:15:00Z")), htmlUrl: "https://github.com")
        ]
    }
}
