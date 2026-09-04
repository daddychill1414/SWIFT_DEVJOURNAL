//
//  ContentView.swift
//  DevJournal
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Tab Screens Switcher
            Group {
                switch appState.selectedTab {
                case .home:
                    HomeView()
                case .projects:
                    ProjectsView()
                case .journal:
                    JournalView()
                case .insights:
                    InsightsView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Elevated Floating Glass TabBar
            GlassTabBar(
                selectedTab: Bindable(appState).selectedTab,
                onPlusTap: {
                    appState.isNewJournalSheetPresented = true
                }
            )
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: Bindable(appState).isNewJournalSheetPresented) {
            NewJournalView()
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
