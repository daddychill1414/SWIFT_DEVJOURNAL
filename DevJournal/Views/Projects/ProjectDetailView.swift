//
//  ProjectDetailView.swift
//  DevJournal
//

import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    @State private var selectedTab = "Overview"
    let detailTabs = ["Overview", "Activity", "Files", "Settings"]
    
    var body: some View {
        ZStack {
            AtmosphericBackgroundView()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Banner
                    GlassCard(style: .regular) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(project.category)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.accentCyan)
                                Spacer()
                                Text(project.status)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.successGreen)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(AppColors.successGreen.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                            
                            Text(project.name)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text(project.projectDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Stats 4-Grid
                    HStack(spacing: 12) {
                        statBox(title: "Commits", value: "\(project.commitsCount)", icon: "hammer.fill", color: AppColors.primaryIndigo)
                        statBox(title: "Pull Requests", value: "\(project.prsCount)", icon: "arrow.triangle.pull", color: AppColors.secondaryPurple)
                        statBox(title: "Issues", value: "\(project.issuesCount)", icon: "exclamationmark.circle.fill", color: AppColors.warningOrange)
                        statBox(title: "Stars", value: "\(project.starsCount)", icon: "star.fill", color: AppColors.accentCyan)
                    }
                    
                    // Detail Segmented Control
                    HStack {
                        ForEach(detailTabs, id: \.self) { tab in
                            Button {
                                withAnimation { selectedTab = tab }
                            } label: {
                                Text(tab)
                                    .font(.subheadline)
                                    .fontWeight(selectedTab == tab ? .bold : .regular)
                                    .foregroundColor(selectedTab == tab ? AppColors.accentCyan : .secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(selectedTab == tab ? Color.white.opacity(0.1) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(4)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    
                    // Tab Content
                    if selectedTab == "Overview" {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Recent Commits")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            GlassCard(style: .thin) {
                                VStack(alignment: .leading, spacing: 12) {
                                    commitRow(hash: "a1b2c3d", msg: "feat: implement visionOS glassmorphism components", date: "2h ago")
                                    Divider()
                                    commitRow(hash: "e5f6g7h", msg: "fix: SwiftData concurrency & model container initialization", date: "5h ago")
                                    Divider()
                                    commitRow(hash: "8i9j0k1", msg: "docs: update API setup instructions", date: "1d ago")
                                }
                            }
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "square.stack.3d.up")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("\(selectedTab) data synchronized with GitHub REST API.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 180)
                    }
                }
                .padding(20)
                .padding(.bottom, 60)
            }
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func statBox(title: String, value: String, icon: String, color: Color) -> some View {
        GlassCard(style: .ultraThin, padding: 10) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    @ViewBuilder
    private func commitRow(hash: String, msg: String, date: String) -> some View {
        HStack(spacing: 10) {
            Text(hash)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(AppColors.accentCyan)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AppColors.accentCyan.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            Text(msg)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer()
            
            Text(date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ProjectDetailView(project: Project(name: "DevJournal iOS", projectDescription: "Native iOS App", commitsCount: 142, prsCount: 18, issuesCount: 4, starsCount: 24))
}
