//
//  GroupBrowseView.swift
//  BlinkitSharedCart
//
//  Lightweight in-session catalogue for adding items to the shared cart.
//  Lives inside the SharedCart navigation stack (no nested NavigationStack).
//

import SwiftUI

struct GroupBrowseView: View {
    @Bindable var app: AppState
    @State private var selectedCategory: String = MockCatalog.categories.first!.id

    private var products: [Product] { MockCatalog.products(in: selectedCategory) }

    /// My quantity of a product in the live cart.
    private func myQty(_ product: Product, in items: [CartItem]) -> Int {
        var total = 0
        for item in items where item.product.id == product.id && item.addedByID == app.currentUser.id {
            total += item.quantity
        }
        return total
    }

    var body: some View {
        // TimelineView re-reads the live cart every 0.4s, so counters and the
        // total bar stay correct even where @Observable invalidation is unreliable
        // (navigationDestination). Own taps still reflect within 0.4s.
        TimelineView(.periodic(from: .now, by: 0.4)) { _ in
            gridContent
        }
        .background(Palette.background)
        .navigationTitle("Add to group cart")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { app.setGroupBrowsing(true) }
        .onDisappear { app.setGroupBrowsing(false) }
    }

    private var gridContent: some View {
        let liveItems: [CartItem] = app.realtime.session?.items ?? []
        var subtotal = 0.0
        for item in liveItems { subtotal += item.lineTotal }

        return VStack(spacing: 0) {
            categorySelector
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(products) { product in
                        ProductCard(
                            product: product,
                            quantity: myQty(product, in: liveItems),
                            onAdd: { app.addToGroup(product) },
                            onIncrement: { app.groupChangeProduct(product, delta: 1) },
                            onDecrement: { app.groupChangeProduct(product, delta: -1) },
                            onTap: nil
                        )
                    }
                }
                .padding(16)
                Color.clear.frame(height: 40)
            }
        }
        .background(Palette.background)
        .safeAreaInset(edge: .bottom) {
            if !liveItems.isEmpty {
                HStack {
                    Text("\(liveItems.count) items in group cart")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(rupees(subtotal))
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(LinearGradient.group)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(12)
            }
        }
    }

    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(MockCatalog.categories) { cat in
                    let isSel = cat.id == selectedCategory
                    Button {
                        Haptics.tap()
                        withAnimation(.spring) { selectedCategory = cat.id }
                    } label: {
                        HStack(spacing: 5) {
                            Text(cat.emoji)
                            Text(cat.name.components(separatedBy: " ").first ?? cat.name)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(isSel ? .white : Palette.ink)
                        .padding(.horizontal, 12).frame(height: 38)
                        .background(isSel ? AnyShapeStyle(LinearGradient.group) : AnyShapeStyle(Color.white),
                                    in: Capsule())
                        .overlay(Capsule().stroke(Palette.hairline, lineWidth: isSel ? 0 : 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
        }
        .background(.white)
    }
}
