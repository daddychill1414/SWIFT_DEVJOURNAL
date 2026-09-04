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
    @State private var selectedRepo: String = "DevJournal"
    
    let moods = ["😞", "😐", "🙂", "😄", "🤩"]
    let focusLevels = ["Low", "Medium", "High"]
    let repos = ["DevJournal", "Gameteract", "OneNetworx"]
    
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
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Journal Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Journal") {
                        saveJournal()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.accentCyan)
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveJournal() {
        let tagArray = tagsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let newEntry = JournalEntry(
            title: title,
            content: content.isEmpty ? "Development updates logged." : content,
            date: Date(),
            mood: selectedMood,
            focusLevel: focusLevel,
            hoursSpent: hoursSpent,
            tags: tagArray,
            gitHubRepoName: selectedRepo
        )
        
        modelContext.insert(newEntry)
        
        // Sync with Supabase asynchronously
        Task {
            try? await SupabaseService.shared.syncJournalEntry(newEntry)
        }
        
        dismiss()
    }
}

#Preview {
    NewJournalView()
}
