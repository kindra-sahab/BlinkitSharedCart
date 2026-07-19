//
//  Settlement.swift
//  BlinkitSharedCart
//
//  Works out who owes the host how much after a group order is paid.
//  Rule: everyone pays for their own items + an equal share of the fees.
//  The host paid the whole bill up front, so contributors owe the host back.
//

import Foundation

struct Settlement {
    struct Due: Identifiable {
        let participant: Participant
        let itemsTotal: Double
        let feeShare: Double
        var id: String { participant.id }
        var total: Double { itemsTotal + feeShare }
    }

    let host: Participant
    let dues: [Due]                 // one per contributor (incl. host)
    let feesTotal: Double

    init(order: Order) {
        let host = order.participants.first { $0.isHost } ?? order.participants[0]
        self.host = host
        let fees = order.bill.deliveryFee + order.bill.smallCartFee + order.bill.handlingFee
        self.feesTotal = fees

        // Only people who added at least one item share the fees.
        let contributors = order.participants.filter { p in
            order.items.contains { $0.addedByID == p.id }
        }
        let share = contributors.isEmpty ? 0 : fees / Double(contributors.count)

        dues = contributors.map { p in
            let itemsTotal = order.items
                .filter { $0.addedByID == p.id }
                .reduce(0) { $0 + $1.lineTotal }
            return Due(participant: p, itemsTotal: itemsTotal, feeShare: share)
        }
    }

    /// Dues owed *to* the host (everyone except the host).
    var receivables: [Due] { dues.filter { $0.participant.id != host.id } }

    var hostShare: Double { dues.first { $0.participant.id == host.id }?.total ?? 0 }
    var totalReceivable: Double { receivables.reduce(0) { $0 + $1.total } }

    /// What a given user owes the host (0 if they are the host).
    func amountOwed(by userID: String) -> Double {
        userID == host.id ? 0 : (dues.first { $0.participant.id == userID }?.total ?? 0)
    }
}
