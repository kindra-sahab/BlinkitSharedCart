//
//  SharedUI.swift
//  BlinkitSharedCart
//
//  Small shared building blocks: section headers, search field, chips, badges.
//

import SwiftUI

struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 19, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.ink)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.brandDark)
            }
        }
    }
}

/// Non-interactive search field used as a nav entry to the search screen.
struct SearchField: View {
    var placeholder: String = "Search for milk, bread, eggs…"
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Palette.inkSecondary)
            Text(placeholder)
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(Palette.inkTertiary)
            Spacer()
            Image(systemName: "mic.fill")
                .foregroundStyle(Palette.inkSecondary)
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.hairline, lineWidth: 1))
    }
}

/// A rounded discount / info badge.
struct Badge: View {
    let text: String
    var color: Color = Palette.brand
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(color, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

/// "Added by X" attribution chip for shared-cart items.
struct AddedByChip: View {
    let participant: Participant?
    let name: String
    var isMe: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            if let participant {
                Text(participant.avatarEmoji).font(.system(size: 11))
            }
            Text(isMe ? "Added by you" : "Added by \(name)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(participant?.color ?? Palette.inkSecondary)
        .padding(.horizontal, 7).padding(.vertical, 3)
        .background((participant?.color ?? Palette.inkSecondary).opacity(0.12),
                    in: Capsule())
    }
}

/// A live "browsing" indicator with animated dots.
struct TypingIndicator: View {
    let name: String
    let color: Color
    @State private var phase = 0.0

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 3) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(color)
                        .frame(width: 5, height: 5)
                        .opacity(dotOpacity(i))
                }
            }
            Text("\(name) is browsing…")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.inkSecondary)
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) { phase = 1 }
        }
    }

    private func dotOpacity(_ i: Int) -> Double {
        let t = (phase * 3).truncatingRemainder(dividingBy: 3)
        return abs(t - Double(i)) < 0.5 ? 1 : 0.3
    }
}
