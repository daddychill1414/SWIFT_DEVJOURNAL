//
//  SettingsView.swift
//  DevJournal
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @StateObject private var gitHubAuth = GitHubAuthService.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackgroundView()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title
                        Text("Settings")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        
                        // PROFILE SECTION
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PROFILE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 24)
                            
                            GlassCard(style: .regular) {
                                HStack(spacing: 16) {
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.system(size: 50))
                                        .foregroundStyle(AppColors.primaryIndigo, AppColors.secondaryPurple)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(appState.currentUser?.name ?? "Raniel Go")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("@\(appState.currentUser?.username ?? "ranielgo")")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text(appState.currentUser?.bio ?? "iOS & Full Stack Developer")
                                            .font(.caption)
                                            .foregroundColor(AppColors.accentCyan)
                                    }
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // PREFERENCES SECTION
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PREFERENCES")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 24)
                            
                            GlassCard(style: .thin) {
                                VStack(spacing: 14) {
                                    // Appearance Picker
                                    HStack {
                                        Label("Appearance", systemImage: "paintbrush.fill")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Picker("Theme", selection: Bindable(appState).themeMode) {
                                            ForEach(AppThemeMode.allCases) { mode in
                                                Text(mode.rawValue).tag(mode)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                    }
                                    
                                    Divider()
                                    
                                    // Notifications Toggle
                                    Toggle(isOn: Bindable(appState).isNotificationsEnabled) {
                                        Label("Notifications", systemImage: "bell.fill")
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Divider()
                                    
                                    // Focus Reminders Toggle
                                    Toggle(isOn: Bindable(appState).isFocusRemindersEnabled) {
                                        Label("Focus Reminders", systemImage: "timer")
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // INTEGRATION & DATA
                        VStack(alignment: .leading, spacing: 8) {
                            Text("INTEGRATION & DATA")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 24)
                            
                            GlassCard(style: .thin) {
                                VStack(spacing: 14) {
                                    // GitHub OAuth Status
                                    HStack {
                                        Label("GitHub Integration", systemImage: "network")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        if gitHubAuth.isAuthenticated {
                                            Button("Connected") {
                                                gitHubAuth.signOut()
                                            }
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(AppColors.successGreen)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(AppColors.successGreen.opacity(0.15))
                                            .clipShape(Capsule())
                                        } else {
                                            Button("Connect Account") {
                                                appState.isGitHubConnectSheetPresented = true
                                            }
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(AppColors.accentCyan)
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    // Supabase Sync Toggle
                                    Toggle(isOn: Bindable(appState).isSupabaseSyncEnabled) {
                                        Label("Supabase Cloud Sync", systemImage: "icloud.and.arrow.up.fill")
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // ABOUT
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ABOUT")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 24)
                            
                            GlassCard(style: .ultraThin) {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("DevJournal for iOS")
                                            .fontWeight(.semibold)
                                        Spacer()
                                        Text("v1.0.0 (Build 1)")
                                            .foregroundColor(.secondary)
                                    }
                                    .font(.subheadline)
                                    
                                    Text("Designed with Swift, SwiftUI, SwiftData, and visionOS Glassmorphism.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .sheet(isPresented: Bindable(appState).isGitHubConnectSheetPresented) {
                GitHubConnectSheet()
            }
        }
    }
}

struct GitHubConnectSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AtmosphericBackgroundView()
            
            VStack(spacing: 24) {
                Image(systemName: "cat.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(AppColors.primaryIndigo)
                
                VStack(spacing: 8) {
                    Text("Connect GitHub Account")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Synchronize your repositories, commits, pull requests, and issues directly into DevJournal.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                GlassButton(action: {
                    KeychainService.shared.save(key: "github_access_token", string: "mock_github_oauth_token")
                    GitHubAuthService.shared.isAuthenticated = true
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                        Text("Authorize with GitHub OAuth")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 40)
                
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.secondary)
            }
            .padding(30)
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
}
