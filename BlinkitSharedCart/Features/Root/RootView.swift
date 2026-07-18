//
//  RootView.swift
//  BlinkitSharedCart
//
//  App shell: custom floating tab bar, global overlays, and the modal flows
//  (invite friends, shared cart, checkout, order confirmed).
//

import SwiftUI

struct RootView: View {
    @State private var app = AppState()

    var body: some View {
        RootTabView()
            .environment(app)
            .tint(Palette.brand)
    }
}

struct RootTabView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        @Bindable var app = app

        ZStack(alignment: .bottom) {
            Palette.background.ignoresSafeArea()

            // Active tab content
            Group {
                switch app.selectedTab {
                case .home:       HomeView()
                case .categories: CategoriesView()
                case .cart:       CartView()
                case .orders:     OrdersView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Floating Live Activity (host) + tab bar
            VStack(spacing: 10) {
                if app.isInGroup && !app.showSharedCart, let s = app.session, s.status != .placed {
                    LiveActivityPill(session: s, remaining: app.realtime.timeRemaining)
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onTapGesture { app.showSharedCart = true }
                }
                CustomTabBar(selected: $app.selectedTab, cartCount: app.personalItems.count)
            }
            .padding(.bottom, 6)
        }
        .pushBanner(app.banner) {
            app.selectedTab = .orders
            if let b = app.banner { app.markRead(b) }
            app.banner = nil
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: app.banner?.id)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: app.isInGroup)
        // MARK: Modal flows
        .sheet(isPresented: $app.showInviteSheet) {
            InviteFriendsView()
        }
        .fullScreenCover(isPresented: $app.showSharedCart) {
            SharedCartView()
        }
        .sheet(isPresented: $app.showCheckout) {
            CheckoutView()
        }
        .fullScreenCover(isPresented: $app.showOrderConfirmed) {
            OrderConfirmedView()
        }
    }
}

struct CustomTabBar: View {
    @Binding var selected: AppTab
    var cartCount: Int

    var body: some View {
        HStack(spacing: 0) {
            tab(.home, "Home", "house.fill")
            tab(.categories, "Categories", "square.grid.2x2.fill")
            tab(.cart, "Cart", "cart.fill", badge: cartCount)
            tab(.orders, "Orders", "bag.fill")
        }
        .padding(.horizontal, 8).padding(.vertical, 8)
        .background(
            Capsule().fill(.white)
                .softShadow(24, y: 8, opacity: 0.12)
        )
        .overlay(Capsule().stroke(Palette.hairline, lineWidth: 1))
        .padding(.horizontal, 20)
    }

    private func tab(_ t: AppTab, _ title: String, _ icon: String, badge: Int = 0) -> some View {
        let isSel = selected == t
        return Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selected = t }
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSel ? Palette.brandDark : Palette.inkTertiary)
                    if badge > 0 {
                        Text("\(badge)")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(minWidth: 15, minHeight: 15)
                            .background(Circle().fill(Palette.accent))
                            .offset(x: 12, y: -10)
                    }
                }
                Text(title)
                    .font(.system(size: 10, weight: isSel ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isSel ? Palette.brandDark : Palette.inkTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(isSel ? Palette.brandSoft : .clear)
            )
        }
        .buttonStyle(.plain)
    }
}
