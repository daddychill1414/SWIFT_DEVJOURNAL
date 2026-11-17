//
//  HomeView.swift
//  DevJournal
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @StateObject private var gitHubAuth = GitHubAuthService.shared
    @Query(sort: \JournalEntry.date, order: .reverse) private var recentEntries: [JournalEntry]
    @Query(sort: \FocusSession.startTime, order: .reverse) private var focusSessions: [FocusSession]
    
    @State private var viewModel = HomeViewModel()
    
    private var displayedActivities: [GitHubActivityItem] {
        let base = appState.selectedRepoNames.isEmpty
            ? viewModel.gitHubActivities
            : viewModel.gitHubActivities.filter { appState.selectedRepoNames.contains($0.repoName) }
        if viewModel.searchText.isEmpty {
            return base
        } else {
            return base.filter {
                $0.message.localizedCaseInsensitiveContains(viewModel.searchText) ||
                $0.repoName.localizedCaseInsensitiveContains(viewModel.searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackgroundView()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header Section
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Good evening,")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text("\(appState.currentUser?.name ?? (gitHubAuth.isAuthenticated ? "Loading..." : "Developer")) 👋")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                Spacer()
                                
                                Button {
                                    appState.selectedTab = .settings
                                } label: {
                                    if let avatarUrl = appState.currentUser?.avatarUrl,
                                       let url = URL(string: avatarUrl) {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 34, height: 34)
                                                    .clipShape(Circle())
                                            default:
                                                Image(systemName: "person.crop.circle.fill")
                                                    .font(.system(size: 32))
                                                    .foregroundStyle(AppColors.primaryIndigo, AppColors.secondaryPurple)
                                            }
                                        }
                                    } else {
                                        Image(systemName: "person.crop.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundStyle(AppColors.primaryIndigo, AppColors.secondaryPurple)
                                    }
                                }
                            }
                            
                            Text("Let's continue building something great today.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        // Glass Search Field
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search journals, projects...", text: $viewModel.searchText)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                        .padding(.horizontal, 20)
                        
                        // Today's Progress Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Today's Progress")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            GlassCard(style: .thin) {
                                HStack(spacing: 20) {
                                    ProgressRing(progress: viewModel.progressPercent)
                                        .frame(width: 100, height: 100)
                                    
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "clock.fill")
                                                .foregroundColor(AppColors.accentCyan)
                                            Text(viewModel.focusHoursText)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                        }
                                        
                                        HStack(spacing: 8) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(AppColors.successGreen)
                                            Text("\(viewModel.completedTasksCount) tasks completed")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                        }
                                        
                                        Button {
                                            appState.isNewJournalSheetPresented = true
                                        } label: {
                                            HStack(spacing: 4) {
                                                Text("Log Session")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                Image(systemName: "arrow.right")
                                                    .font(.caption2)
                                            }
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(AppColors.primaryIndigo)
                                            .clipShape(Capsule())
                                        }
                                        .padding(.top, 4)
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Recent GitHub Activity Section
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("Recent Activity")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Button("View All") {
                                    appState.selectedTab = .journal
                                }
                                .font(.subheadline)
                                .foregroundColor(AppColors.accentCyan)
                            }
                            
                            if viewModel.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity, minHeight: 100)
                            } else if displayedActivities.isEmpty {
                                GlassCard(style: .ultraThin, padding: 18) {
                                    VStack(spacing: 14) {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .font(.title2)
                                            .foregroundColor(.secondary)
                                        
                                        let emptyMsg: String = {
                                            if let err = viewModel.errorMessage { return err }
                                            if !gitHubAuth.isAuthenticated { return "Not authenticated with GitHub. Please connect your account in Settings." }
                                            if appState.isGitHubConnected { return "No recent GitHub activity found." }
                                            return "Connect GitHub to view your commit and PR activity."
                                        }()
                                        
                                        Text(emptyMsg)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 8)
                                        
                                        if !gitHubAuth.isAuthenticated {
                                            Button {
                                                appState.isGitHubConnectSheetPresented = true
                                            } label: {
                                                HStack(spacing: 8) {
                                                    Image(systemName: "terminal.fill")
                                                    Text("Connect GitHub Account")
                                                }
                                                .font(.headline)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 22)
                                                .padding(.vertical, 12)
                                                .background(AppColors.primaryIndigo)
                                                .clipShape(Capsule())
                                                .shadow(color: AppColors.primaryIndigo.opacity(0.4), radius: 8, x: 0, y: 4)
                                            }
                                            .padding(.top, 4)
                                        } else {
                                            Button {
                                                Task {
                                                    await viewModel.fetchRecentActivities(username: appState.currentUser?.username)
                                                }
                                            } label: {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "arrow.clockwise")
                                                    Text("Refresh Activity")
                                                }
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .foregroundColor(AppColors.accentCyan)
                                            }
                                            .padding(.top, 4)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                }
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(displayedActivities) { activity in
                                        GlassCard(style: .ultraThin, padding: 14) {
                                            HStack(spacing: 14) {
                                                ZStack {
                                                    Circle()
                                                        .fill(activity.type == "commit" ? AppColors.primaryIndigo.opacity(0.2) : AppColors.secondaryPurple.opacity(0.2))
                                                        .frame(width: 40, height: 40)
                                                    
                                                    Image(systemName: activity.type == "commit" ? "hammer.fill" : "arrow.triangle.pull")
                                                        .foregroundColor(activity.type == "commit" ? AppColors.accentCyan : AppColors.secondaryPurple)
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(activity.message)
                                                        .font(.subheadline)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(.primary)
                                                        .lineLimit(1)
                                                    
                                                    HStack(spacing: 6) {
                                                        Text(activity.repoName)
                                                            .font(.caption)
                                                            .fontWeight(.bold)
                                                            .foregroundColor(AppColors.primaryIndigo)
                                                        
                                                        Text("•")
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                        
                                                        Text(activity.timestamp.formatted(.relative(presentation: .named)))
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .task {
                // Fetch profile on appear if authenticated but profile not loaded yet
                if gitHubAuth.isAuthenticated && appState.currentUser == nil {
                    if let profile = try? await GitHubService.shared.fetchUserProfile() {
                        withAnimation(.spring()) {
                            appState.currentUser = profile
                            appState.isGitHubConnected = true
                        }
                    }
                }
                await viewModel.fetchRecentActivities(username: appState.currentUser?.username)
                viewModel.computeTodayProgress(entries: recentEntries, sessions: focusSessions)
            }
            .refreshable {
                if let profile = try? await GitHubService.shared.fetchUserProfile() {
                    withAnimation(.spring()) {
                        appState.currentUser = profile
                        appState.isGitHubConnected = true
                    }
                }
                await viewModel.fetchRecentActivities(username: appState.currentUser?.username)
                viewModel.computeTodayProgress(entries: recentEntries, sessions: focusSessions)
            }
            .sheet(isPresented: Bindable(appState).isGitHubConnectSheetPresented) {
                GitHubConnectSheet()
            }
            .onChange(of: gitHubAuth.isAuthenticated) { _, isAuthed in
                if isAuthed {
                    Task {
                        if let profile = try? await GitHubService.shared.fetchUserProfile() {
                            await MainActor.run {
                                withAnimation(.spring()) {
                                    appState.currentUser = profile
                                    appState.isGitHubConnected = true
                                }
                            }
                        }
                        await viewModel.fetchRecentActivities(username: appState.currentUser?.username)
                    }
                }
            }
            .onChange(of: appState.currentUser?.username) { _, newUsername in
                if let username = newUsername {
                    Task {
                        await viewModel.fetchRecentActivities(username: username)
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(AppState())
}
