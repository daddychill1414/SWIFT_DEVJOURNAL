//
//  ProjectsView.swift
//  DevJournal
//

import SwiftUI
import SwiftData

enum ProjectsSectionTab: String, CaseIterable, Identifiable {
    case repositories = "Repositories"
    case localProjects = "Work Projects"
    
    var id: String { self.rawValue }
}

struct ProjectsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @StateObject private var gitHubAuth = GitHubAuthService.shared
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    
    @State private var selectedSection: ProjectsSectionTab = .repositories
    @State private var searchText = ""
    @State private var selectedRepoFilter = "All"
    @State private var selectedProjectFilter = "All"
    
    // GitHub Repositories State
    @State private var gitHubRepos: [GitHubRepository] = []
    @State private var isLoadingRepos: Bool = false
    @State private var repoErrorMessage: String? = nil
    
    let repoFilterOptions = ["All", "Public", "Private", "Starred"]
    let projectFilterOptions = ["All", "Active", "Archived", "Starred"]
    
    // Filtered GitHub Repositories
    var filteredRepos: [GitHubRepository] {
        gitHubRepos.filter { repo in
            let matchesSearch = searchText.isEmpty ||
                repo.name.localizedCaseInsensitiveContains(searchText) ||
                (repo.description?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (repo.language?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            if !matchesSearch { return false }
            
            switch selectedRepoFilter {
            case "Public": return !repo.isPrivate
            case "Private": return repo.isPrivate
            case "Starred": return repo.stargazersCount > 0
            default: return true
            }
        }
    }
    
    // Filtered Local Projects
    var userProjects: [Project] {
        guard let currentUsername = appState.currentUser?.username, !currentUsername.isEmpty else {
            return projects.filter { $0.ownerUsername == nil }
        }
        return projects.filter { $0.ownerUsername == currentUsername }
    }
    
    var filteredProjects: [Project] {
        userProjects.filter { project in
            let matchesSearch = searchText.isEmpty || project.name.localizedCaseInsensitiveContains(searchText)
            if selectedProjectFilter == "All" { return matchesSearch }
            return matchesSearch && project.status.capitalized == selectedProjectFilter
        }
    }
    
    private func claimUnownedProjectsIfNeeded() {
        guard let currentUsername = appState.currentUser?.username, !currentUsername.isEmpty else { return }
        for project in projects where project.ownerUsername == nil {
            project.ownerUsername = currentUsername
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackgroundView()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Header Title Bar
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Code & Projects")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text(selectedSection == .repositories
                                     ? "Browse and track all your GitHub repositories"
                                     : "Track focused development logs and sprints")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            if selectedSection == .localProjects {
                                Button {
                                    appState.isNewProjectSheetPresented = true
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title)
                                        .foregroundColor(AppColors.primaryIndigo)
                                }
                            } else {
                                Button {
                                    Task { await loadRepositories() }
                                } label: {
                                    Image(systemName: "arrow.clockwise.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(AppColors.accentCyan)
                                }
                                .disabled(isLoadingRepos)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        // Custom Section Segment Switcher
                        HStack(spacing: 8) {
                            sectionTabButton(
                                tab: .repositories,
                                title: "GitHub Repos",
                                count: gitHubRepos.isEmpty ? nil : gitHubRepos.count,
                                icon: "folder.fill.badge.gearshape"
                            )
                            
                            sectionTabButton(
                                tab: .localProjects,
                                title: "Work Projects",
                                count: userProjects.isEmpty ? nil : userProjects.count,
                                icon: "hammer.fill"
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Search Field
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField(selectedSection == .repositories ? "Search repositories, languages..." : "Search projects...", text: $searchText)
                                .foregroundColor(.primary)
                            
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                        .padding(.horizontal, 20)
                        
                        // Category Pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                let options = selectedSection == .repositories ? repoFilterOptions : projectFilterOptions
                                let selectedBinding = selectedSection == .repositories ? selectedRepoFilter : selectedProjectFilter
                                
                                ForEach(options, id: \.self) { option in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            if selectedSection == .repositories {
                                                selectedRepoFilter = option
                                            } else {
                                                selectedProjectFilter = option
                                            }
                                        }
                                    } label: {
                                        Text(option)
                                            .font(.caption)
                                            .fontWeight(selectedBinding == option ? .bold : .medium)
                                            .foregroundColor(selectedBinding == option ? .white : .secondary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                            .background(selectedBinding == option ? AppColors.primaryIndigo : Color.white.opacity(0.08))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Main Content View
                        if selectedSection == .repositories {
                            repositoriesContentView
                        } else {
                            localProjectsContentView
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .task {
                claimUnownedProjectsIfNeeded()
                if gitHubRepos.isEmpty && gitHubAuth.isAuthenticated {
                    await loadRepositories()
                }
            }
            .refreshable {
                claimUnownedProjectsIfNeeded()
                if selectedSection == .repositories {
                    await loadRepositories()
                }
            }
            .onChange(of: gitHubAuth.isAuthenticated) { _, isAuthed in
                if isAuthed {
                    Task {
                        await loadRepositories()
                    }
                } else {
                    gitHubRepos = []
                }
            }
            .onChange(of: appState.currentUser?.username) { _, newUsername in
                if newUsername != nil {
                    claimUnownedProjectsIfNeeded()
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private func sectionTabButton(tab: ProjectsSectionTab, title: String, count: Int?, icon: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedSection = tab
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(selectedSection == tab ? .bold : .medium)
                
                if let count = count {
                    Text("\(count)")
                        .font(.caption2.bold())
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(selectedSection == tab ? Color.white.opacity(0.25) : Color.white.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(selectedSection == tab ? .white : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                selectedSection == tab
                    ? AnyShapeStyle(LinearGradient(colors: [AppColors.primaryIndigo, AppColors.secondaryPurple], startPoint: .leading, endPoint: .trailing))
                    : AnyShapeStyle(Color.white.opacity(0.06))
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(selectedSection == tab ? AppColors.accentCyan.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Repositories Section
    
    @ViewBuilder
    private var repositoriesContentView: some View {
        if isLoadingRepos && gitHubRepos.isEmpty {
            VStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    ActivitySkeletonCard()
                }
            }
            .padding(.horizontal, 20)
        } else if !gitHubAuth.isAuthenticated {
            GlassCard(style: .regular, padding: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.primaryIndigo)
                    
                    Text("Connect GitHub to View Repositories")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Sign in with your GitHub account to view, search, and track all your personal and team repositories.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        appState.isGitHubConnectSheetPresented = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "terminal.fill")
                            Text("Connect GitHub Account")
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 11)
                        .background(AppColors.primaryIndigo)
                        .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
        } else if let error = repoErrorMessage, gitHubRepos.isEmpty {
            GlassCard(style: .regular, padding: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                    Text("Failed to Load Repositories")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Try Again") {
                        Task { await loadRepositories() }
                    }
                    .font(.caption.bold())
                    .foregroundColor(AppColors.accentCyan)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
        } else if filteredRepos.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "folder.badge.questionmark")
                    .font(.system(size: 44))
                    .foregroundColor(.secondary)
                Text("No Matching Repositories")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("Try adjusting your search terms or filter selection.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
        } else {
            LazyVStack(spacing: 14) {
                ForEach(filteredRepos) { repo in
                    repositoryCard(for: repo)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func repositoryCard(for repo: GitHubRepository) -> some View {
        GlassCard(style: .regular, padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                // Header: Name, Privacy Badge, Tracked Badge
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: repo.isPrivate ? "lock.fill" : "folder.fill")
                        .font(.headline)
                        .foregroundColor(repo.isPrivate ? AppColors.accentCyan : AppColors.primaryIndigo)
                        .frame(width: 28, height: 28)
                        .background((repo.isPrivate ? AppColors.accentCyan : AppColors.primaryIndigo).opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(repo.name)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            // Privacy Tag
                            Text(repo.isPrivate ? "Private" : "Public")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(repo.isPrivate ? AppColors.secondaryPurple : .secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.primary.opacity(0.06))
                                .clipShape(Capsule())
                        }
                        
                        Text(repo.fullName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Tracked in Activity Toggle Button
                    Button {
                        toggleTrackedRepo(repo.fullName)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isRepoTracked(repo.fullName) ? "checkmark.circle.fill" : "plus.circle")
                                .font(.caption)
                            Text(isRepoTracked(repo.fullName) ? "Tracking" : "Track")
                                .font(.caption2.bold())
                        }
                        .foregroundColor(isRepoTracked(repo.fullName) ? AppColors.accentCyan : .secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(isRepoTracked(repo.fullName) ? AppColors.accentCyan.opacity(0.15) : Color.white.opacity(0.06))
                        .clipShape(Capsule())
                    }
                }
                
                // Description
                if let description = repo.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Divider()
                    .background(Color.white.opacity(0.08))
                
                // Footer: Language, Stars, Forks, Open Issues & Web Link
                HStack(spacing: 14) {
                    if let language = repo.language {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(languageColor(for: language))
                                .frame(width: 8, height: 8)
                            Text(language)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        Text("\(repo.stargazersCount)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(repo.forksCount)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Open on GitHub Web Link
                    if let url = URL(string: repo.htmlUrl) {
                        Button {
                            openURL(url)
                        } label: {
                            HStack(spacing: 4) {
                                Text("GitHub")
                                    .font(.caption2.bold())
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption2)
                            }
                            .foregroundColor(AppColors.accentCyan)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Local Projects Section
    
    @ViewBuilder
    private var localProjectsContentView: some View {
        if filteredProjects.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 44))
                    .foregroundColor(.secondary)
                Text("No Work Projects Available")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("Tap the '+' button above to create a project or associate one with your GitHub repos.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
        } else {
            VStack(spacing: 16) {
                ForEach(filteredProjects) { project in
                    NavigationLink(destination: ProjectDetailView(project: project)) {
                        GlassCard(style: .regular) {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(project.name)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                        
                                        Text(project.category)
                                            .font(.caption)
                                            .foregroundColor(AppColors.accentCyan)
                                    }
                                    Spacer()
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.caption)
                                        Text("GitHub Connected")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(AppColors.successGreen)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(AppColors.successGreen.opacity(0.12))
                                    .clipShape(Capsule())
                                }
                                
                                Text(project.projectDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                
                                // Progress bar
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Progress")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(Int(project.progress * 100))%")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(Color.white.opacity(0.1))
                                                .frame(height: 8)
                                            
                                            Capsule()
                                                .fill(LinearGradient(colors: [AppColors.primaryIndigo, AppColors.accentCyan], startPoint: .leading, endPoint: .trailing))
                                                .frame(width: geo.size.width * CGFloat(project.progress), height: 8)
                                        }
                                    }
                                    .frame(height: 8)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Helpers
    
    private func loadRepositories() async {
        guard gitHubAuth.isAuthenticated else { return }
        isLoadingRepos = true
        repoErrorMessage = nil
        do {
            let fetched = try await GitHubService.shared.fetchRepositories()
            await MainActor.run {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    self.gitHubRepos = fetched
                    self.isLoadingRepos = false
                }
            }
        } catch {
            await MainActor.run {
                self.repoErrorMessage = error.localizedDescription
                self.isLoadingRepos = false
            }
        }
    }
    
    private func isRepoTracked(_ fullName: String) -> Bool {
        appState.selectedRepoNames.contains(fullName)
    }
    
    private func toggleTrackedRepo(_ fullName: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if appState.selectedRepoNames.contains(fullName) {
                appState.selectedRepoNames.remove(fullName)
            } else {
                appState.selectedRepoNames.insert(fullName)
            }
        }
    }
    
    private func languageColor(for language: String) -> Color {
        switch language.lowercased() {
        case "swift": return .orange
        case "python": return .blue
        case "javascript", "typescript": return .yellow
        case "html": return .red
        case "css": return .purple
        case "php": return Color(red: 0.5, green: 0.4, blue: 0.8)
        case "c++", "c": return .gray
        case "go": return .cyan
        case "rust": return Color(red: 0.9, green: 0.4, blue: 0.2)
        default: return AppColors.accentCyan
        }
    }
}

#Preview {
    ProjectsView()
        .environment(AppState())
}
