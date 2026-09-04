//
//  DevJournalApp.swift
//  DevJournal
//

import SwiftUI
import SwiftData

@main
struct DevJournalApp: App {
    @State private var appState = AppState()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            JournalEntry.self,
            Project.self,
            FocusSession.self,
            GitHubActivityItem.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(appState.preferredColorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
