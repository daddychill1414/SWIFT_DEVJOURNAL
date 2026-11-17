//
//  LoginView.swift
//  DevJournal
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var gitHubAuth = GitHubAuthService.shared
    
    @State private var isAuthenticatingLocally = false
    @State private var errorMessage: String? = nil
    
    private var isLoading: Bool {
        gitHubAuth.isAuthenticating || isAuthenticatingLocally
    }
    
    var body: some View {
        ZStack {
            AtmosphericBackgroundView()
            
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        Spacer(minLength: 20)
                        
                        // Header / GitHub Branding Hero
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.primaryIndigo.opacity(0.25))
                                    .frame(width: 90, height: 90)
                                    .blur(radius: 22)
                                
                                Circle()
                                    .fill(Color.primary.opacity(0.06))
                                    .frame(width: 76, height: 76)
                                    .overlay(
                                        Circle()
                                            .stroke(AppColors.glassBorderLight, lineWidth: 1)
                                    )
                                
                                Image(systemName: "terminal.fill")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [AppColors.primaryIndigo, AppColors.accentCyan],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            VStack(spacing: 8) {
                                Text("Sign In with GitHub")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                
                                Text("DevJournal integrates directly with your GitHub account to sync repositories, commits, and engineering worklogs.")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                        }
                        
                        // Glass Auth Card
                        GlassCard(style: .regular) {
                            VStack(spacing: 22) {
                                // Error Banner
                                if let error = errorMessage ?? gitHubAuth.authError {
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                            .font(.subheadline)
                                            .padding(.top, 2)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Authentication Error")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.red)
                                            
                                            Text(error)
                                                .font(.caption2)
                                                .foregroundColor(.red.opacity(0.9))
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        
                                        Spacer()
                                        
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                errorMessage = nil
                                                gitHubAuth.authError = nil
                                            }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.subheadline)
                                                .foregroundColor(.red.opacity(0.7))
                                        }
                                    }
                                    .padding(12)
                                    .background(Color.red.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.red.opacity(0.25), lineWidth: 1)
                                    )
                                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                                }
                                
                                // Value proposition features
                                VStack(spacing: 16) {
                                    AuthFeatureRow(
                                        icon: "arrow.triangle.pull",
                                        iconColor: AppColors.primaryIndigo,
                                        title: "Automatic Activity Tracking",
                                        subtitle: "Sync commits, branches, pull requests, and code reviews automatically."
                                    )
                                    
                                    Divider()
                                        .background(Color.primary.opacity(0.08))
                                    
                                    AuthFeatureRow(
                                        icon: "folder.fill.badge.gearshape",
                                        iconColor: AppColors.accentCyan,
                                        title: "Repository Association",
                                        subtitle: "Tag daily focus logs and projects to specific repositories."
                                    )
                                    
                                    Divider()
                                        .background(Color.primary.opacity(0.08))
                                    
                                    AuthFeatureRow(
                                        icon: "chart.line.uptrend.xyaxis",
                                        iconColor: AppColors.secondaryPurple,
                                        title: "Developer Analytics",
                                        subtitle: "Visualize peak focus hours and productivity velocity over time."
                                    )
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 4)
                                
                                // Primary Action: Continue with GitHub
                                Button {
                                    performGitHubAuth()
                                } label: {
                                    ZStack {
                                        if isLoading {
                                            HStack(spacing: 12) {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                    .scaleEffect(0.9)
                                                
                                                Text("Connecting to GitHub...")
                                                    .font(.headline)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                            }
                                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                                        } else {
                                            HStack(spacing: 12) {
                                                Image(systemName: "terminal.fill")
                                                    .font(.title3)
                                                
                                                Text("Continue with GitHub")
                                                    .font(.headline)
                                                    .fontWeight(.bold)
                                                
                                                Image(systemName: "arrow.right")
                                                    .font(.subheadline.bold())
                                            }
                                            .foregroundColor(.white)
                                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            colors: [
                                                AppColors.primaryIndigo,
                                                AppColors.secondaryPurple
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                    .shadow(color: AppColors.primaryIndigo.opacity(0.4), radius: 12, x: 0, y: 6)
                                }
                                .disabled(isLoading)
                                .animation(.easeInOut(duration: 0.25), value: isLoading)
                                .padding(.top, 4)
                                
                                // Security & Privacy Footnote
                                HStack(spacing: 6) {
                                    Image(systemName: "lock.shield.fill")
                                        .font(.caption2)
                                        .foregroundColor(AppColors.successGreen)
                                    
                                    Text("OAuth 2.0 • Secured in Apple Keychain")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 24)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                        Text("Back")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .onChange(of: gitHubAuth.isAuthenticating) { _, isAuthenticating in
            if !isAuthenticating {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    if !appState.isAuthenticated {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isAuthenticatingLocally = false
                        }
                    }
                }
            }
        }
        .onChange(of: gitHubAuth.authError) { _, error in
            if error != nil {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isAuthenticatingLocally = false
                }
            }
        }
    }
    
    private func performGitHubAuth() {
        errorMessage = nil
        gitHubAuth.authError = nil
        withAnimation(.easeInOut(duration: 0.2)) {
            isAuthenticatingLocally = true
        }
        GitHubAuthService.shared.startOAuthFlow(appState: appState)
    }
}

private struct AuthFeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 38, height: 38)
                
                Image(systemName: icon)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    LoginView()
        .environment(AppState())
}
