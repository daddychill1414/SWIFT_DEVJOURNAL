//
//  LandingView.swift
//  DevJournal
//

import SwiftUI

struct LandingView: View {
    @Environment(AppState.self) private var appState
    @State private var showingLoginScreen = false
    @State private var animateHero = false
    @State private var animateCards = false
    @State private var selectedFeatureIndex: Int = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackgroundView()
                
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 28) {
                            // Top Logo & Hero Branding
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(AppColors.primaryIndigo.opacity(0.25))
                                        .frame(width: 100, height: 100)
                                        .blur(radius: 20)
                                    
                                    Image(systemName: "swift")
                                        .font(.system(size: 54, weight: .semibold))
                                        .foregroundStyle(AppColors.primaryIndigo, AppColors.secondaryPurple)
                                        .scaleEffect(animateHero ? 1.08 : 0.94)
                                        .rotationEffect(.degrees(animateHero ? 5 : -5))
                                        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: animateHero)
                                }
                                .padding(.top, 32)
                                
                                VStack(spacing: 8) {
                                    Text("DevJournal")
                                        .font(.system(size: 38, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    Text("Log Your Journey. Quantify Your Progress.")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                }
                            }
                            
                            // Interactive Feature Showcase Cards
                            VStack(spacing: 16) {
                                FeatureCard(
                                    index: 0,
                                    selectedIndex: $selectedFeatureIndex,
                                    icon: "note.text.badge.plus",
                                    iconColor: AppColors.accentCyan,
                                    title: "Developer Worklogs",
                                    subtitle: "Capture focus sessions, daily bugs, mood, and code hours with zero friction.",
                                    demoContent: {
                                        HStack(spacing: 8) {
                                            Label("3.5 hrs logged", systemImage: "clock.fill")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(AppColors.accentCyan)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(AppColors.accentCyan.opacity(0.15))
                                                .clipShape(Capsule())
                                            
                                            Label("#swiftui", systemImage: "tag.fill")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(AppColors.secondaryPurple)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(AppColors.secondaryPurple.opacity(0.15))
                                                .clipShape(Capsule())
                                        }
                                    }
                                )
                                
                                FeatureCard(
                                    index: 1,
                                    selectedIndex: $selectedFeatureIndex,
                                    icon: "arrow.triangle.pull",
                                    iconColor: AppColors.primaryIndigo,
                                    title: "GitHub Activity Sync",
                                    subtitle: "Link repositories to visualize commit streams, pull requests, and issues.",
                                    demoContent: {
                                        HStack(spacing: 8) {
                                            Label("Main Branch Sync", systemImage: "checkmark.circle.fill")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(AppColors.successGreen)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(AppColors.successGreen.opacity(0.15))
                                                .clipShape(Capsule())
                                            
                                            Label("14 Commits", systemImage: "bolt.fill")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(AppColors.primaryIndigo)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(AppColors.primaryIndigo.opacity(0.15))
                                                .clipShape(Capsule())
                                        }
                                    }
                                )
                                
                                FeatureCard(
                                    index: 2,
                                    selectedIndex: $selectedFeatureIndex,
                                    icon: "chart.bar.xaxis",
                                    iconColor: AppColors.secondaryPurple,
                                    title: "Productivity Analytics",
                                    subtitle: "Gain deep insights into peak productivity hours with interactive Swift Charts.",
                                    demoContent: {
                                        HStack(spacing: 8) {
                                            Label("Peak Hour: 2 PM", systemImage: "flame.fill")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.orange)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(Color.orange.opacity(0.15))
                                                .clipShape(Capsule())
                                            
                                            Label("94% Focus", systemImage: "chart.line.uptrend.xyaxis")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(AppColors.secondaryPurple)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(AppColors.secondaryPurple.opacity(0.15))
                                                .clipShape(Capsule())
                                        }
                                    }
                                )
                                
                                FeatureCard(
                                    index: 3,
                                    selectedIndex: $selectedFeatureIndex,
                                    icon: "icloud.and.arrow.up",
                                    iconColor: AppColors.successGreen,
                                    title: "Supabase Cloud Database",
                                    subtitle: "Seamlessly synchronize project portfolios and logs across all your devices.",
                                    demoContent: {
                                        HStack(spacing: 8) {
                                            Label("Realtime Database", systemImage: "lock.shield.fill")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(AppColors.successGreen)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(AppColors.successGreen.opacity(0.15))
                                                .clipShape(Capsule())
                                        }
                                    }
                                )
                            }
                            .padding(.horizontal, 20)
                            .offset(y: animateCards ? 0 : 30)
                            .opacity(animateCards ? 1 : 0)
                        }
                        .padding(.bottom, 24)
                    }
                    
                    // Bottom Sticky Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            showingLoginScreen = true
                        } label: {
                            HStack {
                                Text("Get Started")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Image(systemName: "arrow.right")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.primaryIndigo)
                            .clipShape(Capsule())
                            .shadow(color: AppColors.primaryIndigo.opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(.ultraThinMaterial)
                }
            }
            .navigationDestination(isPresented: $showingLoginScreen) {
                LoginView()
            }
            .onAppear {
                animateHero = true
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15)) {
                    animateCards = true
                }
            }
        }
    }
}

private struct FeatureCard<DemoContent: View>: View {
    let index: Int
    @Binding var selectedIndex: Int
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @ViewBuilder let demoContent: () -> DemoContent
    
    var isSelected: Bool {
        selectedIndex == index
    }
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedIndex = index
            }
        } label: {
            GlassCard(style: isSelected ? .regular : .thin) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(iconColor.opacity(isSelected ? 0.25 : 0.15))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: icon)
                                .font(.title3)
                                .foregroundColor(iconColor)
                                .symbolEffect(.bounce, value: isSelected)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.subheadline)
                                        .foregroundColor(iconColor)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            
                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    if isSelected {
                        demoContent()
                            .padding(.top, 4)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? iconColor.opacity(0.5) : Color.white.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
            )
            .scaleEffect(isSelected ? 1.01 : 0.99)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LandingView()
        .environment(AppState())
}
