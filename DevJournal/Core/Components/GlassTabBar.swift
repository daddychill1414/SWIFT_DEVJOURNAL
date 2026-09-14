//
//  GlassTabBar.swift
//  DevJournal
//

import SwiftUI

struct GlassTabBar: View {
    @Binding var selectedTab: AppTab
    let onPlusTap: () -> Void
    
    var body: some View {
        ZStack {
            // Main Glass Capsule Bar Container
            HStack(spacing: 0) {
                tabButton(tab: .home, title: "Home", systemImage: "house.fill")
                tabButton(tab: .projects, title: "Projects", systemImage: "folder.fill")
                
                // Clear placeholder space for the elevated center button
                Color.clear
                    .frame(width: 52, height: 44)
                
                tabButton(tab: .journal, title: "Journal", systemImage: "book.closed.fill")
                tabButton(tab: .insights, title: "Insights", systemImage: "chart.xyaxis.line")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 8)
            
            // Center Elevated Floating Plus Button (Perfectly centered vertically)
            Button(action: onPlusTap) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.primaryIndigo, AppColors.secondaryPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: AppColors.primaryIndigo.opacity(0.5), radius: 8, x: 0, y: 3)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                        )
                    
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .offset(y: -6)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private func tabButton(tab: AppTab, title: String, systemImage: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: selectedTab == tab ? .bold : .regular))
                    .symbolEffect(.bounce, value: selectedTab == tab)
                
                Text(title)
                    .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .regular))
            }
            .foregroundColor(selectedTab == tab ? AppColors.accentCyan : Color.secondary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        AtmosphericBackgroundView()
        VStack {
            Spacer()
            GlassTabBar(selectedTab: .constant(.home), onPlusTap: {})
        }
    }
}
