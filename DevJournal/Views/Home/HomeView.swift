//
//  HomeView.swift
//  DevJournal
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var recentEntries: [JournalEntry]
    
    @State private var viewModel = HomeViewModel()
    
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
                                Text("\(appState.currentUser?.name ?? "Raniel") 👋")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                Spacer()
                                
                                Button {
                                    appState.selectedTab = .settings
                                } label: {
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(AppColors.primaryIndigo, AppColors.secondaryPurple)
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
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(viewModel.gitHubActivities) { activity in
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
                await viewModel.fetchRecentActivities()
                seedInitialDataIfNeeded()
            }
        }
    }
    
    private func seedInitialDataIfNeeded() {
        if recentEntries.isEmpty {
            let sample1 = JournalEntry(
                title: "Implemented GitHub synchronization",
                content: "Built native URLSession integration with async/await and Keychain token storage.",
                date: Date(),
                mood: "😄",
                focusLevel: "High",
                hoursSpent: 5.5,
                tags: ["github", "swift", "development"],
                gitHubRepoName: "DevJournal"
            )
            let sample2 = JournalEntry(
                title: "Designed Glassmorphism UI Components",
                content: "Created visionOS inspired ultraThinMaterial cards with soft stroke overlays.",
                date: Date().addingTimeInterval(-86400),
                mood: "🤩",
                focusLevel: "High",
                hoursSpent: 4.0,
                tags: ["swiftui", "design"],
                gitHubRepoName: "DevJournal"
            )
            modelContext.insert(sample1)
            modelContext.insert(sample2)
        }
    }
}

#Preview {
    HomeView()
        .environment(AppState())
}
