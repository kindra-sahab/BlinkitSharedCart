//
//  OrdersView.swift
//  BlinkitSharedCart
//

import SwiftUI

struct OrdersView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        NavigationStack {
            Group {
                if app.activeOrder == nil && app.pastOrders.isEmpty && app.subscriptions.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .background(Palette.background)
            .safeAreaInset(edge: .top) { NavBarTitle(title: "Your Orders") }
            .navigationDestination(for: Order.self) { OrderTrackingView(orderID: $0.id) }
            .navigationDestination(for: NotifRoute.self) { _ in NotificationsView() }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var list: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                SubscriptionsEntryCard()
                if let order = app.activeOrder {
                    NavigationLink(value: order) { OrderCard(order: order, isActive: true) }
                        .buttonStyle(.plain)
                }
                if !app.returns.isEmpty {
                    ReturnsSummaryCard()
                }
                ForEach(app.pastOrders) { order in
                    NavigationLink(value: order) { OrderCard(order: order, isActive: false) }
                        .buttonStyle(.plain)
                }
                Color.clear.frame(height: 120)
            }
            .padding(16)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            SubscriptionsEntryCard().padding(.horizontal, 16).padding(.top, 8)
            Spacer()
            Text("📦").font(.system(size: 64))
            Text("No orders yet")
                .font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(Palette.ink)
            Text("Your live and past orders will show up here.")
                .font(.system(size: 13, design: .rounded)).foregroundStyle(Palette.inkSecondary)
            Spacer(); Spacer()
        }
    }
}

struct SubscriptionsEntryCard: View {
    @Environment(AppState.self) private var app
    var body: some View {
        Button { app.showSubscriptions = true } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(LinearGradient.brand)
                    Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                        .foregroundStyle(.white).font(.system(size: 20, weight: .bold))
                }.frame(width: 46, height: 46)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recurring deliveries")
                        .font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(Palette.ink)
                    Text(app.activeSubscriptionCount > 0
                         ? "\(app.activeSubscriptionCount) active · auto-paid from Blinkit Money"
                         : "Schedule daily essentials — set up in seconds")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.inkSecondary).lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Palette.inkTertiary)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

struct OrderCard: View {
    let order: Order
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(Palette.brandSoft)
                    Image(systemName: order.stage.icon).foregroundStyle(Palette.brandDark)
                }.frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(order.id).font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(Palette.ink)
                        if order.isGroupOrder {
                            Label("Group", systemImage: "person.2.fill")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .foregroundStyle(Palette.violet)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Palette.violetSoft, in: Capsule())
                        }
                    }
                    Text(isActive ? order.etaText : "Delivered")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(isActive ? Palette.brandDark : Palette.inkSecondary)
                }
                Spacer()
                Text(rupees(order.bill.total)).font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.ink)
            }

            if isActive {
                MiniStageBar(stage: order.stage)
            }

            HStack(spacing: 8) {
                ForEach(order.items.prefix(6)) { item in
                    Text(item.product.emoji).font(.system(size: 18))
                }
                if order.items.count > 6 {
                    Text("+\(order.items.count - 6)").font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.inkSecondary)
                }
                Spacer()
                Text(isActive ? "Track →" : "View / Return →")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.brandDark)
            }
        }
        .cardStyle(padding: 14)
    }
}

struct MiniStageBar: View {
    let stage: OrderStage
    var body: some View {
        HStack(spacing: 4) {
            ForEach(OrderStage.allCases) { s in
                Capsule()
                    .fill(s.rawValue <= stage.rawValue ? Palette.brand : Palette.hairline)
                    .frame(height: 5)
            }
        }
    }
}
