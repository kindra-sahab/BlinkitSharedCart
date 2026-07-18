//
//  GroupBrowseView.swift
//  BlinkitSharedCart
//
//  Lightweight in-session catalogue for adding items to the shared cart.
//  Lives inside the SharedCart navigation stack (no nested NavigationStack).
//

import SwiftUI

struct GroupBrowseView: View {
    @Environment(AppState.self) private var app
    @State private var selectedCategory: String = MockCatalog.categories.first!.id

    private var products: [Product] { MockCatalog.products(in: selectedCategory) }

    var body: some View {
        VStack(spacing: 0) {
            // Category selector
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

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(products) { product in
                        ProductCard(
                            product: product,
                            quantity: app.groupQuantity(of: product),
                            onAdd: { app.addToGroup(product) },
                            onIncrement: { app.contextChange(product, delta: 1) },
                            onDecrement: { app.contextChange(product, delta: -1) },
                            onTap: nil
                        )
                    }
                }
                .padding(16)
                Color.clear.frame(height: 40)
            }
        }
        .background(Palette.background)
        .navigationTitle("Add to group cart")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if let s = app.session {
                HStack {
                    Text("\(s.items.count) items in group cart")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(rupees(s.bill.subtotal))
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
}
