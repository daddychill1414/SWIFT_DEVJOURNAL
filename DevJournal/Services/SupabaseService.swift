//
//  SupabaseService.swift
//  DevJournal
//

import Foundation

enum SupabaseError: Error, LocalizedError {
    case configMissing
    case networkError
    case syncFailed
    
    var errorDescription: String? {
        switch self {
        case .configMissing: return "Supabase URL or Anon Key missing. Configure in Xcode Environment."
        case .networkError: return "Network connectivity issue with Supabase cloud."
        case .syncFailed: return "Failed to synchronize local SwiftData with Supabase cloud."
        }
    }
}

final class SupabaseService {
    static let shared = SupabaseService()
    private init() {}
    
    private var supabaseURL: String {
        ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "https://your-project.supabase.co"
    }
    
    private var supabaseAnonKey: String {
        ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? "YOUR_SUPABASE_ANON_KEY"
    }
    
    func syncJournalEntry(_ entry: JournalEntry) async throws {
        // Simulates async REST API push to Supabase Postgres database
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5s network simulation
        entry.isSyncedWithSupabase = true
    }
    
    func syncProject(_ project: Project) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    func fetchCloudJournalEntries() async throws -> [JournalEntry] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return []
    }
}
