//
//  ReturnsSummaryCard.swift
//  BlinkitSharedCart
//
//  Shows active return requests + their live status (visible to everyone).
//

import SwiftUI

struct ReturnsSummaryCard: View {
    @Environment(AppState.self) private var app

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.uturn.left.circle.fill").foregroundStyle(Palette.warning)
                Text("Returns").font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Text("Visible to all").font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.inkTertiary)
            }
            ForEach(app.returns) { req in
                ReturnStatusRow(request: req)
            }
        }
        .cardStyle()
    }
}

struct ReturnStatusRow: View {
    let request: ReturnRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ProductImageView(product: request.item.product, size: 40, showEta: false)
                VStack(alignment: .leading, spacing: 1) {
                    Text(request.item.product.name)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.ink).lineLimit(1)
                    Text("By \(request.requestedByName) · \(request.reason)")
                        .font(.system(size: 11, design: .rounded)).foregroundStyle(Palette.inkSecondary)
                }
                Spacer()
                Text(request.status.rawValue)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(request.status.color, in: Capsule())
                    .contentTransition(.opacity)
            }
            // Status progress
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.tile)
                    Capsule().fill(request.status.color)
                        .frame(width: geo.size.width * request.status.progress)
                }
            }
            .frame(height: 5)
            HStack {
                Text("Refund \(rupees(request.refundAmount))")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(request.status == .refunded ? Palette.success : Palette.inkSecondary)
                Spacer()
                if request.status == .refunded {
                    Label("Refunded to source", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.success)
                }
            }
        }
        .padding(.vertical, 4)
        .animation(.spring, value: request.status)
    }
}
