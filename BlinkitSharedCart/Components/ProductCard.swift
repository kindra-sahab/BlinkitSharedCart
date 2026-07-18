//
//  ProductCard.swift
//  BlinkitSharedCart
//
//  Grid product card with image, discount badge, price and ADD control.
//

import SwiftUI

struct ProductCard: View {
    let product: Product
    let quantity: Int
    let onAdd: () -> Void
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    var onTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                ProductImageView(product: product, size: 118)
                    .frame(maxWidth: .infinity)
                if product.hasDiscount {
                    Badge(text: "\(product.discountPercent)% OFF", color: Palette.accent)
                        .padding(6)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { onTap?() }

            Text(product.name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Palette.ink)
                .lineLimit(2)
                .frame(height: 34, alignment: .top)

            Text(product.unit)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.inkSecondary)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(rupees(product.price))
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.ink)
                    if product.hasDiscount {
                        Text(rupees(product.mrp))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Palette.inkTertiary)
                            .strikethrough()
                    }
                }
                Spacer(minLength: 4)
                AddButton(quantity: quantity, compact: true,
                          onAdd: onAdd, onIncrement: onIncrement, onDecrement: onDecrement)
            }
        }
        .padding(10)
        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.hairline, lineWidth: 1))
    }
}
