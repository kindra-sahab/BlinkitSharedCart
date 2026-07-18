//
//  OrderTrackingView.swift
//  BlinkitSharedCart
//

import SwiftUI

struct OrderTrackingView: View {
    @Environment(AppState.self) private var app
    let orderID: String

    private var order: Order? {
        if app.activeOrder?.id == orderID { return app.activeOrder }
        return app.pastOrders.first { $0.id == orderID }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            if let order {
                VStack(spacing: 16) {
                    etaHero(order)
                    if order.isGroupOrder { participantsCard(order) }
                    stagesCard(order)
                    itemsCard(order)
                    Color.clear.frame(height: 120)
                }
                .padding(16)
            } else {
                Text("Order not found").foregroundStyle(Palette.inkSecondary).padding(.top, 80)
            }
        }
        .background(Palette.background)
        .navigationTitle("Track Order")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func etaHero(_ order: Order) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(.white.opacity(0.2)).frame(width: 88, height: 88)
                Image(systemName: order.stage.icon)
                    .font(.system(size: 36, weight: .bold)).foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
            Text(order.etaText)
                .font(.system(size: 20, weight: .heavy, design: .rounded)).foregroundStyle(.white)
            Text(order.stage.subtitle)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
            if order.stage != .delivered {
                Text("Everyone in this order gets live updates")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(order.stage == .delivered ? LinearGradient.celebrate : LinearGradient.group)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func participantsCard(_ order: Order) -> some View {
        HStack(spacing: 12) {
            AvatarStack(participants: order.participants, size: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text("Group order · \(order.participants.count) people")
                    .font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink)
                Text("Placed by \(order.placedByName)")
                    .font(.system(size: 11, design: .rounded)).foregroundStyle(Palette.inkSecondary)
            }
            Spacer()
        }
        .cardStyle()
    }

    private func stagesCard(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(OrderStage.allCases) { stage in
                StageRow(stage: stage, current: order.stage, isLast: stage == .delivered)
            }
        }
        .cardStyle(padding: 16)
    }

    private func itemsCard(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(order.items.count) items").font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                Spacer()
                if order.stage == .delivered {
                    NavigationLink(value: ReturnRoute.request(orderID)) {
                        Label("Return items", systemImage: "arrow.uturn.left")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.warning)
                    }
                }
            }
            ForEach(order.items) { item in
                HStack(spacing: 10) {
                    ProductImageView(product: item.product, size: 40, showEta: false)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.product.name).font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Palette.ink).lineLimit(1)
                        if order.isGroupOrder {
                            Text("by \(item.addedByID == app.currentUser.id ? "you" : item.addedByName)")
                                .font(.system(size: 11, design: .rounded)).foregroundStyle(Palette.inkTertiary)
                        }
                    }
                    Spacer()
                    Text("×\(item.quantity)").font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.inkSecondary)
                }
            }
        }
        .cardStyle()
        .navigationDestination(for: ReturnRoute.self) { route in
            if case .request(let id) = route { ReturnRequestView(orderID: id) }
        }
    }
}

struct StageRow: View {
    let stage: OrderStage
    let current: OrderStage
    let isLast: Bool

    private var done: Bool { stage.rawValue < current.rawValue }
    private var active: Bool { stage == current }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle().fill(done || active ? Palette.brand : Palette.tile)
                        .frame(width: 30, height: 30)
                    Image(systemName: done ? "checkmark" : stage.icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(done || active ? .white : Palette.inkTertiary)
                    if active {
                        Circle().stroke(Palette.brand.opacity(0.35), lineWidth: 4)
                            .frame(width: 40, height: 40)
                    }
                }
                if !isLast {
                    Rectangle().fill(done ? Palette.brand : Palette.hairline)
                        .frame(width: 2.5, height: 30)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(stage.title)
                    .font(.system(size: 14, weight: active ? .heavy : .semibold, design: .rounded))
                    .foregroundStyle(done || active ? Palette.ink : Palette.inkTertiary)
                Text(stage.subtitle)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(Palette.inkSecondary)
                if active { Text("In progress…").font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.brandDark) }
            }
            .padding(.top, 4)
            Spacer()
        }
    }
}

enum ReturnRoute: Hashable { case request(String) }
