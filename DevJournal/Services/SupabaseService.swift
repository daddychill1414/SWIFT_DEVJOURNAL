//
//  SupabaseService.swift
//  DevJournal
//

import Foundation

enum SupabaseError: Error, LocalizedError {
    case configMissing
    case networkError
    case syncFailed
    case invalidResponse(Int)
    
    var errorDescription: String? {
        switch self {
        case .configMissing: return "Supabase URL or Anon Key missing. Configure in Xcode Environment."
        case .networkError: return "Network connectivity issue with Supabase cloud."
        case .syncFailed: return "Failed to synchronize local SwiftData with Supabase cloud."
        case .invalidResponse(let code): return "Supabase returned status code \(code)."
        }
    }
}

final class SupabaseService {
    static let shared = SupabaseService()
    private init() {}
    
    private var supabaseURL: String {
        AppConfiguration.supabaseURL
    }
    
    private var supabaseAnonKey: String {
        AppConfiguration.supabaseAnonKey
    }
    
    private func makeRequest(endpoint: String, method: String, body: Data? = nil) async throws -> Data {
        guard !supabaseURL.isEmpty, !supabaseAnonKey.isEmpty else {
            throw SupabaseError.configMissing
        }
        
        guard let url = URL(string: "\(supabaseURL)/rest/v1/\(endpoint)") else {
            throw SupabaseError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
            throw SupabaseError.invalidResponse(statusCode)
        }
        
        return data
    }
    
    func syncJournalEntry(_ entry: JournalEntry) async throws {
        let payload: [String: Any] = [
            "id": entry.id.uuidString,
            "title": entry.title,
            "content": entry.content,
            "date": ISO8601DateFormatter().string(from: entry.date),
            "mood": entry.mood,
            "focus_level": entry.focusLevel,
            "hours_spent": entry.hoursSpent,
            "tags": entry.tags,
            "github_repo_name": entry.gitHubRepoName ?? ""
        ]
        let body = try JSONSerialization.data(withJSONObject: payload)
        _ = try await makeRequest(endpoint: "journal_entries", method: "POST", body: body)
        entry.isSyncedWithSupabase = true
    }
    
    func syncProject(_ project: Project) async throws {
        let payload: [String: Any] = [
            "id": project.id.uuidString,
            "name": project.name,
            "description": project.projectDescription,
            "category": project.category,
            "progress": project.progress,
            "status": project.status,
            "github_repo_name": project.gitHubRepoName ?? ""
        ]
        let body = try JSONSerialization.data(withJSONObject: payload)
        _ = try await makeRequest(endpoint: "projects", method: "POST", body: body)
    }
    
    func fetchCloudJournalEntries() async throws -> [JournalEntry] {
        let data = try await makeRequest(endpoint: "journal_entries?order=date.desc&limit=50", method: "GET")
        
        guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        
        let formatter = ISO8601DateFormatter()
        return jsonArray.compactMap { dict in
            guard let title = dict["title"] as? String,
                  let content = dict["content"] as? String,
                  let dateString = dict["date"] as? String,
                  let date = formatter.date(from: dateString) else {
                return nil
            }
            
            return JournalEntry(
                title: title,
                content: content,
                date: date,
                mood: dict["mood"] as? String ?? "😊",
                focusLevel: dict["focus_level"] as? String ?? "Medium",
                hoursSpent: dict["hours_spent"] as? Double ?? 0,
                tags: dict["tags"] as? [String] ?? [],
                gitHubRepoName: dict["github_repo_name"] as? String
            )
        }
    }
}

