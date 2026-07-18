//
//  ReturnRequest.swift
//  BlinkitSharedCart
//

import SwiftUI

enum ReturnStatus: String, CaseIterable {
    case requested = "Requested"
    case approved = "Approved"
    case pickedUp = "Picked Up"
    case refunded = "Refunded"

    var progress: Double {
        switch self {
        case .requested: 0.25
        case .approved: 0.5
        case .pickedUp: 0.75
        case .refunded: 1.0
        }
    }

    var color: Color {
        switch self {
        case .requested: Palette.warning
        case .approved: Palette.violet
        case .pickedUp: Palette.accent
        case .refunded: Palette.success
        }
    }
}

struct ReturnRequest: Identifiable {
    let id: String
    let item: CartItem
    let reason: String
    let requestedByID: String
    let requestedByName: String
    var status: ReturnStatus
    let createdAt: Date

    var refundAmount: Double { item.lineTotal }
}

enum ReturnReason: String, CaseIterable, Identifiable {
    case damaged = "Item damaged"
    case wrong = "Wrong item delivered"
    case quality = "Quality not as expected"
    case expired = "Expired / near expiry"
    case changedMind = "Changed my mind"
    var id: String { rawValue }
}
