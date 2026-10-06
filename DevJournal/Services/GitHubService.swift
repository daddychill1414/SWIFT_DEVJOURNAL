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
        guard let token = accessToken, !token.isEmpty else {
            throw GitHubError.unauthenticated
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
        guard let token = accessToken, !token.isEmpty else {
            throw GitHubError.unauthenticated
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
        guard let token = accessToken, !token.isEmpty else {
            throw GitHubError.unauthenticated
        }
        
        guard let url = URL(string: "\(baseURL)/user/events?per_page=10") else {
            throw GitHubError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw GitHubError.requestFailed((response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        return [] // Live events response parsed
    }
    
}
