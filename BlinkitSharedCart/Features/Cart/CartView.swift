//
//  CartView.swift
//  BlinkitSharedCart
//

import SwiftUI

struct CartView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        NavigationStack {
            Group {
                if app.personalItems.isEmpty {
                    EmptyCartView()
                } else {
                    filledCart
                }
            }
            .background(Palette.background)
            .safeAreaInset(edge: .top) { NavBarTitle(title: "Your Cart") }
            .navigationDestination(for: NotifRoute.self) { _ in NotificationsView() }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var bill: Bill { app.personalBill }

    private var filledCart: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                // Free delivery progress
                FreeDeliveryProgressBar(bill: bill)
                    .cardStyle()
                    .padding(.horizontal, 16)

                // The Group Order CTA — prominent when the cart is small.
                if !bill.freeDeliveryUnlocked {
                    InviteToJoinCTA(remaining: bill.amountToFreeDelivery)
                        .padding(.horizontal, 16)
                }

                // Items
                VStack(spacing: 10) {
                    ForEach(app.personalItems) { item in
                        CartItemRow(
                            item: item,
                            onIncrement: { app.changePersonalQuantity(item.product, delta: 1) },
                            onDecrement: { app.changePersonalQuantity(item.product, delta: -1) }
                        )
                    }
                }
                .padding(.horizontal, 16)

                BillDetailsCard(bill: bill)
                    .padding(.horizontal, 16)

                Color.clear.frame(height: 150)
            }
            .padding(.top, 8)
        }
        .safeAreaInset(edge: .bottom) { checkoutBar }
    }

    private var checkoutBar: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                Text(rupees(bill.total))
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.ink)
                Text("TOTAL").font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.inkTertiary)
            }
            PrimaryButton(title: "Proceed to Pay", icon: "lock.fill") {
                app.showCheckout = true
            }
            .frame(maxWidth: 210)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(.white)
        .overlay(Rectangle().fill(Palette.hairline).frame(height: 1), alignment: .top)
    }
}

/// The prominent "Invite others to join this order" call to action.
struct InviteToJoinCTA: View {
    @Environment(AppState.self) private var app
    let remaining: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(.white.opacity(0.2))
                    Image(systemName: "person.2.fill").foregroundStyle(.white)
                }.frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cart too small for free delivery?")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Split it! Only \(rupees(remaining)) more unlocks FREE delivery for everyone.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Button {
                app.showInviteSheet = true
            } label: {
                HStack {
                    Text("Invite others to join this order")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .foregroundStyle(Palette.violet)
                .padding(.horizontal, 14).frame(height: 44)
                .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(LinearGradient.group, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .softShadow(18, y: 10, opacity: 0.2)
    }
}

struct BillDetailsCard: View {
    let bill: Bill
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Bill Details").font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                Spacer()
            }
            billRow("Item total", rupees(bill.subtotal))
            billRow("Delivery fee", bill.deliveryFee == 0 ? "FREE" : rupees(bill.deliveryFee),
                    strike: bill.deliveryFee == 0 ? rupees(Pricing.baseDeliveryFee) : nil,
                    highlight: bill.deliveryFee == 0)
            if bill.smallCartFee > 0 {
                billRow("Small cart fee", rupees(bill.smallCartFee), note: "Charged on carts below \(rupees(Pricing.smallCartThreshold))")
            }
            billRow("Handling fee", rupees(bill.handlingFee))
            Divider()
            HStack {
                Text("To Pay").font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Text(rupees(bill.total)).font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.ink)
            }
        }
        .cardStyle()
    }

    private func billRow(_ label: String, _ value: String, strike: String? = nil,
                         highlight: Bool = false, note: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label).font(.system(size: 13, design: .rounded)).foregroundStyle(Palette.inkSecondary)
                Spacer()
                if let strike {
                    Text(strike).font(.system(size: 12, design: .rounded))
                        .foregroundStyle(Palette.inkTertiary).strikethrough()
                }
                Text(value).font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(highlight ? Palette.success : Palette.ink)
            }
            if let note {
                Text(note).font(.system(size: 10, design: .rounded)).foregroundStyle(Palette.inkTertiary)
            }
        }
    }
}

struct EmptyCartView: View {
    @Environment(AppState.self) private var app
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("🛒").font(.system(size: 70))
            Text("Your cart is empty")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.ink)
            Text("Add items worth just ₹30 and invite friends\nto split delivery — magic ✨")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(Palette.inkSecondary)
                .multilineTextAlignment(.center)
            Button("Start shopping") { app.selectedTab = .home }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 24).frame(height: 46)
                .background(LinearGradient.brand, in: Capsule())
            Spacer(); Spacer()
        }
    }
}
