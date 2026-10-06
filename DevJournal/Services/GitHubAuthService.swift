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
        guard let url = URL(string: "https://github.com/login/oauth/access_token") else {
            self.authError = "Invalid token exchange URL."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let body: [String: String] = [
            "client_id": clientID,
            "client_secret": AppConfiguration.gitHubClientSecret,
            "code": code,
            "redirect_uri": redirectURI
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.authError = error.localizedDescription
                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let accessToken = json["access_token"] as? String else {
                    self?.authError = "Failed to parse access token from GitHub."
                    return
                }

                _ = KeychainService.shared.save(key: "github_access_token", string: accessToken)
                self?.isAuthenticated = true
                withAnimation(.spring()) {
                    appState.isGitHubConnected = true
                    appState.isAuthenticated = true
                }
            }
        }.resume()
    }
    
    func signOut() {
        _ = KeychainService.shared.delete(key: "github_access_token")
        self.isAuthenticated = false
    }
}
