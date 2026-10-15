//
//  SyncEngine.swift
//  DevJournal
//
//  Offline-first sync queue: saves locally first, pushes to Supabase
//  when network is available. Uses NWPathMonitor to auto-trigger sync
//  whenever connectivity is restored.
//

import Foundation
import SwiftData
import Network

@Observable
final class SyncEngine {
    static let shared = SyncEngine()

    var isSyncing: Bool = false
    var lastSyncDate: Date?
    var pendingCount: Int = 0
    private(set) var isConnected: Bool = false

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "SyncEngine.NetworkMonitor", qos: .background)

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = (path.status == .satisfied)
            Task { @MainActor in
                self?.isConnected = connected
            }
            if connected {
                // Network restored — try to drain the queue
                Task { await self?.syncAll() }
            }
        }
        monitor.start(queue: monitorQueue)
    }

    /// Call after any local model insert/update (from NewJournalView, NewProjectView, etc.)
    @MainActor
    func syncAll(using modelContext: ModelContext? = nil) async {
        guard isConnected, !isSyncing else { return }
        guard AppState.current?.isSupabaseSyncEnabled == true else { return }

        isSyncing = true
        defer {
            isSyncing = false
            lastSyncDate = Date()
        }

        guard let context = modelContext ?? AppState.current?.modelContext else { return }

        // ── Sync unsynced journal entries ──────────────────────────────────
        do {
            let unsyncedPredicate = #Predicate<JournalEntry> { $0.isSyncedWithSupabase == false }
            let descriptor = FetchDescriptor<JournalEntry>(predicate: unsyncedPredicate)
            let unsynced = try context.fetch(descriptor)
            pendingCount = unsynced.count

            for entry in unsynced {
                do {
                    try await SupabaseService.shared.syncJournalEntry(entry)
                    // isSyncedWithSupabase is set inside syncJournalEntry
                } catch {
                    print("SyncEngine: Failed journal entry \(entry.id): \(error.localizedDescription)")
                }
            }
        } catch {
            print("SyncEngine: Fetch unsynced entries error: \(error)")
        }

        // ── Sync unsynced projects ─────────────────────────────────────────
        do {
            let unsyncedPredicate = #Predicate<Project> { $0.isSyncedWithSupabase == false }
            let descriptor = FetchDescriptor<Project>(predicate: unsyncedPredicate)
            let unsynced = try context.fetch(descriptor)
            pendingCount += unsynced.count

            for project in unsynced {
                do {
                    try await SupabaseService.shared.syncProject(project)
                    project.isSyncedWithSupabase = true
                } catch {
                    print("SyncEngine: Failed project \(project.id): \(error.localizedDescription)")
                }
            }
        } catch {
            print("SyncEngine: Fetch unsynced projects error: \(error)")
        }

        try? context.save()
        pendingCount = 0
    }
}

// MARK: - AppState convenience accessor for SyncEngine
// AppState.current and AppState.modelContext are injected at app startup
extension AppState {
    /// Set by the App root on launch so SyncEngine can grab a model context
    static weak var current: AppState?
    var modelContext: ModelContext? {
        get { _modelContext }
        set { _modelContext = newValue }
    }
    @ObservationIgnored private(set) var _modelContext: ModelContext? = nil
}
