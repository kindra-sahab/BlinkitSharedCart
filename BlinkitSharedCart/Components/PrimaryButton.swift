//
//  PrimaryButton.swift
//  BlinkitSharedCart
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var gradient: LinearGradient = .brand
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.pop()
            action()
        } label: {
            HStack(spacing: 10) {
                if let icon { Image(systemName: icon).font(.headline) }
                VStack(spacing: 1) {
                    Text(title).font(.system(size: 16, weight: .bold, design: .rounded))
                    if let subtitle {
                        Text(subtitle).font(.system(size: 11, weight: .medium, design: .rounded)).opacity(0.9)
                    }
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: Metrics.controlHeight)
            .background(gradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(enabled ? 1 : 0.5)
            .softShadow(12, y: 6, opacity: 0.18)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

/// A tappable secondary/ghost button.
struct GhostButton: View {
    let title: String
    var icon: String? = nil
    var tint: Color = Palette.brandDark
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap(); action()
        } label: {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon) }
                Text(title)
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
