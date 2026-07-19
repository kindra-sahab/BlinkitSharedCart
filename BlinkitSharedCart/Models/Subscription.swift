//
//  Subscription.swift
//  BlinkitSharedCart
//
//  Recurring ("scheduled") delivery: the same set of items delivered on a
//  schedule, auto-paid from Blinkit Money.
//

import SwiftUI

enum SubStatus: String, Codable {
    case active, paused, ended, cancelled

    var label: String {
        switch self {
        case .active: "Active"
        case .paused: "Paused"
        case .ended: "Completed"
        case .cancelled: "Cancelled"
        }
    }
    var color: Color {
        switch self {
        case .active: Palette.success
        case .paused: Palette.warning
        case .ended: Palette.inkSecondary
        case .cancelled: Palette.danger
        }
    }
}

struct SubDelivery: Identifiable {
    enum Status: String { case delivered, skipped, failed, upcoming }
    let id: String
    let date: Date
    var status: Status
    let amount: Double
    var orderID: String?

    init(id: String = UUID().uuidString, date: Date, status: Status, amount: Double, orderID: String? = nil) {
        self.id = id; self.date = date; self.status = status; self.amount = amount; self.orderID = orderID
    }
}

struct Subscription: Identifiable {
    let id: String
    var title: String
    var items: [CartItem]
    var startDate: Date
    var endDate: Date
    var hour: Int
    var minute: Int
    var weekdays: Set<Int>          // Calendar weekday, 1 = Sunday … 7 = Saturday
    var status: SubStatus
    var nextRunDate: Date
    var deliveries: [SubDelivery]
    let createdAt: Date

    // MARK: Derived

    var itemsSubtotal: Double { items.reduce(0) { $0 + $1.lineTotal } }
    /// Subscriptions get FREE delivery as a perk — just items + handling.
    var perDeliveryTotal: Double { itemsSubtotal + (items.isEmpty ? 0 : Pricing.handlingFee) }
    var itemCount: Int { items.reduce(0) { $0 + $1.quantity } }
    var deliveredCount: Int { deliveries.filter { $0.status == .delivered }.count }
    var runsEveryDay: Bool { weekdays.count == 7 }
    var isLive: Bool { status == .active }

    var timeText: String {
        var c = DateComponents(); c.hour = hour; c.minute = minute
        let d = Calendar.current.date(from: c) ?? .now
        let f = DateFormatter(); f.dateFormat = "h:mm a"
        return f.string(from: d)
    }

    var frequencyText: String {
        if runsEveryDay { return "Every day" }
        if weekdays == [2, 3, 4, 5, 6] { return "Weekdays" }
        if weekdays == [1, 7] { return "Weekends" }
        let order = [1, 2, 3, 4, 5, 6, 7]
        let names = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return order.filter { weekdays.contains($0) }.map { names[$0] }.joined(separator: ", ")
    }

    var scheduleText: String { "\(frequencyText) · \(timeText)" }

    /// Upcoming run dates (for the schedule preview), skipping non-matching weekdays.
    func upcomingRuns(_ count: Int = 5, from date: Date = .now) -> [Date] {
        var result: [Date] = []
        let cal = Calendar.current
        var cursor = max(date, nextRunDate)
        var guardCounter = 0
        while result.count < count && cursor <= endDate && guardCounter < 400 {
            guardCounter += 1
            if weekdays.contains(cal.component(.weekday, from: cursor)) {
                result.append(cursor)
            }
            cursor = cal.date(byAdding: .day, value: 1, to: cursor).map {
                var c = cal.dateComponents([.year, .month, .day], from: $0)
                c.hour = hour; c.minute = minute
                return cal.date(from: c) ?? $0
            } ?? cursor.addingTimeInterval(86400)
        }
        return result
    }
}

enum SubFrequencyPreset: String, CaseIterable, Identifiable {
    case everyday = "Every day"
    case weekdays = "Weekdays"
    case weekends = "Weekends"
    case custom = "Custom"
    var id: String { rawValue }

    var days: Set<Int> {
        switch self {
        case .everyday: [1, 2, 3, 4, 5, 6, 7]
        case .weekdays: [2, 3, 4, 5, 6]
        case .weekends: [1, 7]
        case .custom: [1, 2, 3, 4, 5, 6, 7]
        }
    }
}
