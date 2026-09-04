//
//  Project.swift
//  DevJournal
//

import Foundation
import SwiftData

@Model
final class Project {
    @Attribute(.unique) var id: UUID
    var name: String
    var projectDescription: String
    var category: String // Personal, Capstone, OJT, Enterprise
    var progress: Double // 0.0 to 1.0
    var status: String // Active, Archived, Starred
    var gitHubRepoName: String?
    var commitsCount: Int
    var prsCount: Int
    var issuesCount: Int
    var starsCount: Int
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        projectDescription: String,
        category: String = "Personal Project",
        progress: Double = 0.0,
        status: String = "Active",
        gitHubRepoName: String? = nil,
        commitsCount: Int = 0,
        prsCount: Int = 0,
        issuesCount: Int = 0,
        starsCount: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.projectDescription = projectDescription
        self.category = category
        self.progress = progress
        self.status = status
        self.gitHubRepoName = gitHubRepoName
        self.commitsCount = commitsCount
        self.prsCount = prsCount
        self.issuesCount = issuesCount
        self.starsCount = starsCount
        self.updatedAt = updatedAt
    }
}
