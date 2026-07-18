//
//  AvatarView.swift
//  BlinkitSharedCart
//

import SwiftUI

struct AvatarView: View {
    let participant: Participant
    var size: CGFloat = 36
    var showPresence: Bool = false
    var showBrowsingRing: Bool = false

    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(participant.color.opacity(0.16))
            Text(participant.avatarEmoji)
                .font(.system(size: size * 0.52))
            Circle()
                .stroke(participant.color.opacity(0.9), lineWidth: 2)

            if showBrowsingRing && participant.isBrowsing {
                Circle()
                    .stroke(participant.color, lineWidth: 2.5)
                    .scaleEffect(pulse ? 1.28 : 1.0)
                    .opacity(pulse ? 0 : 0.9)
                    .onAppear { withAnimation(.easeOut(duration: 1).repeatForever(autoreverses: false)) { pulse = true } }
            }
        }
        .frame(width: size, height: size)
        .overlay(alignment: .bottomTrailing) {
            if showPresence {
                Circle()
                    .fill(participant.isOnline ? Palette.success : Palette.inkTertiary)
                    .frame(width: size * 0.28, height: size * 0.28)
                    .overlay(Circle().stroke(.white, lineWidth: 1.5))
            }
        }
    }
}

/// Overlapping avatar stack with an optional "+N" overflow chip.
struct AvatarStack: View {
    let participants: [Participant]
    var size: CGFloat = 32
    var maxVisible: Int = 4

    var body: some View {
        let visible = Array(participants.prefix(maxVisible))
        let overflow = participants.count - visible.count
        HStack(spacing: -size * 0.32) {
            ForEach(visible) { p in
                AvatarView(participant: p, size: size, showPresence: true)
                    .background(Circle().fill(.white))
            }
            if overflow > 0 {
                Text("+\(overflow)")
                    .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.inkSecondary)
                    .frame(width: size, height: size)
                    .background(Circle().fill(Palette.tile))
                    .overlay(Circle().stroke(.white, lineWidth: 2))
            }
        }
    }
}
