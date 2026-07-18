//
//  GroupChips.swift
//  BlinkitSharedCart
//
//  Countdown pill, presence bar and the simulated Live Activity / Dynamic Island.
//

import SwiftUI

struct CountdownPill: View {
    let remaining: TimeInterval
    var tint: Color = Palette.accent

    private var text: String {
        let t = max(0, Int(remaining))
        return String(format: "%02d:%02d", t / 60, t % 60)
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "timer").font(.system(size: 11, weight: .bold))
            Text(text)
                .font(.system(size: 13, weight: .heavy, design: .rounded).monospacedDigit())
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(tint.opacity(0.14), in: Capsule())
    }
}

/// A compact live participant/presence strip.
struct PresenceBar: View {
    let participants: [Participant]

    var body: some View {
        HStack(spacing: 8) {
            AvatarStack(participants: participants, size: 30)
            let online = participants.filter { $0.isOnline }.count
            HStack(spacing: 4) {
                Circle().fill(Palette.success).frame(width: 6, height: 6)
                Text("\(online) live")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.inkSecondary)
            }
        }
    }
}

/// Simulated Live Activity / Dynamic Island pill for the host (in-app mock).
struct LiveActivityPill: View {
    let session: GroupSession
    let remaining: TimeInterval

    private var remainingText: String {
        let t = max(0, Int(remaining))
        return String(format: "%02d:%02d", t / 60, t % 60)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(.white.opacity(0.15))
                Image(systemName: "cart.fill").foregroundStyle(.white).font(.system(size: 15, weight: .bold))
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 1) {
                Text("Group order · live")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(session.bill.freeDeliveryUnlocked
                     ? "Free delivery unlocked 🎉"
                     : "\(rupees(session.bill.amountToFreeDelivery)) to free delivery")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }
            Spacer(minLength: 6)

            HStack(spacing: -8) {
                ForEach(session.participants.prefix(3)) { p in
                    Text(p.avatarEmoji)
                        .font(.system(size: 13))
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(.white.opacity(0.2)))
                }
            }
            Text(remainingText)
                .font(.system(size: 13, weight: .heavy, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(
            Capsule().fill(Color.black)
                .overlay(Capsule().stroke(.white.opacity(0.08), lineWidth: 1))
        )
        .softShadow(16, y: 8, opacity: 0.35)
    }
}
