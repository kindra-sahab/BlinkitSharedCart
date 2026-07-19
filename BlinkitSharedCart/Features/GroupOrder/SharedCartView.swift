//
//  SharedCartView.swift
//  BlinkitSharedCart
//
//  The live, multiplayer shared cart — presence, countdown, activity feed,
//  free-delivery progress, per-person attribution, and host checkout.
//

import SwiftUI

struct SharedCartView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    // Checkout must be presented from INSIDE this cover, otherwise a root-level
    // sheet opens hidden behind the full-screen cover.
    @State private var showGroupCheckout = false

    var body: some View {
        NavigationStack {
            Group {
                if let session = app.realtime.session {
                    content(session)
                } else {
                    ProgressView()
                }
            }
            .background(Palette.background)
            .navigationDestination(for: Product.self) { ProductDetailView(product: $0) }
            .navigationDestination(for: GroupBrowseRoute.self) { _ in GroupBrowseView(app: app) }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showGroupCheckout) { CheckoutView() }
        }
    }

    @ViewBuilder
    private func content(_ session: GroupSession) -> some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    header(session)
                    liveStrip(session)
                    FreeDeliveryProgressBar(bill: session.bill)
                        .cardStyle()
                        .padding(.horizontal, 16)
                    ActivityFeedCard(activities: app.realtime.activities)
                        .padding(.horizontal, 16)
                    itemsSection(session)
                    addMoreButton
                    Color.clear.frame(height: 160)
                }
                .padding(.top, 8)
            }
            .safeAreaInset(edge: .bottom) { checkoutBar(session) }

            // Celebration confetti
            ConfettiView(trigger: app.realtime.celebrate)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .groupToast(app.realtime.toast)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: app.realtime.toast?.id)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: session.items)
    }

    // MARK: Header

    private func header(_ session: GroupSession) -> some View {
        VStack(spacing: 14) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 34, height: 34).background(.white.opacity(0.2), in: Circle())
                }
                Spacer()
                VStack(spacing: 1) {
                    Text("Group Order").font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Code \(session.inviteCode)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                CountdownPill(remaining: app.realtime.timeRemaining, tint: .white)
                    .background(.white.opacity(0.15), in: Capsule())
            }

            HStack {
                PresenceBar(participants: session.participants)
                Spacer()
                if app.isHost {
                    Label("You're host", systemImage: "crown.fill")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(.white.opacity(0.2), in: Capsule())
                }
            }
            MPDebugChip()
        }
        .padding(16).padding(.top, 44)
        .background(LinearGradient.group)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .ignoresSafeArea(edges: .top)
    }

    // MARK: Live browsing strip

    @ViewBuilder
    private func liveStrip(_ session: GroupSession) -> some View {
        let browsing = session.participants.filter { $0.isBrowsing }
        if !browsing.isEmpty {
            HStack {
                ForEach(browsing) { p in
                    TypingIndicator(name: p.firstName, color: p.color)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .transition(.opacity)
        }
    }

    // MARK: Items grouped by participant

    private func itemsSection(_ session: GroupSession) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(session.participants) { p in
                let items = session.items(addedBy: p.id)
                if !items.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            AvatarView(participant: p, size: 26, showBrowsingRing: true)
                            Text(p.id == app.currentUser.id ? "Your items" : "\(p.firstName)'s items")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .foregroundStyle(Palette.ink)
                            if p.isHost {
                                Image(systemName: "crown.fill").font(.system(size: 10))
                                    .foregroundStyle(Palette.accent)
                            }
                            Spacer()
                            Text(rupees(items.reduce(0) { $0 + $1.lineTotal }))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(Palette.inkSecondary)
                        }
                        ForEach(items) { item in
                            let editable = app.realtime.canEdit(item, as: app.currentUser)
                            CartItemRow(
                                item: item,
                                addedBy: p,
                                canEdit: editable,
                                showAttribution: false,
                                isMe: p.id == app.currentUser.id,
                                onIncrement: { app.groupChangeQuantity(itemID: item.id, delta: 1) },
                                onDecrement: { app.groupChangeQuantity(itemID: item.id, delta: -1) }
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var addMoreButton: some View {
        NavigationLink(value: GroupBrowseRoute.browse) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text("Add more items")
            }
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(Palette.brandDark)
            .frame(maxWidth: .infinity).frame(height: 50)
            .background(Palette.brandSoft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.brand.opacity(0.4), lineWidth: 1.5))
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }

    // MARK: Checkout bar (host vs guest vs expired)

    @ViewBuilder
    private func checkoutBar(_ session: GroupSession) -> some View {
        VStack(spacing: 10) {
            if session.status == .expired {
                Label("This group order expired", systemImage: "clock.badge.xmark")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.danger)
            } else if app.isHost {
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(rupees(session.bill.total))
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundStyle(Palette.ink)
                        Text("\(session.items.count) items · \(session.onlineCount) live")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.inkTertiary)
                    }
                    Spacer()
                    PrimaryButton(title: "Place Group Order", icon: "lock.fill",
                                  enabled: !session.items.isEmpty) {
                        showGroupCheckout = true
                    }
                    .frame(maxWidth: 220)
                }
            } else {
                WaitingForHostBar(hostName: session.host?.name ?? "Host",
                                  myTotal: session.items(addedBy: app.currentUser.id).reduce(0) { $0 + $1.lineTotal })
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(.white)
        .overlay(Rectangle().fill(Palette.hairline).frame(height: 1), alignment: .top)
    }
}

struct WaitingForHostBar: View {
    let hostName: String
    let myTotal: Double
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 12) {
            ProgressView().tint(Palette.violet)
            VStack(alignment: .leading, spacing: 2) {
                Text("Waiting for \(hostName) to place order…")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                Text("Your share: \(rupees(myTotal)) · You'll be notified when it's placed")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Palette.violetSoft, in: RoundedRectangle(cornerRadius: 14))
    }
}

/// Live activity feed card ("Rahul added Bread", joins, unlocks).
struct ActivityFeedCard: View {
    let activities: [GroupActivity]

    var body: some View {
        let recent = Array(activities.suffix(4).reversed())
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle().fill(Palette.success).frame(width: 7, height: 7)
                Text("Live activity")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.ink)
                Spacer()
            }
            ForEach(recent) { a in
                HStack(spacing: 8) {
                    Circle().fill(Color(hex: a.colorHex)).frame(width: 6, height: 6)
                    (Text(a.participantName).font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: a.colorHex))
                     + Text(" \(a.text)").font(.system(size: 12, design: .rounded))
                        .foregroundColor(Palette.inkSecondary))
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .cardStyle()
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: activities.count)
    }
}

enum GroupBrowseRoute: Hashable { case browse }
