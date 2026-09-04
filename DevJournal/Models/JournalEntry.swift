//
//  JournalEntry.swift
//  DevJournal
//

import Foundation
import SwiftData

@Model
final class JournalEntry {
    @Attribute(.unique) var id: UUID
    var title: String
    var content: String
    var date: Date
    var mood: String // 😞 😐 🙂 😄 🤩
    var focusLevel: String // Low, Medium, High
    var hoursSpent: Double
    var tags: [String]
    var projectId: UUID?
    var gitHubRepoName: String?
    var isSyncedWithSupabase: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        date: Date = Date(),
        mood: String = "😄",
        focusLevel: String = "High",
        hoursSpent: Double = 2.5,
        tags: [String] = [],
        projectId: UUID? = nil,
        gitHubRepoName: String? = nil,
        isSyncedWithSupabase: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.date = date
        self.mood = mood
        self.focusLevel = focusLevel
        self.hoursSpent = hoursSpent
        self.tags = tags
        self.projectId = projectId
        self.gitHubRepoName = gitHubRepoName
        self.isSyncedWithSupabase = isSyncedWithSupabase
    }
}
