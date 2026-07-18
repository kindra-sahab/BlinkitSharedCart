//
//  ProductListView.swift
//  BlinkitSharedCart
//

import SwiftUI

struct ProductListView: View {
    @Environment(AppState.self) private var app
    let category: Category

    private var products: [Product] { MockCatalog.products(in: category.id) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(products) { product in
                    ProductCard(
                        product: product,
                        quantity: app.contextQuantity(of: product),
                        onAdd: { app.contextAdd(product) },
                        onIncrement: { app.contextChange(product, delta: 1) },
                        onDecrement: { app.contextChange(product, delta: -1) },
                        onTap: { route(product) }
                    )
                }
            }
            .padding(16)
            Color.clear.frame(height: 120)
        }
        .background(Palette.background)
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Product.self) { ProductDetailView(product: $0) }
        .navigationDestination(item: $pushed) { ProductDetailView(product: $0) }
        .safeAreaInset(edge: .bottom) {
            if app.isInGroup { GroupContextBar() }
        }
    }

    // Programmatic push needs the destination in scope; use a hidden link container.
    @State private var pushed: Product?
    private func route(_ p: Product) { pushed = p }
}

/// A slim bar reminding the user they're shopping into a live group cart.
struct GroupContextBar: View {
    @Environment(AppState.self) private var app
    var body: some View {
        if let s = app.session {
            Button { app.showSharedCart = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "person.2.fill").foregroundStyle(.white)
                    Text("Adding to group cart")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(s.items.count) items · \(rupees(s.bill.subtotal))")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.9)).font(.caption)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(LinearGradient.group)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 12)
            }
            .buttonStyle(.plain)
        }
    }
}
