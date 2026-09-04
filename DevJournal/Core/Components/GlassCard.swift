//
//  GlassCard.swift
//  DevJournal
//

import SwiftUI

struct GlassCard<Content: View>: View {
    let style: GlassMaterialStyle
    let cornerRadius: CGFloat
    let strokeColor: Color?
    let padding: CGFloat
    let content: Content

    init(
        style: GlassMaterialStyle = .ultraThin,
        cornerRadius: CGFloat = 24,
        strokeColor: Color? = nil,
        padding: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.cornerRadius = cornerRadius
        self.strokeColor = strokeColor
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(style.material)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        strokeColor ?? Color.white.opacity(0.12),
                        lineWidth: 1
                    )
            }
            .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
    }
}

struct GlassButton<Content: View>: View {
    let action: () -> Void
    let style: GlassMaterialStyle
    let cornerRadius: CGFloat
    let content: Content
    
    @State private var isPressed = false
    
    init(
        style: GlassMaterialStyle = .thin,
        cornerRadius: CGFloat = 16,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.cornerRadius = cornerRadius
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: action) {
            content
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(style.material)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        AtmosphericBackgroundView()
        VStack(spacing: 20) {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Glass Card Header")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("This is a visionOS inspired glass card container.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            GlassButton(action: {}) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Interactive Glass Button")
                }
                .font(.headline)
                .foregroundColor(.white)
            }
        }
        .padding()
    }
}
