//
//  SubscriptionsView.swift
//  BlinkitSharedCart
//

import SwiftUI

struct SubscriptionsView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    // Local sheet so it presents over this sheet (root sheets can't stack).
    @State private var showCreate = false

    var body: some View {
        NavigationStack {
            Group {
                if app.subscriptions.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .background(Palette.background)
            .navigationTitle("Recurring Deliveries")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: String.self) { SubscriptionDetailView(id: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }.foregroundStyle(Palette.inkSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCreate = true } label: {
                        Image(systemName: "plus").font(.system(size: 15, weight: .bold))
                    }.tint(Palette.brandDark)
                }
            }
            .sheet(isPresented: $showCreate) { CreateSubscriptionView() }
        }
    }

    private var list: some View {
        _ = app.subsTick   // refresh anchor for delivery/status changes
        return ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                WalletCard()
                ForEach(app.subscriptions) { sub in
                    NavigationLink(value: sub.id) { SubscriptionCard(sub: sub) }
                        .buttonStyle(.plain)
                }
                Color.clear.frame(height: 40)
            }
            .padding(16)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("🔁").font(.system(size: 64))
            Text("No recurring deliveries yet")
                .font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(Palette.ink)
            Text("Get milk, veggies & essentials delivered\nevery day without lifting a finger.")
                .font(.system(size: 13, design: .rounded)).foregroundStyle(Palette.inkSecondary)
                .multilineTextAlignment(.center)
            Button("Set up recurring delivery") { showCreate = true }
                .font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(.white)
                .padding(.horizontal, 22).frame(height: 46)
                .background(LinearGradient.brand, in: Capsule())
            Spacer(); Spacer()
        }
    }
}

struct SubscriptionCard: View {
    let sub: Subscription

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(sub.title).font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.ink)
                    Text(sub.scheduleText).font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.inkSecondary)
                }
                Spacer()
                Text(sub.status.label)
                    .font(.system(size: 10, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(sub.status.color, in: Capsule())
            }
            HStack(spacing: 6) {
                ForEach(sub.items.prefix(6)) { item in
                    Text(item.product.emoji).font(.system(size: 20))
                }
                if sub.items.count > 6 {
                    Text("+\(sub.items.count - 6)").font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.inkSecondary)
                }
                Spacer()
                Text(rupees(sub.perDeliveryTotal) + "/day")
                    .font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(Palette.ink)
            }
            Divider()
            HStack(spacing: 6) {
                Image(systemName: sub.status == .active ? "clock.fill" : "pause.circle.fill")
                    .font(.system(size: 12)).foregroundStyle(sub.status.color)
                Text(nextText).font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.inkSecondary)
                Spacer()
                Text("Manage →").font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.brandDark)
            }
        }
        .cardStyle(padding: 14)
    }

    private var nextText: String {
        switch sub.status {
        case .active: "Next: \(sub.nextRunDate.formatted(.dateTime.weekday().hour().minute()))"
        case .paused: "Paused · \(sub.deliveredCount) delivered"
        case .ended: "Completed · \(sub.deliveredCount) delivered"
        case .cancelled: "Cancelled"
        }
    }
}

struct WalletCard: View {
    @Environment(AppState.self) private var app
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(LinearGradient.brand)
                Image(systemName: "wallet.bifold.fill").foregroundStyle(.white).font(.system(size: 20))
            }.frame(width: 46, height: 46)
            VStack(alignment: .leading, spacing: 1) {
                Text("Blinkit Money").font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.inkSecondary)
                Text(rupees(app.walletBalance)).font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.ink)
            }
            Spacer()
            Button { app.addMoney(500) } label: {
                Text("+ Add").font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.brandDark)
                    .padding(.horizontal, 14).frame(height: 38)
                    .background(Palette.brandSoft, in: Capsule())
            }.buttonStyle(.plain)
        }
        .cardStyle()
    }
}
