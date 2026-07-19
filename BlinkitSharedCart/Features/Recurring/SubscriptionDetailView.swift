//
//  SubscriptionDetailView.swift
//  BlinkitSharedCart
//

import SwiftUI

struct SubscriptionDetailView: View {
    @Environment(AppState.self) private var app
    let id: String

    private var sub: Subscription? {
        _ = app.subsTick
        return app.subscriptions.first { $0.id == id }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            if let sub {
                VStack(spacing: 16) {
                    header(sub)
                    itemsCard(sub)
                    if sub.status == .active { upcomingCard(sub) }
                    if !sub.deliveries.isEmpty { historyCard(sub) }
                    Color.clear.frame(height: 120)
                }
                .padding(16)
            } else {
                Text("Subscription not found").foregroundStyle(Palette.inkSecondary).padding(.top, 80)
            }
        }
        .background(Palette.background)
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if let sub, sub.status == .active || sub.status == .paused { controlBar(sub) }
        }
    }

    private func header(_ sub: Subscription) -> some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(sub.title).font(.system(size: 20, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                    Text(sub.scheduleText).font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                Text(sub.status.label)
                    .font(.system(size: 11, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(.white.opacity(0.22), in: Capsule())
            }
            Divider().overlay(.white.opacity(0.3))
            HStack {
                stat("\(rupees(sub.perDeliveryTotal))", "per delivery")
                Spacer()
                stat("\(sub.deliveredCount)", "delivered")
                Spacer()
                stat(sub.endDate.formatted(.dateTime.day().month()), "ends")
            }
        }
        .padding(16)
        .background(sub.status == .active ? LinearGradient.brand : LinearGradient.group)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 1) {
            Text(value).font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(.white)
            Text(label).font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.85))
        }
    }

    private func itemsCard(_ sub: Subscription) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Items · every delivery").font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.ink)
            ForEach(sub.items) { item in
                HStack(spacing: 10) {
                    ProductImageView(product: item.product, size: 40, showEta: false)
                    Text(item.product.name).font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    Text("×\(item.quantity)").font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.inkSecondary)
                    Text(rupees(item.lineTotal)).font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.ink).frame(width: 54, alignment: .trailing)
                }
            }
        }
        .cardStyle()
    }

    private func upcomingCard(_ sub: Subscription) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Upcoming deliveries").font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.ink)
            ForEach(Array(sub.upcomingRuns(4).enumerated()), id: \.offset) { idx, date in
                HStack(spacing: 10) {
                    Image(systemName: idx == 0 ? "arrow.right.circle.fill" : "circle")
                        .foregroundStyle(idx == 0 ? Palette.brand : Palette.hairline)
                    Text(date.formatted(.dateTime.weekday(.wide).day().month()))
                        .font(.system(size: 13, weight: idx == 0 ? .bold : .medium, design: .rounded))
                        .foregroundStyle(idx == 0 ? Palette.ink : Palette.inkSecondary)
                    Spacer()
                    Text(sub.timeText).font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.inkTertiary)
                }
            }
        }
        .cardStyle()
    }

    private func historyCard(_ sub: Subscription) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("History").font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(Palette.ink)
            ForEach(sub.deliveries) { d in
                HStack(spacing: 10) {
                    Image(systemName: icon(d.status)).foregroundStyle(color(d.status)).frame(width: 20)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(d.status.rawValue.capitalized)
                            .font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink)
                        Text(d.date.formatted(.dateTime.weekday().hour().minute()))
                            .font(.system(size: 11, design: .rounded)).foregroundStyle(Palette.inkTertiary)
                    }
                    Spacer()
                    Text(d.status == .delivered ? "-\(rupees(d.amount))" : rupees(d.amount))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(d.status == .delivered ? Palette.ink : Palette.inkTertiary)
                }
            }
        }
        .cardStyle()
    }

    private func controlBar(_ sub: Subscription) -> some View {
        VStack(spacing: 10) {
            if sub.status == .active {
                HStack(spacing: 10) {
                    GhostButton(title: "Deliver now", icon: "bolt.fill", tint: Palette.brandDark) {
                        app.fireDelivery(sub.id)
                    }
                    GhostButton(title: "Skip next", icon: "forward.fill", tint: Palette.inkSecondary) {
                        app.skipNextDelivery(sub.id)
                    }
                }
                HStack(spacing: 10) {
                    GhostButton(title: "Pause", icon: "pause.fill", tint: Palette.warning) {
                        app.pauseSubscription(sub.id)
                    }
                    GhostButton(title: "Cancel", icon: "xmark", tint: Palette.danger) {
                        app.cancelSubscription(sub.id)
                    }
                }
            } else if sub.status == .paused {
                PrimaryButton(title: "Resume Subscription", icon: "play.fill") {
                    app.resumeSubscription(sub.id)
                }
                GhostButton(title: "Cancel Subscription", icon: "xmark", tint: Palette.danger) {
                    app.cancelSubscription(sub.id)
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(.white)
        .overlay(Rectangle().fill(Palette.hairline).frame(height: 1), alignment: .top)
    }

    private func icon(_ s: SubDelivery.Status) -> String {
        switch s {
        case .delivered: "checkmark.seal.fill"
        case .skipped: "forward.end.fill"
        case .failed: "exclamationmark.triangle.fill"
        case .upcoming: "clock"
        }
    }
    private func color(_ s: SubDelivery.Status) -> Color {
        switch s {
        case .delivered: Palette.success
        case .skipped: Palette.inkTertiary
        case .failed: Palette.danger
        case .upcoming: Palette.brand
        }
    }
}
