//
//  AppState.swift
//  DevJournal
//

import SwiftUI

enum AppTab: Hashable {

    case home
    case projects
    case journal
    case insights
    case settings
}

enum AppThemeMode: String, CaseIterable, Identifiable {
    case system = "System"
    case dark = "Dark"
    case light = "Light"
    
    var id: String { self.rawValue }
}

@Observable
final class AppState {
    var selectedTab: AppTab = .home
    var isNewJournalSheetPresented: Bool = false
    var isNewProjectSheetPresented: Bool = false
    var isGitHubConnectSheetPresented: Bool = false
    
    // User Settings
    var themeMode: AppThemeMode = .dark
    var isNotificationsEnabled: Bool = true
    var isFocusRemindersEnabled: Bool = true
    var isSupabaseSyncEnabled: Bool = true
    
    // Auth & GitHub Status
    var isAuthenticated: Bool = false
    var isGitHubConnected: Bool = false
    var currentUser: UserProfile? = UserProfile.sample
    
    var preferredColorScheme: ColorScheme? {
        switch themeMode {
        case .system: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }
}
