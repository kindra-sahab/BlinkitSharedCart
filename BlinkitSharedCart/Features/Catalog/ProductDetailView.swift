//
//  ProductDetailView.swift
//  BlinkitSharedCart
//

import SwiftUI

struct ProductDetailView: View {
    @Environment(AppState.self) private var app
    let product: Product

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(product.tileTint)
                    Text(product.emoji).font(.system(size: 130))
                }
                .frame(height: 300)
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 8) {
                    Label("\(product.etaMinutes) MINS", systemImage: "clock.fill")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.brandDark)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Palette.brandSoft, in: Capsule())

                    Text(product.name)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.ink)
                    Text(product.unit)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.inkSecondary)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(rupees(product.price))
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundStyle(Palette.ink)
                        if product.hasDiscount {
                            Text(rupees(product.mrp))
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(Palette.inkTertiary).strikethrough()
                            Badge(text: "\(product.discountPercent)% OFF", color: Palette.accent)
                        }
                    }
                }
                .padding(.horizontal, 16)

                Divider().padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Highlights").font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.ink)
                    ForEach(highlights, id: \.0) { row in
                        HStack(spacing: 10) {
                            Image(systemName: row.1).foregroundStyle(Palette.brand).frame(width: 22)
                            Text(row.0).font(.system(size: 14, design: .rounded)).foregroundStyle(Palette.inkSecondary)
                        }
                    }
                }
                .padding(.horizontal, 16)

                if app.isInGroup {
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill").foregroundStyle(Palette.violet)
                        Text("This will be added to your group cart")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Palette.violet)
                    }
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.violetSoft, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                }

                Color.clear.frame(height: 100)
            }
        }
        .background(Palette.background)
        .navigationTitle("Product")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { bottomBar }
    }

    private var bottomBar: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                Text(rupees(product.price))
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.ink)
                Text("Inclusive of all taxes")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.inkTertiary)
            }
            Spacer()
            AddButton(quantity: app.contextQuantity(of: product),
                      onAdd: { app.contextAdd(product) },
                      onIncrement: { app.contextChange(product, delta: 1) },
                      onDecrement: { app.contextChange(product, delta: -1) })
                .frame(width: 130)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(.white)
        .overlay(Rectangle().fill(Palette.hairline).frame(height: 1), alignment: .top)
    }

    private var highlights: [(String, String)] {
        [
            ("Delivered in \(product.etaMinutes) minutes", "bolt.fill"),
            ("Freshness guaranteed", "leaf.fill"),
            ("Easy returns on damaged items", "arrow.uturn.left"),
        ]
    }
}
