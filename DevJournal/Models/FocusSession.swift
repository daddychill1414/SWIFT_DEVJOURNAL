//
//  FocusSession.swift
//  DevJournal
//

import Foundation
import SwiftData

@Model
final class FocusSession {
    @Attribute(.unique) var id: UUID
    var startTime: Date
    var endTime: Date?
    var durationMinutes: Int
    var notes: String
    var isCompleted: Bool
    
    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        durationMinutes: Int = 25,
        notes: String = "",
        isCompleted: Bool = false
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.isCompleted = isCompleted
    }
}

struct UserProfile: Codable, Identifiable {
    var id: String
    var name: String
    var username: String
    var avatarUrl: String?
    var bio: String?
    var gitHubUsername: String?
    
    static let sample = UserProfile(
        id: "usr_12345",
        name: "Raniel Go",
        username: "ranielgo",
        avatarUrl: "https://github.com/ranielgo.png",
        bio: "Full Stack & iOS Developer building DevJournal",
        gitHubUsername: "ranielgo"
    )
}
