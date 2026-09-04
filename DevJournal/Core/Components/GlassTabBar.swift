//
//  GlassTabBar.swift
//  DevJournal
//

import SwiftUI

struct GlassTabBar: View {
    @Binding var selectedTab: AppTab
    let onPlusTap: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            tabButton(tab: .home, title: "Home", systemImage: "house.fill")
            tabButton(tab: .projects, title: "Projects", systemImage: "folder.fill")
            
            // Center Elevated Plus Button
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
                        .frame(width: 52, height: 52)
                        .shadow(color: AppColors.primaryIndigo.opacity(0.5), radius: 10, x: 0, y: 4)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        )
                    
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -14)
            .padding(.horizontal, 8)
            
            tabButton(tab: .journal, title: "Journal", systemImage: "book.closed.fill")
            tabButton(tab: .insights, title: "Insights", systemImage: "chart.xyaxis.line")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 10)
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
