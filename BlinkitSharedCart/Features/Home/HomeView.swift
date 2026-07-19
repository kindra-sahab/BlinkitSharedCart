//
//  HomeView.swift
//  BlinkitSharedCart
//

import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                    GroupOrderPromoCard()
                        .padding(.horizontal, 16)
                    BeautyBashBanner()
                        .padding(.horizontal, 16)
                    featuredRail
                    dealGrid
                    Color.clear.frame(height: 120)   // tab bar spacer
                }
            }
            .background(Palette.background)
            .navigationDestination(for: Product.self) { ProductDetailView(product: $0) }
            .navigationDestination(for: Category.self) { ProductListView(category: $0) }
            .toolbar(.hidden, for: .navigationBar)
            .ignoresSafeArea(edges: .top)
        }
    }

    // MARK: Header (pink gradient, location, search, category chips)

    private var header: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill").foregroundStyle(Palette.brandDark)
                        Text("Zipp in").font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.ink)
                    }
                    Text("11 minutes")
                        .font(.system(size: 27, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.ink)
                    HStack(spacing: 4) {
                        Text("Home · Chhatarpur Farms, DLF")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Palette.inkSecondary)
                        Image(systemName: "chevron.down").font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Palette.inkSecondary)
                    }
                }
                Spacer()
                HStack(spacing: 10) {
                    identityButton
                    walletChip
                    NotificationBell()
                }
            }

            NavigationLink(value: SearchRoute.search) { SearchField() }
                .buttonStyle(.plain)

            CategoryChipRow()
        }
        .padding(.horizontal, 16)
        .padding(.top, 64)
        .padding(.bottom, 20)
        .background(
            LinearGradient.home
                .overlay(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 1).fill(.white.opacity(0.001))
                }
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .ignoresSafeArea(edges: .top)
        )
        .navigationDestination(for: SearchRoute.self) { _ in SearchView() }
    }

    /// Lets each phone declare who they are — the guest picks a non-host identity
    /// so the two devices sync as different people during a live group order.
    private var identityButton: some View {
        Menu {
            Text("Who are you on this phone?")
            Button { app.setIdentity(.me) } label: {
                Label("Jatin (host)", systemImage: app.currentUser.id == Participant.me.id ? "checkmark" : "person.crop.circle")
            }
            ForEach(Participant.friendRoster) { p in
                Button { app.setIdentity(p) } label: {
                    Label(p.name, systemImage: app.currentUser.id == p.id ? "checkmark" : "person.crop.circle")
                }
            }
        } label: {
            ZStack {
                Circle().fill(.white)
                Text(app.currentUser.avatarEmoji).font(.system(size: 17))
            }
            .frame(width: 34, height: 34)
            .overlay(Circle().stroke(app.currentUser.color, lineWidth: 1.5))
        }
    }

    private var walletChip: some View {
        HStack(spacing: 5) {
            Image(systemName: "wallet.bifold.fill").font(.system(size: 12))
            Text("₹0").font(.system(size: 13, weight: .bold, design: .rounded))
        }
        .foregroundStyle(Palette.brandDark)
        .padding(.horizontal, 10).frame(height: 34)
        .background(.white, in: Capsule())
    }

    // MARK: Featured

    private var featuredRail: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Bestsellers near you")
                .padding(.horizontal, 16)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MockCatalog.featured) { product in
                        ProductCardCompact(product: product)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var dealGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Grab the deal")
                .padding(.horizontal, 16)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(MockCatalog.products.filter(\.hasDiscount).prefix(6)) { product in
                    ProductCard(
                        product: product,
                        quantity: app.personalQuantity(of: product),
                        onAdd: { app.addToPersonalCart(product) },
                        onIncrement: { app.changePersonalQuantity(product, delta: 1) },
                        onDecrement: { app.changePersonalQuantity(product, delta: -1) },
                        onTap: { app.selectedTab = .home }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// A small home-rail card that navigates to the product on tap.
struct ProductCardCompact: View {
    @Environment(AppState.self) private var app
    let product: Product

    var body: some View {
        NavigationLink(value: product) {
            VStack(alignment: .leading, spacing: 8) {
                ProductImageView(product: product, size: 120)
                Text(product.name)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2).frame(width: 120, height: 32, alignment: .topLeading)
                HStack {
                    Text(rupees(product.price))
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.ink)
                    Spacer()
                }
                AddButton(quantity: app.personalQuantity(of: product), compact: true,
                          onAdd: { app.addToPersonalCart(product) },
                          onIncrement: { app.changePersonalQuantity(product, delta: 1) },
                          onDecrement: { app.changePersonalQuantity(product, delta: -1) })
                    .frame(width: 120)
            }
            .padding(10)
            .frame(width: 140)
            .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

enum SearchRoute: Hashable { case search }
