//
//  AppTheme.swift
//  BlinkitSharedCart
//
//  Central design system: colors, gradients, spacing, radii, shadows.
//  Inspired by quick-commerce grocery apps — original palette, no copied branding.
//

import SwiftUI

// MARK: - Color from hex

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Palette

enum Palette {
    // Brand — fresh grocery green
    static let brand = Color(hex: 0x0FA958)
    static let brandDark = Color(hex: 0x0B7E42)
    static let brandSoft = Color(hex: 0xE4F7EC)

    // Energy accent — warm amber (deals, timers, highlights)
    static let accent = Color(hex: 0xFF9F1C)
    static let accentSoft = Color(hex: 0xFFF1DC)

    // Playful secondary — used in group order / social moments
    static let violet = Color(hex: 0x7C5CFC)
    static let violetSoft = Color(hex: 0xEFEBFF)
    static let pink = Color(hex: 0xFF5C8A)

    // Ink / text
    static let ink = Color(hex: 0x141A1F)
    static let inkSecondary = Color(hex: 0x6A7480)
    static let inkTertiary = Color(hex: 0x9AA4AF)

    // Surfaces
    static let background = Color(hex: 0xF6F8F7)
    static let surface = Color.white
    static let tile = Color(hex: 0xEAF2F1)          // category tile bg (light blue-gray)
    static let hairline = Color(hex: 0xE7EBEA)

    // Status
    static let success = Color(hex: 0x0FA958)
    static let warning = Color(hex: 0xE8A100)
    static let danger = Color(hex: 0xE5484D)

    // Home gradient (peach -> pink, like the reference home screen)
    static let homeTop = Color(hex: 0xFFE7D6)
    static let homeBottom = Color(hex: 0xFFDDE8)

    // Avatar palette (assigned per participant)
    static let avatarColors: [Color] = [
        Color(hex: 0x0FA958), Color(hex: 0x7C5CFC), Color(hex: 0xFF7A45),
        Color(hex: 0x2D9CDB), Color(hex: 0xF2596F), Color(hex: 0xE8A100),
        Color(hex: 0x16B8A6), Color(hex: 0xB15CFC)
    ]
}

// MARK: - Gradients

extension LinearGradient {
    static let home = LinearGradient(
        colors: [Palette.homeTop, Palette.homeBottom],
        startPoint: .top, endPoint: .bottom
    )
    static let brand = LinearGradient(
        colors: [Palette.brand, Palette.brandDark],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let group = LinearGradient(
        colors: [Palette.violet, Color(hex: 0x5B7CFC)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let celebrate = LinearGradient(
        colors: [Palette.brand, Color(hex: 0x16B8A6)],
        startPoint: .leading, endPoint: .trailing
    )
}

// MARK: - Layout tokens

enum Metrics {
    static let screenPadding: CGFloat = 16
    static let cardRadius: CGFloat = 18
    static let tileRadius: CGFloat = 16
    static let pillRadius: CGFloat = 999
    static let controlHeight: CGFloat = 52
}

// MARK: - Shadows

extension View {
    func softShadow(_ radius: CGFloat = 16, y: CGFloat = 8, opacity: Double = 0.08) -> some View {
        shadow(color: Color.black.opacity(opacity), radius: radius, x: 0, y: y)
    }

    /// Standard rounded card container.
    func cardStyle(radius: CGFloat = Metrics.cardRadius, padding: CGFloat = 14) -> some View {
        self
            .padding(padding)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .softShadow()
    }
}
