//
//  Participant.swift
//  BlinkitSharedCart
//

import SwiftUI

/// A person in a group order (the host or a friend/roommate).
struct Participant: Identifiable, Hashable {
    let id: String
    let name: String
    let avatarEmoji: String
    let colorHex: UInt
    var isHost: Bool = false

    // Live presence
    var isOnline: Bool = true
    var isBrowsing: Bool = false   // drives the "typing"/browsing indicator

    var color: Color { Color(hex: colorHex) }
    var initials: String { String(name.prefix(1)).uppercased() }
    var firstName: String { name.components(separatedBy: " ").first ?? name }
}

extension Participant {
    // The device owner (host by default in this prototype).
    static let me = Participant(
        id: "u_me", name: "Jatin", avatarEmoji: "🧑🏻", colorHex: 0x0FA958, isHost: true
    )

    // A roster of friends/roommates that can be invited.
    static let rahul = Participant(id: "u_rahul", name: "Rahul", avatarEmoji: "🧔🏽", colorHex: 0x7C5CFC)
    static let aman  = Participant(id: "u_aman",  name: "Aman",  avatarEmoji: "👨🏽", colorHex: 0xFF7A45)
    static let priya = Participant(id: "u_priya", name: "Priya", avatarEmoji: "👩🏻", colorHex: 0x2D9CDB)
    static let neha  = Participant(id: "u_neha",  name: "Neha",  avatarEmoji: "👩🏽", colorHex: 0xF2596F)
    static let kabir = Participant(id: "u_kabir", name: "Kabir", avatarEmoji: "🧑🏾", colorHex: 0x16B8A6)

    static let friendRoster: [Participant] = [rahul, aman, priya, neha, kabir]
}
