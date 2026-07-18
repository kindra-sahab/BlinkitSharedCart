//
//  Typography.swift
//  BlinkitSharedCart
//
//  Rounded, friendly type scale used across the app.
//

import SwiftUI

extension Font {
    static func app(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static let displayXL = app(30, .heavy)
    static let display    = app(24, .bold)
    static let title      = app(20, .bold)
    static let headline   = app(17, .semibold)
    static let body       = app(15, .regular)
    static let bodyBold   = app(15, .semibold)
    static let callout    = app(14, .medium)
    static let caption    = app(12, .medium)
    static let captionBold = app(12, .bold)
    static let micro      = app(10, .semibold)
}

extension Text {
    func inkStyle() -> Text { foregroundColor(Palette.ink) }
    func secondaryStyle() -> Text { foregroundColor(Palette.inkSecondary) }
}

/// Rupee formatting used everywhere prices appear.
func rupees(_ value: Double) -> String {
    if value == value.rounded() {
        return "₹\(Int(value))"
    }
    return String(format: "₹%.2f", value)
}
