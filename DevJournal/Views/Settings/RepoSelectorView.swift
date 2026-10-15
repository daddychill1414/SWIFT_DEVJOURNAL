//
//  RepoSelectorView.swift
//  DevJournal
//
//  Allows selecting which GitHub repositories appear in the activity feed.
//

import SwiftUI

struct RepoSelectorView: View {
    @Environment(AppState.self) private var appState
    @State private var repos: [GitHubRepository] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        List {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView("Loading repositories...")
                    Spacer()
                }
            } else if repos.isEmpty {
                Text("No repositories found or GitHub not connected.")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(repos) { repo in
                    Button {
                        toggleRepo(repo.fullName)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(repo.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                if let desc = repo.description, !desc.isEmpty {
                                    Text(desc)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                            if appState.selectedRepoNames.contains(repo.fullName) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppColors.accentCyan)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Tracked Repositories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !appState.selectedRepoNames.isEmpty {
                    Button("Clear Filter") {
                        appState.selectedRepoNames.removeAll()
                    }
                }
            }
        }
        .task {
            await loadRepos()
        }
    }
    
    private func toggleRepo(_ name: String) {
        if appState.selectedRepoNames.contains(name) {
            appState.selectedRepoNames.remove(name)
        } else {
            appState.selectedRepoNames.insert(name)
        }
    }
    
    private func loadRepos() async {
        isLoading = true
        errorMessage = nil
        do {
            repos = try await GitHubService.shared.fetchRepositories()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
