//
//  JournalView.swift
//  DevJournal
//

import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    
    @State private var searchText = ""
    
    var filteredEntries: [JournalEntry] {
        if searchText.isEmpty {
            return entries
        } else {
            return entries.filter { $0.title.localizedCaseInsensitiveContains(searchText) || $0.content.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackgroundView()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title Bar
                        HStack {
                            Text("Journal")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Spacer()
                            
                            Button {
                                appState.isNewJournalSheetPresented = true
                            } label: {
                                Image(systemName: "square.and.pencil")
                                    .font(.title2)
                                    .foregroundColor(AppColors.accentCyan)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search entries...", text: $searchText)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                        .padding(.horizontal, 20)
                        
                        // Entries List
                        if filteredEntries.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "book.closed")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                Text("No Journal Entries Found")
                                    .font(.headline)
                                Text("Tap '+' to create your first development log entry.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 250)
                            .padding(.horizontal, 40)
                        } else {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(filteredEntries) { entry in
                                    NavigationLink(destination: JournalEntryDetailView(entry: entry)) {
                                        GlassCard(style: .thin) {
                                            VStack(alignment: .leading, spacing: 12) {
                                                HStack {
                                                    Text(entry.date.formatted(date: .abbreviated, time: .omitted).uppercased())
                                                        .font(.caption)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(AppColors.accentCyan)
                                                    
                                                    Spacer()
                                                    
                                                    Text(entry.mood)
                                                        .font(.title3)
                                                }
                                                
                                                Text(entry.title)
                                                    .font(.title3)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.primary)
                                                    .multilineTextAlignment(.leading)
                                                
                                                Text(entry.content)
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.leading)
                                                
                                                HStack(spacing: 12) {
                                                    Label("\(String(format: "%.1fh", entry.hoursSpent))", systemImage: "clock")
                                                        .font(.caption)
                                                        .foregroundColor(.primary)
                                                    
                                                    Label("Focus: \(entry.focusLevel)", systemImage: "bolt.fill")
                                                        .font(.caption)
                                                        .foregroundColor(AppColors.warningOrange)
                                                    
                                                    Spacer()
                                                    
                                                    if entry.isSyncedWithSupabase {
                                                        Image(systemName: "cloud.fill")
                                                            .font(.caption)
                                                            .foregroundColor(AppColors.successGreen)
                                                    }
                                                }
                                                
                                                if !entry.tags.isEmpty {
                                                    HStack {
                                                        ForEach(entry.tags, id: \.self) { tag in
                                                            Text("#\(tag)")
                                                                .font(.caption2)
                                                                .fontWeight(.semibold)
                                                                .foregroundColor(AppColors.primaryIndigo)
                                                                .padding(.horizontal, 8)
                                                                .padding(.vertical, 4)
                                                                .background(AppColors.primaryIndigo.opacity(0.15))
                                                                .clipShape(Capsule())
                                                        }
                                                    }
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
        }
    }
}

struct JournalEntryDetailView: View {
    let entry: JournalEntry
    
    var body: some View {
        ZStack {
            AtmosphericBackgroundView()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    GlassCard(style: .regular) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text(entry.date.formatted(date: .long, time: .shortened))
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.accentCyan)
                                Spacer()
                                Text(entry.mood)
                                    .font(.title2)
                            }
                            
                            Text(entry.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Divider()
                            
                            Text(entry.content)
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineSpacing(6)
                            
                            HStack(spacing: 16) {
                                Label("Duration: \(String(format: "%.1fh", entry.hoursSpent))", systemImage: "clock.fill")
                                Label("Focus: \(entry.focusLevel)", systemImage: "brain.head.profile")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Entry Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    JournalView()
        .environment(AppState())
}
