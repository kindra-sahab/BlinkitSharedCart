//
//  Overlays.swift
//  BlinkitSharedCart
//
//  Push-notification banner + shared-cart toast presenters.
//

import SwiftUI

/// Top push-notification banner (simulated iOS push).
struct PushBanner: View {
    let notification: AppNotification
    var onTap: () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(notification.kind.tint.gradient)
                Image(systemName: notification.kind.icon)
                    .foregroundStyle(.white).font(.system(size: 17, weight: .bold))
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                Text(notification.body)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Palette.inkSecondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.5), lineWidth: 1))
        .softShadow(20, y: 10, opacity: 0.18)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

/// Small toast that pops from the shared cart ("Rahul added Bread").
struct GroupToastView: View {
    let toast: GroupToast

    var body: some View {
        HStack(spacing: 8) {
            Text(toast.emoji).font(.system(size: 18))
            Text(toast.text)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(Capsule().fill(Color.black.opacity(0.85)))
        .softShadow(14, y: 6, opacity: 0.25)
    }
}

// MARK: - Transient presenter modifiers

extension View {
    /// Presents a push banner from the top that auto-dismisses via binding.
    func pushBanner(_ notification: AppNotification?, onTap: @escaping () -> Void = {}) -> some View {
        overlay(alignment: .top) {
            if let notification {
                PushBanner(notification: notification, onTap: onTap)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 4)
            }
        }
    }

    func groupToast(_ toast: GroupToast?) -> some View {
        overlay(alignment: .top) {
            if let toast {
                GroupToastView(toast: toast)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
                    .id(toast.id)
            }
        }
    }
}
