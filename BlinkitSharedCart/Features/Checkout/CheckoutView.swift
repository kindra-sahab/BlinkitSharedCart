//
//  CheckoutView.swift
//  BlinkitSharedCart
//

import SwiftUI

struct CheckoutView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var payMethod = "UPI"

    private var isGroup: Bool { app.isInGroup }
    private var bill: Bill { app.realtime.session?.bill ?? app.personalBill }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    deliveryCard
                    if isGroup, let s = app.realtime.session { groupSummary(s) }
                    BillDetailsCard(bill: bill).padding(.horizontal, 16)
                    paymentCard
                    Color.clear.frame(height: 120)
                }
                .padding(.top, 8)
            }
            .background(Palette.background)
            .navigationTitle(isGroup ? "Place Group Order" : "Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }.foregroundStyle(Palette.inkSecondary)
                }
            }
            .safeAreaInset(edge: .bottom) { payBar }
        }
    }

    private var deliveryCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "location.fill").foregroundStyle(Palette.brandDark)
                .frame(width: 40, height: 40).background(Palette.brandSoft, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("Delivery in \(bill.freeDeliveryUnlocked ? 11 : 13) minutes")
                    .font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink)
                Text("Home · Chhatarpur Farms, DLF Farms")
                    .font(.system(size: 12, design: .rounded)).foregroundStyle(Palette.inkSecondary)
            }
            Spacer()
        }
        .cardStyle().padding(.horizontal, 16)
    }

    private func groupSummary(_ s: GroupSession) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Group contributions")
                    .font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink)
                Spacer()
                AvatarStack(participants: s.participants, size: 26)
            }
            ForEach(s.participants) { p in
                let total = s.items(addedBy: p.id).reduce(0) { $0 + $1.lineTotal }
                if total > 0 {
                    HStack(spacing: 8) {
                        Text(p.avatarEmoji)
                        Text(p.id == app.currentUser.id ? "You" : p.name)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Palette.ink)
                        if p.isHost {
                            Image(systemName: "crown.fill").font(.system(size: 9)).foregroundStyle(Palette.accent)
                        }
                        Spacer()
                        Text(rupees(total)).font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.inkSecondary)
                    }
                }
            }
            Divider()
            Text("As host, you pay the full bill now. Settle up with friends however you like 😉")
                .font(.system(size: 11, design: .rounded)).foregroundStyle(Palette.inkTertiary)
        }
        .cardStyle().padding(.horizontal, 16)
    }

    private var paymentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Payment method")
                .font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink)
            ForEach(["UPI", "Credit / Debit Card", "Cash on Delivery"], id: \.self) { method in
                Button { payMethod = method } label: {
                    HStack(spacing: 10) {
                        Image(systemName: icon(method)).foregroundStyle(Palette.brandDark).frame(width: 24)
                        Text(method).font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(Palette.ink)
                        Spacer()
                        Image(systemName: payMethod == method ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(payMethod == method ? Palette.brand : Palette.hairline)
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
        .cardStyle().padding(.horizontal, 16)
    }

    private func icon(_ method: String) -> String {
        switch method {
        case "UPI": "indianrupeesign.circle.fill"
        case "Credit / Debit Card": "creditcard.fill"
        default: "banknote.fill"
        }
    }

    private var payBar: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                Text(rupees(bill.total)).font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.ink)
                Text("via \(payMethod)").font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.inkTertiary)
            }
            Spacer()
            PrimaryButton(title: isGroup ? "Place Group Order" : "Pay \(rupees(bill.total))",
                          icon: "checkmark.seal.fill",
                          gradient: isGroup ? .group : .brand) {
                if isGroup { app.placeGroupOrder() } else { app.placeSoloOrder() }
                app.selectedTab = .orders
            }
            .frame(maxWidth: 220)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(.white)
        .overlay(Rectangle().fill(Palette.hairline).frame(height: 1), alignment: .top)
    }
}
