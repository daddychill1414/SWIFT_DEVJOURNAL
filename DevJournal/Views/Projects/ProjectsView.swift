//
//  ProjectsView.swift
//  DevJournal
//

import SwiftUI
import SwiftData

struct ProjectsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    let filterOptions = ["All", "Active", "Archived", "Starred"]
    
    var filteredProjects: [Project] {
        projects.filter { project in
            let matchesSearch = searchText.isEmpty || project.name.localizedCaseInsensitiveContains(searchText)
            if selectedFilter == "All" { return matchesSearch }
            return matchesSearch && project.status.capitalized == selectedFilter
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackgroundView()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title
                        HStack {
                            Text("Projects")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Spacer()
                            
                            Button {
                                appState.isNewProjectSheetPresented = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(AppColors.primaryIndigo)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search projects...", text: $searchText)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                        .padding(.horizontal, 20)
                        
                        // Category Pills
                        HStack(spacing: 12) {
                            ForEach(filterOptions, id: \.self) { option in
                                Button {
                                    withAnimation { selectedFilter = option }
                                } label: {
                                    Text(option)
                                        .font(.subheadline)
                                        .fontWeight(selectedFilter == option ? .bold : .regular)
                                        .foregroundColor(selectedFilter == option ? .white : .secondary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedFilter == option ? AppColors.primaryIndigo : Color.white.opacity(0.08))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Project Cards Grid/List
                        if filteredProjects.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 44))
                                    .foregroundColor(.secondary)
                                Text("No Projects Available")
                                    .font(.headline)
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
                    .padding(.bottom, 100)
                }
            }
            .task {
                seedInitialProjectsIfNeeded()
            }
        }
    }
    
    private func seedInitialProjectsIfNeeded() {
        if projects.isEmpty {
            let proj1 = Project(name: "DevJournal iOS", projectDescription: "Native iOS app with SwiftData, Supabase, and GitHub Integration", category: "Personal Project", progress: 0.72, status: "Active", gitHubRepoName: "DevJournal", commitsCount: 142, prsCount: 22, issuesCount: 4, starsCount: 48)
            let proj2 = Project(name: "Gameteract", projectDescription: "Interactive Capstone project platform with real-time analytics", category: "Capstone Project", progress: 0.84, status: "Active", gitHubRepoName: "Gameteract", commitsCount: 127, prsCount: 18, issuesCount: 7, starsCount: 24)
            let proj3 = Project(name: "OneNetworx", projectDescription: "OJT Enterprise Network Monitoring Solution", category: "OJT Project", progress: 1.00, status: "Archived", gitHubRepoName: "OneNetworx", commitsCount: 89, prsCount: 12, issuesCount: 0, starsCount: 15)
            
            modelContext.insert(proj1)
            modelContext.insert(proj2)
            modelContext.insert(proj3)
        }
    }
}

#Preview {
    ProjectsView()
        .environment(AppState())
}
