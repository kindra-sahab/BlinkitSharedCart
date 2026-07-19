//
//  SyncMessage.swift
//  BlinkitSharedCart
//
//  Wire protocol for the peer-to-peer group order. The HOST is authoritative:
//  guests send *intents*, the host applies them and broadcasts a full `.state`
//  snapshot back to everyone.
//

import Foundation

enum SyncMessage: Codable {
    // Host → guests
    case invite(host: Participant, remaining: Double, sessionID: String)
    case state(GroupSession)
    case orderPlaced(Order)
    case stageUpdate(orderID: String, stage: OrderStage)
    case endSession

    // Guest → host (intents)
    case joinRequest(Participant)
    case addItemIntent(productID: String, by: Participant)
    case changeProductIntent(productID: String, delta: Int, by: Participant)
    case changeQtyIntent(itemID: String, delta: Int, by: Participant)
    case browsingIntent(participantID: String, browsing: Bool)

    // Anyone → everyone
    case returnUpdate(ReturnRequest)

    var debugLabel: String {
        switch self {
        case .invite: "invite"
        case .state: "state"
        case .orderPlaced: "orderPlaced"
        case .stageUpdate: "stage"
        case .endSession: "end"
        case .joinRequest: "join"
        case .addItemIntent: "add"
        case .changeProductIntent: "change"
        case .changeQtyIntent: "qty"
        case .browsingIntent: "browsing"
        case .returnUpdate: "return"
        }
    }
}
