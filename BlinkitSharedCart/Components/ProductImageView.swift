//
//  ProductImageView.swift
//  BlinkitSharedCart
//
//  Emoji-on-pastel product imagery — self-contained, no external assets.
//

import SwiftUI

struct ProductImageView: View {
    let product: Product
    var size: CGFloat = 72
    var showEta: Bool = true

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: Metrics.tileRadius, style: .continuous)
                .fill(product.tileTint)
            Text(product.emoji)
                .font(.system(size: size * 0.5))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if showEta {
                Label("\(product.etaMinutes) min", systemImage: "clock")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.inkSecondary)
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(.white.opacity(0.9), in: Capsule())
                    .padding(6)
            }
        }
        .frame(width: size, height: size)
    }
}
