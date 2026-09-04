//
//  AppColors.swift
//  DevJournal
//

import SwiftUI

enum AppColors {
    // Base Colors
    static let backgroundDark = Color(red: 0.04, green: 0.04, blue: 0.08)
    static let backgroundLight = Color(red: 0.95, green: 0.95, blue: 0.97)
    
    static let primaryIndigo = Color(red: 0.38, green: 0.35, blue: 0.96)
    static let secondaryPurple = Color(red: 0.62, green: 0.28, blue: 0.98)
    static let accentCyan = Color(red: 0.20, green: 0.78, blue: 0.95)
    static let successGreen = Color(red: 0.20, green: 0.84, blue: 0.52)
    static let warningOrange = Color(red: 1.00, green: 0.62, blue: 0.18)
    
    // Glass Overlay Borders & Highlights
    static let glassBorderLight = Color.white.opacity(0.18)
    static let glassBorderDark = Color.white.opacity(0.08)
    
    static let glassTextPrimary = Color.primary
    static let glassTextSecondary = Color.secondary
}
