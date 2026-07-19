//
//  CartItem.swift
//  BlinkitSharedCart
//

import Foundation

/// A line item in a cart. In a group order it also records who added it.
struct CartItem: Identifiable, Hashable, Codable {
    let id: String
    let product: Product
    var quantity: Int
    var addedByID: String
    var addedByName: String
    var addedAt: Date

    init(
        id: String = UUID().uuidString,
        product: Product,
        quantity: Int = 1,
        addedBy: Participant,
        addedAt: Date = .now
    ) {
        self.id = id
        self.product = product
        self.quantity = quantity
        self.addedByID = addedBy.id
        self.addedByName = addedBy.name
        self.addedAt = addedAt
    }

    var lineTotal: Double { product.price * Double(quantity) }
}

extension CartItem {
    /// Deterministic id per (participant, product) so an optimistic copy on the
    /// guest and the host-authoritative copy share the same id and reconcile
    /// cleanly when the host broadcasts state back.
    static func group(_ product: Product, quantity: Int = 1, addedBy: Participant) -> CartItem {
        CartItem(id: "\(addedBy.id)__\(product.id)", product: product, quantity: quantity, addedBy: addedBy)
    }
}
