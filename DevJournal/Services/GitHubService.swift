//
//  GitHubService.swift
//  DevJournal
//
//  Handles all GitHub REST API calls: repositories, commits (paginated),
//  and user activity events (fully parsed, not an empty array).
//

import Foundation

enum GitHubError: Error, LocalizedError {
    case invalidURL
    case unauthenticated
    case requestFailed(Int)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:        return "Invalid GitHub API URL."
        case .unauthenticated:   return "Not authenticated with GitHub. Please connect your account in Settings."
        case .requestFailed(let s): return "GitHub API request failed with status code \(s)."
        case .decodingError:     return "Failed to parse data from GitHub."
        }
    }
}

protocol GitHubServiceProtocol {
    func fetchUserProfile() async throws -> UserProfile
    func fetchRepositories() async throws -> [GitHubRepository]
    func fetchRecentCommits(repoOwner: String, repoName: String, page: Int, perPage: Int) async throws -> [GitHubCommit]
    func fetchUserActivity(username: String?, page: Int) async throws -> [GitHubActivityItem]
}

// Convenience default arguments for protocol callers
extension GitHubServiceProtocol {
    func fetchRecentCommits(repoOwner: String, repoName: String, page: Int = 1, perPage: Int = 30) async throws -> [GitHubCommit] {
        try await fetchRecentCommits(repoOwner: repoOwner, repoName: repoName, page: page, perPage: perPage)
    }
    func fetchUserActivity(username: String? = nil, page: Int = 1) async throws -> [GitHubActivityItem] {
        try await fetchUserActivity(username: username, page: page)
    }
}

final class GitHubService: GitHubServiceProtocol {
    static let shared = GitHubService()
    private init() {}
    
    private let baseURL = "https://api.github.com"
    private(set) var cachedProfile: UserProfile?
    
    func clearCachedProfile() {
        cachedProfile = nil
    }
    
