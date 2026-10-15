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
    func fetchRepositories() async throws -> [GitHubRepository]
    func fetchRecentCommits(repoOwner: String, repoName: String, page: Int, perPage: Int) async throws -> [GitHubCommit]
    func fetchUserActivity(page: Int) async throws -> [GitHubActivityItem]
}

// Convenience default arguments for protocol callers
extension GitHubServiceProtocol {
    func fetchRecentCommits(repoOwner: String, repoName: String, page: Int = 1, perPage: Int = 30) async throws -> [GitHubCommit] {
        try await fetchRecentCommits(repoOwner: repoOwner, repoName: repoName, page: page, perPage: perPage)
    }
    func fetchUserActivity(page: Int = 1) async throws -> [GitHubActivityItem] {
        try await fetchUserActivity(page: page)
    }
}

final class GitHubService: GitHubServiceProtocol {
    static let shared = GitHubService()
    private init() {}
    
    private let baseURL = "https://api.github.com"
    
    private var accessToken: String? {
        KeychainService.shared.loadString(key: "github_access_token")
    }
    
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw GitHubError.requestFailed((response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode([T].self, from: data)
        } catch {
            throw GitHubError.decodingError
        }
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
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw GitHubError.requestFailed((response as? HTTPURLResponse)?.statusCode ?? 500)
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
                  let createdAt = event["created_at"] as? String,
                  let actor = event["actor"] as? [String: Any],
                  let login = actor["login"] as? String
            else { return nil }
            
            let payload = event["payload"] as? [String: Any] ?? [:]
            
            let message: String
            let eventType: String
            
            switch type {
            case "PushEvent":
                let commits = payload["commits"] as? [[String: Any]]
                let firstMsg = commits?.first?["message"] as? String ?? "Pushed commits"
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
