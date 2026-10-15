//
//  NewJournalView.swift
//  DevJournal
//

import SwiftUI
import SwiftData

struct NewJournalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedMood: String = "😄"
    @State private var focusLevel: String = "High"
    @State private var hoursSpent: Double = 2.5
    @State private var tagsString: String = "swift, github"
    @State private var selectedRepo: String = ""
    @State private var repos: [GitHubRepository] = []
    @State private var isLoadingRepos: Bool = false
    @Environment(\.modelContext) private var modelContext

    let moods = ["😞", "😐", "🙂", "😄", "🤩"]
    let focusLevels = ["Low", "Medium", "High"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackgroundView()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            TextField("What did you work on today?", text: $title)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1))
                        }
                        
                        // Content Text Editor
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Journal Content")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $content)
                                .frame(minHeight: 140)
                                .padding(8)
                                .scrollContentBackground(.hidden)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1))
                        }
                        
                        // Mood Selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Mood")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                ForEach(moods, id: \.self) { mood in
                                    Spacer()
                                    Text(mood)
                                        .font(.title)
                                        .padding(10)
                                        .background(selectedMood == mood ? AppColors.primaryIndigo.opacity(0.4) : Color.clear)
                                        .clipShape(Circle())
                                        .onTapGesture {
                                            selectedMood = mood
                                        }
                                    Spacer()
                                }
                            }
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        // Focus Level & Duration
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Focus Level")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                
                                Picker("Focus", selection: $focusLevel) {
                                    ForEach(focusLevels, id: \.self) { level in
                                        Text(level).tag(level)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Hours Spent: \(String(format: "%.1f", hoursSpent))h")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                
                                Slider(value: $hoursSpent, in: 0.5...12.0, step: 0.5)
                                    .accentColor(AppColors.accentCyan)
                            }
                        }
                        
                        // Tags & Repository Selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags (comma separated)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            TextField("e.g. swiftui, coredata, bugfix", text: $tagsString)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1))
                        }
                        
                        // GitHub Repo Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("GitHub Repository")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            if isLoadingRepos {
                                HStack {
                                    ProgressView()
                                    Text("Loading repos...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                            } else if repos.isEmpty {
                                // Fallback free-text entry
                                TextField("e.g. username/repo", text: $selectedRepo)
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1))
                            } else {
                                Picker("Repository", selection: $selectedRepo) {
                                    Text("None").tag("")
                                    ForEach(repos, id: \.fullName) { repo in
                                        Text(repo.name).tag(repo.fullName)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Journal Log")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Journal") { saveJournal() }
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.accentCyan)
                        .disabled(title.isEmpty)
                }
            }
            .task {
                isLoadingRepos = true
                repos = (try? await GitHubService.shared.fetchRepositories()) ?? []
                isLoadingRepos = false
            }
        }
    }
    
    private func saveJournal() {
        let tagArray = tagsString
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        let newEntry = JournalEntry(
            title: title,
            content: content.isEmpty ? "Development updates logged." : content,
            date: Date(),
            mood: selectedMood,
            focusLevel: focusLevel,
            hoursSpent: hoursSpent,
            tags: tagArray,
            gitHubRepoName: selectedRepo.isEmpty ? nil : selectedRepo,
            isSyncedWithSupabase: false   // SyncEngine will handle push
        )
        
        modelContext.insert(newEntry)
        
        // Kick off background sync (SyncEngine queues if offline)
        Task {
            await SyncEngine.shared.syncAll(using: modelContext)
        }
        
        dismiss()
    }
}

#Preview {
    NewJournalView()
}
