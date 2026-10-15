//
//  BackgroundTaskService.swift
//  DevJournal
//
//  Registers and handles BGAppRefreshTask for periodic GitHub
//  activity fetching without blocking the UI.
//
//  SETUP REQUIRED:
//  Add this to DevJournal/Info.plist:
//  <key>BGTaskSchedulerPermittedIdentifiers</key>
//  <array>
//      <string>com.devjournal.app.githubRefresh</string>
//  </array>
//
//  In Xcode: Signing & Capabilities → + Background Modes → Background fetch
//

import BackgroundTasks
import SwiftData

final class BackgroundTaskService {
    static let shared = BackgroundTaskService()
    static let refreshTaskIdentifier = "com.devjournal.app.githubRefresh"

    private init() {}

    /// Call once in your @main App struct's init()
    func registerTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.refreshTaskIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            self.handleGitHubRefresh(task: refreshTask)
        }
    }

    /// Schedule the next background fetch — call on app foreground or after each refresh
    func scheduleGitHubRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskIdentifier)
        // iOS enforces a minimum of ~15 min in practice even if you request less
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("BackgroundTask: Schedule failed — \(error.localizedDescription)")
        }
    }

    private func handleGitHubRefresh(task: BGAppRefreshTask) {
        // Immediately schedule the next refresh
        scheduleGitHubRefresh()

        let fetchTask = Task {
            do {
                let activities = try await GitHubService.shared.fetchUserActivity()
                print("BackgroundTask: Fetched \(activities.count) GitHub activities")
                // Optionally persist via SyncEngine or SwiftData here
                await SyncEngine.shared.syncAll()
                task.setTaskCompleted(success: true)
            } catch {
                print("BackgroundTask: Error — \(error.localizedDescription)")
                task.setTaskCompleted(success: false)
            }
        }

        task.expirationHandler = {
            fetchTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }
}