    private var accessToken: String? {
        KeychainService.shared.loadString(key: "github_access_token")
    }
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        config.httpCookieStorage = nil
        config.httpShouldSetCookies = false
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 15
        return URLSession(configuration: config)
    }()
    
    // MARK: - Generic Paginated Fetch
    
    private func fetchPaginated<T: Decodable>(
        path: String,
        page: Int = 1,
        perPage: Int = 30
    ) async throws -> [T] {
        guard let token = accessToken, !token.isEmpty else {
            throw GitHubError.unauthenticated
        }
        let separator = path.contains("?") ? "&" : "?"
        let urlString = "\(baseURL)\(path)\(separator)page=\(page)&per_page=\(perPage)"
        guard let url = URL(string: urlString) else {
            throw GitHubError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("DevJournal/1.0", forHTTPHeaderField: "User-Agent")
        request.assumesHTTP3Capable = false
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? 500
            print("GitHubService: Request to \(path) failed with status: \(status)")
            throw GitHubError.requestFailed(status)
        }
        
        let decoder = JSONDecoder()
        do {
            return try decoder.decode([T].self, from: data)
        } catch {
            print("GitHubService decoding error on \(path): \(error)")
            throw GitHubError.decodingError
        }
    }
    
    // MARK: - User Profile
    
    func fetchUserProfile() async throws -> UserProfile {
        guard let token = accessToken, !token.isEmpty else {
            throw GitHubError.unauthenticated
        }
        guard let url = URL(string: "\(baseURL)/user") else {
            throw GitHubError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("DevJournal/1.0", forHTTPHeaderField: "User-Agent")
        request.assumesHTTP3Capable = false
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? 500
            print("GitHubService fetchUserProfile HTTP error: \(status)")
            throw GitHubError.requestFailed(status)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let login = json["login"] as? String else {
            throw GitHubError.decodingError
        }
        
        let name = json["name"] as? String ?? login
        let bio = json["bio"] as? String ?? "iOS Developer"
        let avatarUrl = json["avatar_url"] as? String
        let id = String(describing: json["id"] ?? UUID().uuidString)
        
        let profile = UserProfile(
            id: id,
            name: name,
            username: login,
            avatarUrl: avatarUrl,
            bio: bio,
            gitHubUsername: login
        )
        self.cachedProfile = profile
        return profile
    }
    
    // MARK: - Repositories
    
    func fetchRepositories() async throws -> [GitHubRepository] {
        return try await fetchPaginated(path: "/user/repos?sort=updated", perPage: 30)
    }
    
    // MARK: - Commits (paginated)
    
    func fetchRecentCommits(
        repoOwner: String,
        repoName: String,
        page: Int = 1,
        perPage: Int = 30
    ) async throws -> [GitHubCommit] {
        return try await fetchPaginated(
            path: "/repos/\(repoOwner)/\(repoName)/commits",
            page: page,
            perPage: perPage
        )
    }
    
    // MARK: - User Activity (properly parsed)
    
    func fetchUserActivity(username: String? = nil, page: Int = 1) async throws -> [GitHubActivityItem] {
        guard let token = accessToken, !token.isEmpty else {
            throw GitHubError.unauthenticated
        }
        
        let targetUsername: String
        if let username = username, !username.isEmpty {
            targetUsername = username
        } else if let cached = cachedProfile?.username {
            targetUsername = cached
        } else {
            let profile = try await fetchUserProfile()
            targetUsername = profile.username
        }
        
        guard let url = URL(string: "\(baseURL)/users/\(targetUsername)/events?per_page=30&page=\(page)") else {
            throw GitHubError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("DevJournal/1.0", forHTTPHeaderField: "User-Agent")
        request.assumesHTTP3Capable = false
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? 500
            print("GitHubService fetchUserActivity HTTP error: \(status)")
            throw GitHubError.requestFailed(status)
        }
        
        guard let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        
        let dateFormatter = ISO8601DateFormatter()
        
        return jsonArray.compactMap { event -> GitHubActivityItem? in
            guard let id = event["id"] as? String,
                  let type = event["type"] as? String,
                  let repoDict = event["repo"] as? [String: Any],
                  let repoName = repoDict["name"] as? String,
                  let createdAt = event["created_at"] as? String
            else { return nil }
            
            let actor = event["actor"] as? [String: Any]
            let login = actor?["login"] as? String ?? targetUsername
            
            let payload = event["payload"] as? [String: Any] ?? [:]
            
            let message: String
            let eventType: String
            
            switch type {
            case "PushEvent":
                let commits = payload["commits"] as? [[String: Any]]
                let ref = (payload["ref"] as? String)?.replacingOccurrences(of: "refs/heads/", with: "") ?? "main"
                let firstMsg = commits?.first?["message"] as? String ?? "Pushed commits to \(ref)"
                // Trim to first line of commit message
                message = firstMsg.components(separatedBy: "\n").first ?? firstMsg
                eventType = "commit"
                
            case "PullRequestEvent":
                let action = payload["action"] as? String ?? "updated"
                let pr = payload["pull_request"] as? [String: Any]
                let title = pr?["title"] as? String ?? "Pull request"
                message = "\(action.capitalized): \(title)"
                eventType = "pr"
                
            case "IssuesEvent":
                let action = payload["action"] as? String ?? "updated"
                let issue = payload["issue"] as? [String: Any]
                let title = issue?["title"] as? String ?? "Issue"
                message = "\(action.capitalized): \(title)"
                eventType = "issue"
                
            case "CreateEvent":
                let refType = payload["ref_type"] as? String ?? "resource"
                let ref = payload["ref"] as? String ?? ""
                message = "Created \(refType)\(ref.isEmpty ? "" : " '\(ref)'")"
                eventType = "commit"
                
            case "DeleteEvent":
                let refType = payload["ref_type"] as? String ?? "resource"
                message = "Deleted \(refType)"
                eventType = "commit"
                
            case "WatchEvent":
                message = "Starred repository"
                eventType = "star"
                
            case "ForkEvent":
                message = "Forked repository"
                eventType = "commit"
                
            case "IssueCommentEvent":
                let action = payload["action"] as? String ?? "commented"
                let issue = payload["issue"] as? [String: Any]
                let title = issue?["title"] as? String ?? "issue"
                message = "\(action.capitalized) on: \(title)"
                eventType = "issue"
                
            default:
                // Unknown event type — display it nicely
                message = type.replacingOccurrences(of: "Event", with: " event")
                eventType = "commit"
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
}
