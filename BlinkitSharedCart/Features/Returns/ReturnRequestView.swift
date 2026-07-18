//
//  ReturnRequestView.swift
//  BlinkitSharedCart
//

import SwiftUI

struct ReturnRequestView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    let orderID: String

    @State private var selectedItem: String?
    @State private var reason: ReturnReason = .damaged

    private var order: Order? {
        if app.activeOrder?.id == orderID { return app.activeOrder }
        return app.pastOrders.first { $0.id == orderID }
    }

    /// Items the current user is allowed to return.
    private var returnableItems: [CartItem] {
        guard let order else { return [] }
        return order.items.filter { app.canReturn($0) }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                policyBanner
                Text("Select item to return")
                    .font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(Palette.ink)
                    .padding(.horizontal, 16)

                VStack(spacing: 10) {
                    ForEach(returnableItems) { item in
                        ReturnItemRow(item: item,
                                      isGroup: order?.isGroupOrder ?? false,
                                      isMine: item.addedByID == app.currentUser.id,
                                      isSelected: selectedItem == item.id) {
                            selectedItem = item.id
                        }
                    }
                }
                .padding(.horizontal, 16)

                if let order, order.isGroupOrder {
                    lockedNote(order)
                }

                Text("Reason")
                    .font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(Palette.ink)
                    .padding(.horizontal, 16)
                VStack(spacing: 8) {
                    ForEach(ReturnReason.allCases) { r in
                        Button { reason = r } label: {
                            HStack {
                                Text(r.rawValue).font(.system(size: 14, design: .rounded)).foregroundStyle(Palette.ink)
                                Spacer()
                                Image(systemName: reason == r ? "largecircle.fill.circle" : "circle")
                                    .foregroundStyle(reason == r ? Palette.brand : Palette.hairline)
                            }
                            .padding(.vertical, 10).padding(.horizontal, 14)
                            .background(.white, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.hairline, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                Color.clear.frame(height: 120)
            }
            .padding(.top, 8)
        }
        .background(Palette.background)
        .navigationTitle("Request Return")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { submitBar }
    }

    private var policyBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill").foregroundStyle(Palette.violet)
            Text("You can return only the items you added. Everyone sees the return status.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.inkSecondary)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.violetSoft, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }

    private func lockedNote(_ order: Order) -> some View {
        let locked = order.items.filter { !app.canReturn($0) }
        return Group {
            if !locked.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill").foregroundStyle(Palette.inkTertiary)
                    Text("\(locked.count) item\(locked.count == 1 ? "" : "s") added by others can only be returned by them\(app.currentUser.isHost ? " (or you, as host)" : "").")
                        .font(.system(size: 11, design: .rounded)).foregroundStyle(Palette.inkTertiary)
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var submitBar: some View {
        PrimaryButton(title: "Submit Return Request", icon: "arrow.uturn.left",
                      gradient: .brand, enabled: selectedItem != nil) {
            if let id = selectedItem, let item = returnableItems.first(where: { $0.id == id }) {
                app.requestReturn(for: item, reason: reason)
                dismiss()
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(.white)
        .overlay(Rectangle().fill(Palette.hairline).frame(height: 1), alignment: .top)
    }
}

struct ReturnItemRow: View {
    let item: CartItem
    let isGroup: Bool
    let isMine: Bool
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ProductImageView(product: item.product, size: 48, showEta: false)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.product.name).font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.ink).lineLimit(1)
                    Text("Qty \(item.quantity) · refund \(rupees(item.lineTotal))")
                        .font(.system(size: 12, design: .rounded)).foregroundStyle(Palette.inkSecondary)
                    if isGroup {
                        Text(isMine ? "Added by you" : "Added by \(item.addedByName)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(isMine ? Palette.brandDark : Palette.inkTertiary)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Palette.brand : Palette.hairline)
                    .font(.system(size: 22))
            }
            .padding(12)
            .background(.white, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Palette.brand : Palette.hairline, lineWidth: isSelected ? 2 : 1))
        }
        .buttonStyle(.plain)
    }
}
