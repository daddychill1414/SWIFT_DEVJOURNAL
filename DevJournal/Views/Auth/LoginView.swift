//
//  LoginView.swift
//  DevJournal
//

import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            AtmosphericBackgroundView()
            
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        Spacer(minLength: 16)
                        
                        // Header Title
                        VStack(spacing: 8) {
                            Text("Welcome Back")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("Sign in to sync your logs & projects")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        // Glass Login Form Card
                        GlassCard(style: .regular) {
                            VStack(spacing: 20) {
                                if let error = errorMessage {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                        Text(error)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.red)
                                        Spacer()
                                    }
                                    .padding(12)
                                    .background(Color.red.opacity(0.12))
                                    .cornerRadius(10)
                                }
                                
                                // Email Input
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("EMAIL ADDRESS")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                    
                                    HStack(spacing: 12) {
                                        Image(systemName: "envelope.fill")
                                            .font(.subheadline)
                                            .foregroundColor(AppColors.primaryIndigo)
                                        
                                        TextField("developer@apple.com", text: $email)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            #if os(iOS)
                                            .textInputAutocapitalization(.never)
                                            #endif
                                            .autocorrectionDisabled(true)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(Color.primary.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                    )
                                }
                                
                                // Password Input
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("PASSWORD")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                    
                                    HStack(spacing: 12) {
                                        Image(systemName: "lock.fill")
                                            .font(.subheadline)
                                            .foregroundColor(AppColors.primaryIndigo)
                                        
                                        SecureField("••••••••", text: $password)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(Color.primary.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                    )
                                }
                                
                                // Sign In Button
                                Button {
                                    performLogin()
                                } label: {
                                    HStack {
                                        if isLoading {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Text("Sign In")
                                                .font(.headline)
                                                .fontWeight(.bold)
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                                    .background(AppColors.primaryIndigo)
                                    .clipShape(Capsule())
                                    .shadow(color: AppColors.primaryIndigo.opacity(0.35), radius: 10, x: 0, y: 5)
                                }
                                .disabled(isLoading)
                                .padding(.top, 6)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.primary.opacity(0.2))
                                .frame(height: 1)
                            Text("OR")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary.opacity(0.7))
                                .padding(.horizontal, 8)
                            Rectangle()
                                .fill(Color.primary.opacity(0.2))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 4)
                        
                        // Social Sign-in Options
                        VStack(spacing: 14) {
                            Button {
                                performGitHubAuth()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "terminal.fill")
                                        .font(.title3)
                                    Text("Continue with GitHub")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(Color(uiColor: .systemBackground))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Color.primary)
                                .clipShape(Capsule())
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
                            }
                            .padding(.horizontal, 20)
                            
                            Button {
                                withAnimation(.spring()) {
                                    appState.isAuthenticated = true
                                }
                            } label: {
                                Text("Skip for Now")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColors.primaryIndigo)
                                    .padding(.vertical, 6)
                            }
                        }
                        
                        Spacer(minLength: 24)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
    }
    
    private func performLogin() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            withAnimation(.spring()) {
                appState.isAuthenticated = true
            }
        }
    }
    
    private func performGitHubAuth() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isLoading = false
            appState.isGitHubConnected = true
            withAnimation(.spring()) {
                appState.isAuthenticated = true
            }
        }
    }
}

#Preview {
    LoginView()
        .environment(AppState())
}
