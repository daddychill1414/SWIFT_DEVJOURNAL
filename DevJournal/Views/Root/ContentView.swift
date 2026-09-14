//
//  ContentView.swift
//  DevJournal
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        Group {
            if appState.isAuthenticated {
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
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                .ignoresSafeArea(.keyboard)
                .sheet(isPresented: Bindable(appState).isNewJournalSheetPresented) {
                    NewJournalView()
                }
                .sheet(isPresented: Bindable(appState).isNewProjectSheetPresented) {
                    NewProjectView()
                }
            } else {
                LandingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: appState.isAuthenticated)
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
