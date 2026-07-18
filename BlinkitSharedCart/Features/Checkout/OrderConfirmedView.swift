//
//  OrderConfirmedView.swift
//  BlinkitSharedCart
//

import SwiftUI

struct OrderConfirmedView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var showConfetti = false
    @State private var appear = false

    var body: some View {
        ZStack {
            LinearGradient.celebrate.ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()
                ZStack {
                    Circle().fill(.white.opacity(0.2)).frame(width: 130, height: 130)
                    Circle().fill(.white).frame(width: 96, height: 96)
                    Image(systemName: "checkmark")
                        .font(.system(size: 46, weight: .black))
                        .foregroundStyle(Palette.brand)
                        .scaleEffect(appear ? 1 : 0.3)
                }
                .scaleEffect(appear ? 1 : 0.5)

                VStack(spacing: 8) {
                    Text("Order Confirmed!")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    if let order = app.activeOrder {
                        Text(order.isGroupOrder
                             ? "\(order.placedByName) placed the group order for everyone 🎉"
                             : "Your order is on its way 🎉")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.95))
                            .multilineTextAlignment(.center)
                        Text(order.id)
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12).padding(.vertical, 5)
                            .background(.white.opacity(0.2), in: Capsule())
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 30)

                if let order = app.activeOrder, order.isGroupOrder {
                    HStack(spacing: -8) {
                        ForEach(order.participants) { p in
                            Text(p.avatarEmoji).font(.system(size: 18))
                                .frame(width: 38, height: 38)
                                .background(Circle().fill(.white.opacity(0.25)))
                                .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1))
                        }
                    }
                }

                Spacer()

                VStack(spacing: 10) {
                    Button {
                        Haptics.pop()
                        app.selectedTab = .orders
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                            Text("Track Order")
                        }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.brandDark)
                        .frame(maxWidth: .infinity).frame(height: Metrics.controlHeight)
                        .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button("Back to Home") {
                        app.selectedTab = .home
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }

            ConfettiView(trigger: showConfetti).ignoresSafeArea().allowsHitTesting(false)
        }
        .onAppear {
            Haptics.success()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { appear = true }
            showConfetti = true
        }
    }
}
