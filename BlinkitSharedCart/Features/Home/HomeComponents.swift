//
//  HomeComponents.swift
//  BlinkitSharedCart
//

import SwiftUI

/// The hero card that pitches the Group Order feature.
struct GroupOrderPromoCard: View {
    @Environment(AppState.self) private var app

    var body: some View {
        Button {
            app.selectedTab = .cart
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill")
                        Text("GROUP ORDER").tracking(1)
                    }
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))

                    Text("Order together,\nsplit the delivery")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Invite roommates & unlock FREE delivery →")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                ZStack {
                    ForEach(Array([Participant.rahul, Participant.priya, Participant.aman].enumerated()), id: \.offset) { idx, p in
                        Text(p.avatarEmoji)
                            .font(.system(size: 26))
                            .frame(width: 46, height: 46)
                            .background(Circle().fill(.white.opacity(0.2)))
                            .overlay(Circle().stroke(.white.opacity(0.4), lineWidth: 1))
                            .offset(x: CGFloat(idx) * -6, y: CGFloat(idx) * -14)
                    }
                }
                .frame(width: 60)
            }
            .padding(16)
            .background(LinearGradient.group, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .softShadow(18, y: 10, opacity: 0.2)
        }
        .buttonStyle(.plain)
    }
}

/// Pitches the Recurring Delivery feature.
struct RecurringPromoCard: View {
    @Environment(AppState.self) private var app

    var body: some View {
        Button { app.showSubscriptions = true } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                        Text("RECURRING DELIVERY").tracking(1)
                    }
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))

                    Text("Never run out of\nmilk again")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(app.activeSubscriptionCount > 0
                         ? "\(app.activeSubscriptionCount) active · manage →"
                         : "Schedule milk, veggies & more daily →")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                ZStack {
                    Circle().fill(.white.opacity(0.18)).frame(width: 62, height: 62)
                    Text("🥛").font(.system(size: 30))
                    Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                        .font(.system(size: 60, weight: .thin)).foregroundStyle(.white.opacity(0.25))
                }
                .frame(width: 62)
            }
            .padding(16)
            .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .softShadow(18, y: 10, opacity: 0.2)
        }
        .buttonStyle(.plain)
    }
}

/// Decorative promo banner (original artwork, not copied branding).
struct BeautyBashBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Text("🧺").font(.system(size: 40))
            VStack(alignment: .leading, spacing: 3) {
                Text("MONSOON ESSENTIALS")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.accent)
                Text("Up to 60% off on daily needs")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                Text("Free gift on orders above ₹499")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.inkSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Palette.inkTertiary)
        }
        .padding(14)
        .background(Palette.accentSoft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

/// Bell with unread badge that opens the notifications inbox.
struct NotificationBell: View {
    @Environment(AppState.self) private var app
    var body: some View {
        NavigationLink(value: NotifRoute.inbox) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.ink)
                    .frame(width: 34, height: 34)
                    .background(.white, in: Circle())
                if app.unreadCount > 0 {
                    Text("\(app.unreadCount)")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(minWidth: 15, minHeight: 15)
                        .background(Circle().fill(Palette.danger))
                        .offset(x: 3, y: -3)
                }
            }
        }
        .buttonStyle(.plain)
        .navigationDestination(for: NotifRoute.self) { _ in NotificationsView() }
    }
}

enum NotifRoute: Hashable { case inbox }

/// Horizontal row of category chips with icons (top of Home / Categories).
struct CategoryChipRow: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                ForEach(MockCatalog.categories.prefix(6)) { cat in
                    NavigationLink(value: cat) {
                        VStack(spacing: 5) {
                            Text(cat.emoji).font(.system(size: 24))
                                .frame(width: 46, height: 46)
                                .background(Color(hex: cat.tint), in: Circle())
                            Text(cat.name.components(separatedBy: " ").first ?? cat.name)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(Palette.ink)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
