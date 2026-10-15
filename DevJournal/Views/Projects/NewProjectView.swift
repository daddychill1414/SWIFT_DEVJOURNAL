//
//  NewProjectView.swift
//  DevJournal
//

import SwiftUI
import SwiftData

struct NewProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name: String = ""
    @State private var projectDescription: String = ""
    @State private var category: String = "Personal Project"
    @State private var progress: Double = 0.5
    @State private var gitHubRepoName: String = ""
    
    let categories = ["Personal Project", "Capstone Project", "OJT Project", "Enterprise"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackgroundView()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Project Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Project Name")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            TextField("e.g. Swift AI Assistant", text: $name)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1))
                        }
                        
                        // Project Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $projectDescription)
                                .frame(minHeight: 120)
                                .padding(8)
                                .scrollContentBackground(.hidden)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1))
                        }
                        
                        // Category Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            Picker("Category", selection: $category) {
                                ForEach(categories, id: \.self) { cat in
                                    Text(cat).tag(cat)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        // Initial Progress
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Progress")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(progress * 100))%")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.accentCyan)
                            }
                            
                            Slider(value: $progress, in: 0.0...1.0, step: 0.05)
                                .accentColor(AppColors.primaryIndigo)
                        }
                        
                        // GitHub Repository
                        VStack(alignment: .leading, spacing: 8) {
                            Text("GitHub Repository (Optional)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            TextField("e.g. myorg/myrepo", text: $gitHubRepoName)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Project")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Project") {
                        saveProject()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.accentCyan)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveProject() {
        let newProject = Project(
            name: name,
            projectDescription: projectDescription.isEmpty ? "Developer project portfolio item." : projectDescription,
            category: category,
            progress: progress,
            status: "Active",
            gitHubRepoName: gitHubRepoName.isEmpty ? nil : gitHubRepoName,
            commitsCount: 0,
            prsCount: 0,
            issuesCount: 0,
            starsCount: 0,
            isSyncedWithSupabase: false   // SyncEngine will handle push
        )
        
        modelContext.insert(newProject)
        
        // Kick off background sync (queues if offline)
        Task {
            await SyncEngine.shared.syncAll(using: modelContext)
        }
        
        dismiss()
    }
}

#Preview {
    NewProjectView()
        .environment(AppState())
}
