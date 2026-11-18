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
    
    private var userRecentEntries: [JournalEntry] {
        guard let currentUsername = appState.currentUser?.username, !currentUsername.isEmpty else {
            return recentEntries.filter { $0.ownerUsername == nil }
        }
        return recentEntries.filter { $0.ownerUsername == currentUsername }
    }
    
    private var userFocusSessions: [FocusSession] {
        guard let currentUsername = appState.currentUser?.username, !currentUsername.isEmpty else {
            return focusSessions.filter { $0.ownerUsername == nil }
        }
        return focusSessions.filter { $0.ownerUsername == currentUsername }
    }
    
    private func claimUnownedDataIfNeeded() {
        guard let currentUsername = appState.currentUser?.username, !currentUsername.isEmpty else { return }
        for entry in recentEntries where entry.ownerUsername == nil {
            entry.ownerUsername = currentUsername
        }
        for session in focusSessions where session.ownerUsername == nil {
            session.ownerUsername = currentUsername
        }
    }
    
    @State private var viewModel = HomeViewModel()
    
    private var isProfileLoading: Bool {
        gitHubAuth.isAuthenticated && appState.currentUser == nil
    }
    
    private var displayedActivities: [GitHubActivityItem] {
        viewModel.filteredActivities(globalSelectedRepos: appState.selectedRepoNames)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackgroundView()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header Section
                        VStack(alignment: .leading, spacing: 6) {
                            Text(viewModel.currentGreeting)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                HStack(spacing: 8) {
                                    Text(appState.currentUser?.name ?? (gitHubAuth.isAuthenticated ? "Developer" : "Developer"))
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                        .redacted(reason: isProfileLoading ? .placeholder : [])
                                        .shimmer(active: isProfileLoading)
                                    
                                    if !isProfileLoading {
                                        Text("👋")
                                            .font(.system(size: 28))
                                    }
                                }
                                
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
                                            .redacted(reason: isProfileLoading ? .placeholder : [])
                                            .shimmer(active: isProfileLoading)
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
                            
                            // Horizontal Repository Filter Chips
                            if !viewModel.availableRepos.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        // "All" Chip
                                        Button {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                                viewModel.selectedRepoFilter = nil
                                            }
                                        } label: {
                                            HStack(spacing: 5) {
                                                Image(systemName: "tray.full.fill")
                                                    .font(.caption2)
                                                Text("All")
                                                    .font(.subheadline)
                                                    .fontWeight(viewModel.selectedRepoFilter == nil ? .bold : .medium)
                                            }
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                            .background(
                                                viewModel.selectedRepoFilter == nil
                                                    ? AnyShapeStyle(AppColors.primaryIndigo)
                                                    : AnyShapeStyle(.ultraThinMaterial)
                                            )
                                            .foregroundColor(viewModel.selectedRepoFilter == nil ? .white : .secondary)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule()
                                                    .stroke(
                                                        viewModel.selectedRepoFilter == nil
                                                            ? Color.white.opacity(0.3)
                                                            : Color.white.opacity(0.1),
                                                        lineWidth: 1
                                                    )
                                            )
                                            .shadow(
                                                color: viewModel.selectedRepoFilter == nil ? AppColors.primaryIndigo.opacity(0.3) : .clear,
                                                radius: 4, x: 0, y: 2
                                            )
                                        }
                                        
                                        // Specific Repo Chips
                                        ForEach(viewModel.availableRepos, id: \.self) { repo in
                                            let isSelected = viewModel.selectedRepoFilter == repo
                                            let displayName = repo.components(separatedBy: "/").last ?? repo
                                            
                                            Button {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                                    viewModel.toggleRepoFilter(repo)
                                                }
                                            } label: {
                                                HStack(spacing: 5) {
                                                    Image(systemName: "folder.fill")
                                                        .font(.caption2)
                                                        .foregroundColor(isSelected ? .white : AppColors.accentCyan)
                                                    
                                                    Text(displayName)
                                                        .font(.subheadline)
                                                        .fontWeight(isSelected ? .bold : .medium)
                                                }
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 7)
                                                .background(
                                                    isSelected
                                                        ? AnyShapeStyle(AppColors.primaryIndigo)
                                                        : AnyShapeStyle(.ultraThinMaterial)
                                                )
                                                .foregroundColor(isSelected ? .white : .primary)
                                                .clipShape(Capsule())
                                                .overlay(
                                                    Capsule()
                                                        .stroke(
                                                            isSelected
                                                                ? Color.white.opacity(0.3)
                                                                : Color.white.opacity(0.1),
                                                            lineWidth: 1
                                                        )
                                                )
                                                .shadow(
                                                    color: isSelected ? AppColors.primaryIndigo.opacity(0.3) : .clear,
                                                    radius: 4, x: 0, y: 2
                                                )
                                            }
                                        }
                                        
                                        // "All Repos" Navigation Chip
                                        Button {
                                            appState.selectedTab = .projects
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: "folder.badge.gearshape")
                                                    .font(.caption2)
                                                Text("All Repos")
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 9, weight: .bold))
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(Color.white.opacity(0.08))
                                            .foregroundColor(AppColors.accentCyan)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(AppColors.accentCyan.opacity(0.35), lineWidth: 1))
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            
                            // Activity List / Skeleton / Empty State
                            if viewModel.isLoading {
                                VStack(spacing: 12) {
                                    ForEach(0..<3, id: \.self) { _ in
                                        ActivitySkeletonCard()
                                    }
                                }
                                .transition(.opacity)
                            } else if displayedActivities.isEmpty {
                                GlassCard(style: .ultraThin, padding: 18) {
                                    VStack(spacing: 14) {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .font(.title2)
                                            .foregroundColor(.secondary)
                                        
                                        let emptyMsg: String = {
                                            if let authErr = gitHubAuth.authError { return authErr }
                                            if let err = viewModel.errorMessage { return err }
                                            if !gitHubAuth.isAuthenticated { return "Not authenticated with GitHub. Please connect your account in Settings." }
                                            if let filter = viewModel.selectedRepoFilter {
                                                let display = filter.components(separatedBy: "/").last ?? filter
                                                return "No recent activity found for '\(display)'."
                                            }
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
                claimUnownedDataIfNeeded()
                await viewModel.fetchRecentActivities(username: appState.currentUser?.username)
                viewModel.computeTodayProgress(entries: userRecentEntries, sessions: userFocusSessions)
            }
            .refreshable {
                if let profile = try? await GitHubService.shared.fetchUserProfile() {
                    withAnimation(.spring()) {
                        appState.currentUser = profile
                        appState.isGitHubConnected = true
                    }
                }
                claimUnownedDataIfNeeded()
                await viewModel.fetchRecentActivities(username: appState.currentUser?.username)
                viewModel.computeTodayProgress(entries: userRecentEntries, sessions: userFocusSessions)
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
                                claimUnownedDataIfNeeded()
                            }
                        }
                        await viewModel.fetchRecentActivities(username: appState.currentUser?.username)
                    }
                } else {
                    viewModel.gitHubActivities = []
                    viewModel.selectedRepoFilter = nil
                    viewModel.computeTodayProgress(entries: userRecentEntries, sessions: userFocusSessions)
                }
            }
            .onChange(of: appState.currentUser?.username) { _, newUsername in
                claimUnownedDataIfNeeded()
                viewModel.computeTodayProgress(entries: userRecentEntries, sessions: userFocusSessions)
                if let username = newUsername {
                    Task {
                        await viewModel.fetchRecentActivities(username: username)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views & Modifiers

struct ActivitySkeletonCard: View {
    var body: some View {
        GlassCard(style: .ultraThin, padding: 14) {
            HStack(spacing: 14) {
                Circle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.12))
                        .frame(height: 14)
                        .frame(maxWidth: 220)
                    
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.primary.opacity(0.08))
                            .frame(width: 80, height: 10)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.primary.opacity(0.06))
                            .frame(width: 50, height: 10)
                    }
                }
                Spacer()
            }
        }
        .shimmer(active: true)
    }
}

struct ShimmerModifier: ViewModifier {
    var active: Bool
    @State private var phase: CGFloat = -1.0
    
    func body(content: Content) -> some View {
        if active {
            content
                .overlay(
                    GeometryReader { geo in
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: Color.white.opacity(0.2), location: 0.5),
                                .init(color: .clear, location: 1.0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .rotationEffect(.degrees(20))
                        .offset(x: phase * (geo.size.width * 2))
                    }
                    .mask(content)
                )
                .onAppear {
                    withAnimation(
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                    ) {
                        phase = 1.0
                    }
                }
        } else {
            content
        }
    }
}

extension View {
    func shimmer(active: Bool = true) -> some View {
        modifier(ShimmerModifier(active: active))
    }
}

#Preview {
    HomeView()
        .environment(AppState())
}
