//
//  GitHubActivity.swift
//  DevJournal
//

import Foundation
import SwiftData

@Model
final class GitHubActivityItem {
    @Attribute(.unique) var id: String
    var message: String
    var repoName: String
    var timestamp: Date
    var type: String // commit, pr, issue, star
    var author: String
    
    init(
        id: String = UUID().uuidString,
        message: String,
        repoName: String,
        timestamp: Date = Date(),
        type: String = "commit",
        author: String = "ranielgo"
    ) {
        self.id = id
        self.message = message
        self.repoName = repoName
        self.timestamp = timestamp
        self.type = type
        self.author = author
    }
}

struct GitHubRepository: Codable, Identifiable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let htmlUrl: String
    let stargazersCount: Int
    let forksCount: Int
    let openIssuesCount: Int
    let language: String?
    let isPrivate: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case fullName = "full_name"
        case description
        case htmlUrl = "html_url"
        case stargazersCount = "stargazers_count"
        case forksCount = "forks_count"
        case openIssuesCount = "open_issues_count"
        case language
        case isPrivate = "private"
    }
}

struct GitHubCommit: Codable, Identifiable {
    var id: String { sha }
    let sha: String
    let commit: CommitDetail
    let htmlUrl: String
    
    struct CommitDetail: Codable {
        let message: String
        let author: CommitAuthor
    }
    
    struct CommitAuthor: Codable {
        let name: String
        let date: String
    }
    
    enum CodingKeys: String, CodingKey {
        case sha
        case commit
        case htmlUrl = "html_url"
    }
}
