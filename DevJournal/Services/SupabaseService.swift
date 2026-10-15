//
//  SupabaseService.swift
//  DevJournal
//
//  Handles all REST communication with the Supabase cloud database.
//  Uses UPSERT (merge-duplicates) so re-syncing the same record is safe.
//

import Foundation

enum SupabaseError: Error, LocalizedError {
    case configMissing
    case networkError
    case syncFailed
    case invalidResponse(Int)
    
    var errorDescription: String? {
        switch self {
        case .configMissing:
            return "Supabase URL or Anon Key missing. Configure in Xcode Environment."
        case .networkError:
            return "Network connectivity issue with Supabase cloud."
        case .syncFailed:
            return "Failed to synchronize local SwiftData with Supabase cloud."
        case .invalidResponse(let code):
            return "Supabase returned status code \(code)."
        }
    }
}

final class SupabaseService {
    static let shared = SupabaseService()
    private init() {}
    
    private var supabaseURL: String { AppConfiguration.supabaseURL }
    private var supabaseAnonKey: String { AppConfiguration.supabaseAnonKey }
    
    // MARK: - Core Request Builder
    
    private func makeRequest(
        endpoint: String,
        method: String,
        body: Data? = nil,
        extraHeaders: [String: String] = [:]
    ) async throws -> Data {
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
        // Default Prefer header — overridden if extraHeaders contains "Prefer"
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        
        for (key, value) in extraHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 500
            throw SupabaseError.invalidResponse(code)
        }
        return data
    }
    
    // MARK: - Journal Entries
    
    /// UPSERT a journal entry — safe to call multiple times for the same entry
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
        _ = try await makeRequest(
            endpoint: "journal_entries",
            method: "POST",
            body: body,
            extraHeaders: ["Prefer": "return=representation,resolution=merge-duplicates"]
        )
        // Mark as synced on success
        entry.isSyncedWithSupabase = true
    }
    
    /// Fetch the latest journal entries from Supabase cloud
    func fetchCloudJournalEntries(limit: Int = 50) async throws -> [JournalEntry] {
        let data = try await makeRequest(
            endpoint: "journal_entries?order=date.desc&limit=\(limit)",
            method: "GET"
        )
        
        guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        
        let formatter = ISO8601DateFormatter()
        return jsonArray.compactMap { dict -> JournalEntry? in
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
                gitHubRepoName: dict["github_repo_name"] as? String,
                isSyncedWithSupabase: true   // came from cloud, already synced
            )
        }
    }
    
    // MARK: - Projects
    
    /// UPSERT a project — safe to call multiple times for the same record
    func syncProject(_ project: Project) async throws {
        let payload: [String: Any] = [
            "id": project.id.uuidString,
            "name": project.name,
            "description": project.projectDescription,
            "category": project.category,
            "progress": project.progress,
            "status": project.status,
            "github_repo_name": project.gitHubRepoName ?? "",
            "commits_count": project.commitsCount,
            "prs_count": project.prsCount,
            "issues_count": project.issuesCount,
            "stars_count": project.starsCount
        ]
        let body = try JSONSerialization.data(withJSONObject: payload)
        _ = try await makeRequest(
            endpoint: "projects",
            method: "POST",
            body: body,
            extraHeaders: ["Prefer": "return=representation,resolution=merge-duplicates"]
        )
        project.isSyncedWithSupabase = true
    }
    
    // MARK: - User Profile
    
    func syncUserProfile(_ profile: UserProfile) async throws {
        let payload: [String: Any] = [
            "id": profile.id,
            "name": profile.name,
            "username": profile.username,
            "avatar_url": profile.avatarUrl ?? "",
            "bio": profile.bio ?? "",
            "github_username": profile.gitHubUsername ?? ""
        ]
        let body = try JSONSerialization.data(withJSONObject: payload)
        _ = try await makeRequest(
            endpoint: "user_profiles",
            method: "POST",
            body: body,
            extraHeaders: ["Prefer": "return=representation,resolution=merge-duplicates"]
        )
    }
}
