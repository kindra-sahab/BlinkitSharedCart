//
//  NotificationsView.swift
//  BlinkitSharedCart
//

import SwiftUI

struct NotificationsView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                ForEach(app.notifications) { n in
                    if n.kind == .groupInvite && n.inviteSessionID != nil {
                        IncomingInviteCard(notification: n)
                    } else {
                        NotificationRow(notification: n)
                    }
                }
                Color.clear.frame(height: 100)
            }
            .padding(16)
        }
        .background(Palette.background)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Mark all read") { app.markAllRead() }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.brandDark)
            }
        }
        .onAppear { app.markAllRead() }
    }
}

/// The incoming group-invite push with Join / Ignore actions.
struct IncomingInviteCard: View {
    @Environment(AppState.self) private var app
    let notification: AppNotification
    @State private var ignored = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(LinearGradient.group)
                    Text(Participant.rahul.avatarEmoji).font(.system(size: 22))
                }.frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text(notification.title)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.ink)
                    Text("Tap Join to add items to Rahul's shared cart")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(Palette.inkSecondary)
                }
                Spacer(minLength: 0)
            }

            Text(notification.body)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.ink)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.violetSoft, in: RoundedRectangle(cornerRadius: 12))

            if ignored {
                Text("Ignored")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.inkTertiary)
                    .frame(maxWidth: .infinity).frame(height: 44)
                    .background(Palette.tile, in: RoundedRectangle(cornerRadius: 12))
            } else {
                HStack(spacing: 10) {
                    Button {
                        withAnimation { ignored = true }
                        app.markRead(notification)
                    } label: {
                        Text("Ignore")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.inkSecondary)
                            .frame(maxWidth: .infinity).frame(height: 46)
                            .background(Palette.tile, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    Button {
                        app.acceptInvite(notification)
                    } label: {
                        Text("Join Order")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 46)
                            .background(LinearGradient.group, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Palette.violet.opacity(0.3), lineWidth: 1.5))
        .softShadow(16, y: 8, opacity: 0.1)
    }
}

struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(notification.kind.tint.opacity(0.15))
                Image(systemName: notification.kind.icon)
                    .foregroundStyle(notification.kind.tint).font(.system(size: 18, weight: .bold))
            }.frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink).lineLimit(1)
                Text(notification.body)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Palette.inkSecondary).lineLimit(2)
                Text(notification.date, style: .relative)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.inkTertiary)
            }
            Spacer(minLength: 0)
            if !notification.isRead {
                Circle().fill(Palette.brand).frame(width: 8, height: 8)
            }
        }
        .padding(12)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.hairline, lineWidth: 1))
    }
}
