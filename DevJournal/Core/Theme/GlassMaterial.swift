//
//  GlassMaterial.swift
//  DevJournal
//

import SwiftUI

enum GlassMaterialStyle {
    case ultraThin
    case thin
    case regular
    case thick
    
    var material: Material {
        switch self {
        case .ultraThin: return .ultraThinMaterial
        case .thin: return .thinMaterial
        case .regular: return .regularMaterial
        case .thick: return .thickMaterial
        }
    }
}

struct AtmosphericBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateGlow = false
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? AppColors.backgroundDark : AppColors.backgroundLight)
                .ignoresSafeArea()
            
            if colorScheme == .dark {
                // Purple ambient light top right
                Circle()
                    .fill(AppColors.secondaryPurple.opacity(0.28))
                    .frame(width: 320, height: 320)
                    .blur(radius: 90)
                    .offset(x: animateGlow ? 140 : 100, y: animateGlow ? -180 : -220)
                
                // Blue/Indigo ambient light bottom left
                Circle()
                    .fill(AppColors.primaryIndigo.opacity(0.25))
                    .frame(width: 360, height: 360)
                    .blur(radius: 100)
                    .offset(x: animateGlow ? -150 : -110, y: animateGlow ? 220 : 180)
                
                // Subtle cyan highlight top left
                Circle()
                    .fill(AppColors.accentCyan.opacity(0.12))
                    .frame(width: 260, height: 260)
                    .blur(radius: 80)
                    .offset(x: -120, y: -100)
            } else {
                // Light mode atmospheric glows
                Circle()
                    .fill(AppColors.primaryIndigo.opacity(0.10))
                    .frame(width: 350, height: 350)
                    .blur(radius: 80)
                    .offset(x: 120, y: -160)
                
                Circle()
                    .fill(AppColors.secondaryPurple.opacity(0.08))
                    .frame(width: 300, height: 300)
                    .blur(radius: 70)
                    .offset(x: -120, y: 200)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 7.0).repeatForever(autoreverses: true)) {
                animateGlow.toggle()
            }
        }
    }
}

#Preview {
    AtmosphericBackgroundView()
}
