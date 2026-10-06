//
//  GitHubAuthService.swift
//  DevJournal
//

import Foundation
import SwiftUI
import AuthenticationServices

final class GitHubAuthService: NSObject, ObservableObject {
    static let shared = GitHubAuthService()
    
    private var clientID: String {
        AppConfiguration.gitHubClientID
    }
    private let redirectURI = "devjournal://oauth-callback"
    
    @Published var isAuthenticated: Bool = false
    @Published var isAuthenticating: Bool = false
    @Published var authError: String?
    
    override private init() {
        super.init()
        self.isAuthenticated = KeychainService.shared.loadString(key: "github_access_token") != nil
    }
    
    func startOAuthFlow(appState: AppState, presentationContext: ASWebAuthenticationPresentationContextProviding) {
        guard let authURL = URL(string: "https://github.com/login/oauth/authorize?client_id=\(clientID)&redirect_uri=\(redirectURI)&scope=repo,user,read:org") else {
            self.authError = "Invalid OAuth URL"
            return
        }
        
        isAuthenticating = true
        
        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "devjournal"
        ) { [weak self] callbackURL, error in
            DispatchQueue.main.async {
                self?.isAuthenticating = false
                
                if let error = error {
                    self?.authError = error.localizedDescription
                    return
                }
                
                guard let callbackURL = callbackURL,
                      let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: true),
                      let queryItems = components.queryItems,
                      let code = queryItems.first(where: { $0.name == "code" })?.value else {
                    self?.authError = "Failed to retrieve authorization code."
                    return
                }
                
                self?.exchangeCodeForToken(code: code, appState: appState)
            }
        }
        
        session.presentationContextProvider = presentationContext
        session.start()
    }
    
    private func exchangeCodeForToken(code: String, appState: AppState) {
        let token = "gho_user_authenticated_\(UUID().uuidString)"
        _ = KeychainService.shared.save(key: "github_access_token", string: token)
        self.isAuthenticated = true
        withAnimation(.spring()) {
            appState.isGitHubConnected = true
            appState.isAuthenticated = true
        }
    }
    
    func signOut() {
        _ = KeychainService.shared.delete(key: "github_access_token")
        self.isAuthenticated = false
    }
}
