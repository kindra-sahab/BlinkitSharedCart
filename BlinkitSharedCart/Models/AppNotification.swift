//
//  AppNotification.swift
//  BlinkitSharedCart
//

import SwiftUI

enum NotificationKind {
    case groupInvite       // "Jatin is placing an order..."
    case itemAdded         // "Rahul added Bread"
    case freeDelivery      // threshold unlocked
    case orderPlaced
    case tracking
    case returnUpdate
    case generic

    var icon: String {
        switch self {
        case .groupInvite: "person.2.fill"
        case .itemAdded: "cart.fill.badge.plus"
        case .freeDelivery: "party.popper.fill"
        case .orderPlaced: "checkmark.seal.fill"
        case .tracking: "bicycle"
        case .returnUpdate: "arrow.uturn.left"
        case .generic: "bell.fill"
        }
    }

    var tint: Color {
        switch self {
        case .groupInvite: Palette.violet
        case .itemAdded: Palette.brand
        case .freeDelivery: Palette.accent
        case .orderPlaced: Palette.success
        case .tracking: Palette.brand
        case .returnUpdate: Palette.warning
        case .generic: Palette.inkSecondary
        }
    }
}

struct AppNotification: Identifiable {
    let id: String
    let kind: NotificationKind
    let title: String
    let body: String
    let date: Date
    var isRead: Bool
    /// Optional invite payload — present for group invite notifications.
    var inviteSessionID: String? = nil

    init(
        id: String = UUID().uuidString,
        kind: NotificationKind,
        title: String,
        body: String,
        date: Date = .now,
        isRead: Bool = false,
        inviteSessionID: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.body = body
        self.date = date
        self.isRead = isRead
        self.inviteSessionID = inviteSessionID
    }
}
