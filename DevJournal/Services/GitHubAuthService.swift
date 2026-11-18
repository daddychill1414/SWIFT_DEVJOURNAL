//
//  GitHubAuthService.swift
//  DevJournal
//

import Foundation
import SwiftUI
import AuthenticationServices

final class GitHubAuthService: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = GitHubAuthService()
    
    private var clientID: String {
        AppConfiguration.gitHubClientID
    }
    private let redirectURI = "devjournal://oauth-callback"
    
    @Published var isAuthenticated: Bool = false
    @Published var isAuthenticating: Bool = false
    @Published var authError: String?
    
    private var authSession: ASWebAuthenticationSession?
    private var lastExchangedCode: String?
    
    override private init() {
        super.init()
        self.isAuthenticated = KeychainService.shared.loadString(key: "github_access_token") != nil
    }
    
    // MARK: - ASWebAuthenticationPresentationContextProviding
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap { $0.windows }.first { $0.isKeyWindow }
            ?? scenes.flatMap { $0.windows }.first
            ?? ASPresentationAnchor()
        return window
    }
    
    func startOAuthFlow(appState: AppState) {
        guard let authURL = URL(string: "https://github.com/login/oauth/authorize?client_id=\(clientID)&redirect_uri=\(redirectURI)&scope=repo,user,read:org") else {
            self.authError = "Invalid OAuth URL"
            return
        }
        
        isAuthenticating = true
        authError = nil
        
        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "devjournal"
        ) { [weak self] callbackURL, error in
            DispatchQueue.main.async {
                self?.isAuthenticating = false
                self?.authSession = nil
                
                if let error = error {
                    let nsError = error as NSError
                    if nsError.domain == ASWebAuthenticationSessionErrorDomain &&
                        nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        print("GitHubAuthService: User cancelled authorization flow.")
                        return
                    }
                    print("GitHubAuthService: Authentication session error: \(error.localizedDescription)")
                    self?.authError = error.localizedDescription
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    self?.authError = "Failed to retrieve authorization callback URL."
                    return
                }
                
                self?.handleCallbackURL(callbackURL, appState: appState)
            }
        }
        
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        self.authSession = session
        
        let started = session.start()
        if !started {
            self.isAuthenticating = false
            self.authSession = nil
            self.authError = "Unable to start web authentication session."
        }
    }
    
    func handleCallbackURL(_ url: URL, appState: AppState) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems,
              let code = queryItems.first(where: { $0.name == "code" })?.value else {
            self.authError = "Failed to retrieve authorization code from callback URL."
            return
        }
        
        guard code != lastExchangedCode else {
            print("GitHubAuthService: Authorization code already processed.")
            return
        }
        lastExchangedCode = code
        
        exchangeCodeForToken(code: code, appState: appState)
    }
    
    private func exchangeCodeForToken(code: String, appState: AppState) {
        guard let url = URL(string: "https://github.com/login/oauth/access_token") else {
            self.authError = "Invalid token exchange URL."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("DevJournal/1.0", forHTTPHeaderField: "User-Agent")
        request.assumesHTTP3Capable = false
        request.timeoutInterval = 30

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "client_secret", value: AppConfiguration.gitHubClientSecret),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: redirectURI)
        ]
        let bodyString = components.percentEncodedQuery ?? ""
        request.httpBody = bodyString.data(using: .utf8)
        request.setValue("\(request.httpBody?.count ?? 0)", forHTTPHeaderField: "Content-Length")

        let config = URLSessionConfiguration.ephemeral
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        config.httpCookieStorage = nil
        config.httpShouldSetCookies = false
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 15
        let tokenSession = URLSession(configuration: config)

        tokenSession.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("GitHubAuthService: Network error: \(error.localizedDescription)")
                    self?.authError = error.localizedDescription
                    return
                }

                guard let data = data else {
                    self?.authError = "No data returned from GitHub token exchange."
                    return
                }
                
                let rawResponse = String(data: data, encoding: .utf8) ?? ""
                print("GitHubAuthService token response: \(rawResponse)")

                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    self?.authError = "Failed to parse response: \(rawResponse)"
                    return
                }

                if let err = json["error"] as? String {
                    let desc = json["error_description"] as? String ?? err
                    print("GitHubAuthService error: \(desc)")
                    self?.authError = desc
                    return
                }

                guard let accessToken = json["access_token"] as? String else {
                    self?.authError = "Failed to parse access token from GitHub: \(rawResponse)"
                    return
                }

                print("GitHubAuthService: Success! Got access token.")
                _ = KeychainService.shared.save(key: "github_access_token", string: accessToken)
                self?.isAuthenticated = true
                Task {
                    do {
                        let profile = try await GitHubService.shared.fetchUserProfile()
                        print("GitHubAuthService: Fetched user profile for \(profile.username)")
                        await MainActor.run {
                            withAnimation(.spring()) {
                                appState.currentUser = profile
                                appState.isGitHubConnected = true
                                appState.isAuthenticated = true
                            }
                        }
                    } catch {
                        print("GitHubAuthService: Failed to fetch profile: \(error)")
                        await MainActor.run {
                            withAnimation(.spring()) {
                                appState.isGitHubConnected = true
                                appState.isAuthenticated = true
                            }
                        }
                    }
                }
            }
        }.resume()
    }
    
    func signOut() {
        _ = KeychainService.shared.delete(key: "github_access_token")
        self.isAuthenticated = false
        self.lastExchangedCode = nil
        GitHubService.shared.clearCachedProfile()
    }
}
