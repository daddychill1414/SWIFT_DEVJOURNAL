//  Configuration.swift
//  DevJournal
//
//  IMPORTANT XCODE SETUP INSTRUCTIONS:
//  ==================================
//  To configure private secrets for Supabase and GitHub OAuth without committing credentials:
//
//  Option A (Xcode Scheme Environment Variables):
//  1. In Xcode, go to Product -> Scheme -> Edit Scheme... (Cmd + <)
//  2. Select "Run" on the left sidebar and navigate to the "Arguments" tab.
//  3. Under "Environment Variables", add:
//     - SUPABASE_URL       : https://your-project.supabase.co
//     - SUPABASE_ANON_KEY  : your-anon-key
//     - GITHUB_CLIENT_ID   : your-github-client-id
//
//  Option B (Info.plist Custom Keys):
//  1. Open DevJournal Info.plist
//  2. Add SUPABASE_URL, SUPABASE_ANON_KEY, and GITHUB_CLIENT_ID string values.
//

import Foundation

enum AppConfiguration {
    static var supabaseURL: String {
        ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "https://your-project.supabase.co"
    }
    
    static var supabaseAnonKey: String {
        ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? "YOUR_SUPABASE_ANON_KEY"
    }
    
    static var gitHubClientID: String {
        ProcessInfo.processInfo.environment["GITHUB_CLIENT_ID"] ?? "YOUR_GITHUB_CLIENT_ID"
    }
}
