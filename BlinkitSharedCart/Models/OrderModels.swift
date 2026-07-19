//
//  OrderModels.swift
//  BlinkitSharedCart
//

import SwiftUI

enum OrderStage: Int, CaseIterable, Identifiable, Codable {
    case preparing, packed, outForDelivery, arriving, delivered
    var id: Int { rawValue }

    var title: String {
        switch self {
        case .preparing: "Preparing"
        case .packed: "Packed"
        case .outForDelivery: "Out for Delivery"
        case .arriving: "Arriving"
        case .delivered: "Delivered"
        }
    }

    var subtitle: String {
        switch self {
        case .preparing: "Picking & packing your items"
        case .packed: "Your order is sealed and ready"
        case .outForDelivery: "Rider has left the store"
        case .arriving: "Rider is near your location"
        case .delivered: "Enjoy! Order delivered"
        }
    }

    var icon: String {
        switch self {
        case .preparing: "bag.fill"
        case .packed: "shippingbox.fill"
        case .outForDelivery: "bicycle"
        case .arriving: "location.fill"
        case .delivered: "checkmark.seal.fill"
        }
    }
}

struct Order: Identifiable, Hashable, Codable {
    static func == (l: Order, r: Order) -> Bool { l.id == r.id && l.stage == r.stage }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    let id: String
    let items: [CartItem]
    let bill: Bill
    let placedByName: String
    let isGroupOrder: Bool
    var isRecurring: Bool = false
    let participants: [Participant]
    let placedAt: Date
    var stage: OrderStage

    var etaText: String {
        switch stage {
        case .preparing, .packed: "Arriving in 11 mins"
        case .outForDelivery: "Arriving in 6 mins"
        case .arriving: "Arriving in 2 mins"
        case .delivered: "Delivered"
        }
    }
}
