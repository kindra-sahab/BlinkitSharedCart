//
//  GroupSession.swift
//  BlinkitSharedCart
//
//  The shared, live state of a group order.
//

import Foundation

enum GroupStatus: String {
    case active        // collecting items
    case placing       // host is checking out
    case placed        // order confirmed
    case expired
}

struct GroupSession: Identifiable, Hashable {
    let id: String
    let inviteCode: String
    let hostID: String
    var participants: [Participant]
    var items: [CartItem]
    var status: GroupStatus
    let createdAt: Date
    var expiresAt: Date

    var host: Participant? { participants.first { $0.id == hostID } }
    var bill: Bill { Bill(items: items) }
    var onlineCount: Int { participants.filter { $0.isOnline }.count }

    func items(addedBy id: String) -> [CartItem] { items.filter { $0.addedByID == id } }
    func participant(_ id: String) -> Participant? { participants.first { $0.id == id } }

    static func == (l: GroupSession, r: GroupSession) -> Bool { l.id == r.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
