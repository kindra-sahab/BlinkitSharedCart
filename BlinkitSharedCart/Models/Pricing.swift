//
//  Pricing.swift
//  BlinkitSharedCart
//
//  Single source of truth for fee logic, shared by personal + group carts.
//

import Foundation

enum Pricing {
    static let freeDeliveryThreshold: Double = 200
    static let baseDeliveryFee: Double = 25
    static let smallCartThreshold: Double = 100
    static let smallCartFee: Double = 20
    static let handlingFee: Double = 6

    static func deliveryFee(for subtotal: Double) -> Double {
        subtotal >= freeDeliveryThreshold ? 0 : baseDeliveryFee
    }

    static func smallCartFee(for subtotal: Double) -> Double {
        subtotal > 0 && subtotal < smallCartThreshold ? smallCartFee : 0
    }

    static func amountToFreeDelivery(for subtotal: Double) -> Double {
        max(0, freeDeliveryThreshold - subtotal)
    }

    static func freeDeliveryProgress(for subtotal: Double) -> Double {
        min(1, subtotal / freeDeliveryThreshold)
    }
}

/// Computed bill for any list of cart items.
struct Bill {
    let subtotal: Double
    let deliveryFee: Double
    let smallCartFee: Double
    let handlingFee: Double

    init(items: [CartItem]) {
        let sub = items.reduce(0) { $0 + $1.lineTotal }
        subtotal = sub
        deliveryFee = Pricing.deliveryFee(for: sub)
        smallCartFee = Pricing.smallCartFee(for: sub)
        handlingFee = sub > 0 ? Pricing.handlingFee : 0
    }

    var total: Double { subtotal + deliveryFee + smallCartFee + handlingFee }
    var freeDeliveryUnlocked: Bool { subtotal >= Pricing.freeDeliveryThreshold }
    var amountToFreeDelivery: Double { Pricing.amountToFreeDelivery(for: subtotal) }
    var freeDeliveryProgress: Double { Pricing.freeDeliveryProgress(for: subtotal) }
    var savedOnDelivery: Double { freeDeliveryUnlocked ? Pricing.baseDeliveryFee : 0 }
}
