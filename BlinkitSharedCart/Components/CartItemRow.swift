//
//  CartItemRow.swift
//  BlinkitSharedCart
//

import SwiftUI

struct CartItemRow: View {
    let item: CartItem
    /// The participant who added it (nil in solo carts).
    var addedBy: Participant? = nil
    /// Whether the viewer may edit this line.
    var canEdit: Bool = true
    var showAttribution: Bool = false
    var isMe: Bool = false

    let onIncrement: () -> Void
    let onDecrement: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ProductImageView(product: item.product, size: 56, showEta: false)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.product.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                Text(item.product.unit)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.inkSecondary)
                if showAttribution {
                    AddedByChip(participant: addedBy, name: item.addedByName, isMe: isMe)
                        .padding(.top, 1)
                }
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 6) {
                Text(rupees(item.lineTotal))
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.ink)
                if canEdit {
                    AddButton(quantity: item.quantity, compact: true,
                              onAdd: onIncrement, onIncrement: onIncrement, onDecrement: onDecrement)
                } else {
                    Text("Qty \(item.quantity)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.inkTertiary)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Palette.tile, in: Capsule())
                }
            }
        }
        .padding(10)
        .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.hairline, lineWidth: 1))
    }
}
