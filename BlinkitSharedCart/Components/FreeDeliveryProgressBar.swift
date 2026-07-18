//
//  FreeDeliveryProgressBar.swift
//  BlinkitSharedCart
//
//  Animated progress toward the free-delivery threshold.
//

import SwiftUI

struct FreeDeliveryProgressBar: View {
    let bill: Bill
    var compact: Bool = false

    private var unlocked: Bool { bill.freeDeliveryUnlocked }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 8) {
            HStack(spacing: 6) {
                Image(systemName: unlocked ? "checkmark.seal.fill" : "truck.box.fill")
                    .foregroundStyle(unlocked ? Palette.success : Palette.accent)
                    .font(.system(size: 14, weight: .bold))
                Text(headline)
                    .font(.system(size: compact ? 12 : 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                    .contentTransition(.opacity)
                Spacer()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.tile)
                    Capsule()
                        .fill(unlocked ? LinearGradient.celebrate : LinearGradient(
                            colors: [Palette.accent, Palette.brand], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(10, geo.size.width * bill.freeDeliveryProgress))
                        .overlay(alignment: .trailing) {
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.trailing, 4)
                        }
                }
            }
            .frame(height: 10)
            .animation(.spring(response: 0.5, dampingFraction: 0.75), value: bill.freeDeliveryProgress)
        }
    }

    private var headline: String {
        if unlocked {
            return "Yay! FREE delivery unlocked 🎉"
        }
        return "Add \(rupees(bill.amountToFreeDelivery)) more for FREE delivery"
    }
}
