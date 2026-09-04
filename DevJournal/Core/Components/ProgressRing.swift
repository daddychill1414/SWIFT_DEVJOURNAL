//
//  ProgressRing.swift
//  DevJournal
//

import SwiftUI

struct ProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let ringWidth: CGFloat
    let primaryColor: Color
    let secondaryColor: Color
    
    @State private var animatedProgress: Double = 0
    
    init(
        progress: Double,
        ringWidth: CGFloat = 12,
        primaryColor: Color = AppColors.primaryIndigo,
        secondaryColor: Color = AppColors.accentCyan
    ) {
        self.progress = progress
        self.ringWidth = ringWidth
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
    }
    
    var body: some View {
        ZStack {
            // Background ring track
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: ringWidth)
            
            // Progress gradient fill
            Circle()
                .trim(from: 0, to: CGFloat(min(animatedProgress, 1.0)))
                .stroke(
                    LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            // Inner text content
            VStack(spacing: 2) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("Complete")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                animatedProgress = newValue
            }
        }
    }
}

#Preview {
    ZStack {
        AtmosphericBackgroundView()
        ProgressRing(progress: 0.75)
            .frame(width: 140, height: 140)
    }
}
