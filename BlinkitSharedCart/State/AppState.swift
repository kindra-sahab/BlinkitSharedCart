//
//  AppState.swift
//  BlinkitSharedCart
//
//  Central @Observable coordinator (MVVM app model): owns the personal cart,
//  the realtime group session, notifications, the active order and returns,
//  plus lightweight navigation state.
//

import SwiftUI
import Observation

enum AppTab: Hashable { case home, categories, cart, orders }

@Observable
@MainActor
final class AppState {

    // Identity — the device owner.
    var currentUser: Participant = .me

    // Solo cart (before a group order exists).
    private(set) var personalItems: [CartItem] = []

    // Realtime group backend.
    let realtime = RealtimeService()

    // Inbox + transient push banner.
    private(set) var notifications: [AppNotification] = []
    var banner: AppNotification?

    // Orders + returns.
    private(set) var activeOrder: Order?
    private(set) var pastOrders: [Order] = []
    private(set) var returns: [ReturnRequest] = []

    // Navigation
    var selectedTab: AppTab = .home
    var showInviteSheet = false
    var showSharedCart = false
    var showCheckout = false
    var showOrderConfirmed = false

    private var trackingTask: Task<Void, Never>?
    private var hostAutoPlaceTask: Task<Void, Never>?

    init() {
        wireRealtime()
        seedDemoInbox()
    }

    private func wireRealtime() {
        realtime.onFriendActivity = { [weak self] activity in
            guard let self else { return }
            // Only surface item-add activity as an inbox push.
            if activity.text.hasPrefix("added") {
                self.pushNotification(.init(
                    kind: .itemAdded,
                    title: "\(activity.participantName) \(activity.text)",
                    body: "Your shared cart just got bigger."
                ), banner: false)
            }
        }
        realtime.onFreeDeliveryUnlocked = { [weak self] in
            self?.pushNotification(.init(
                kind: .freeDelivery,
                title: "🎉 Free Delivery Unlocked!",
                body: "Your group crossed \(rupees(Pricing.freeDeliveryThreshold)). Delivery is on us."
            ), banner: true)
        }
    }

    // MARK: - Session role

    var session: GroupSession? { realtime.session }
    var isInGroup: Bool { realtime.session != nil }
    var isHost: Bool { realtime.session?.hostID == currentUser.id }

    // MARK: - Personal cart

    var personalBill: Bill { Bill(items: personalItems) }

    func personalQuantity(of product: Product) -> Int {
        personalItems.first { $0.product.id == product.id }?.quantity ?? 0
    }

    func addToPersonalCart(_ product: Product) {
        if let idx = personalItems.firstIndex(where: { $0.product.id == product.id }) {
            personalItems[idx].quantity += 1
        } else {
            personalItems.append(CartItem(product: product, addedBy: currentUser))
        }
    }

    func changePersonalQuantity(_ product: Product, delta: Int) {
        guard let idx = personalItems.firstIndex(where: { $0.product.id == product.id }) else {
            if delta > 0 { addToPersonalCart(product) }
            return
        }
        personalItems[idx].quantity += delta
        if personalItems[idx].quantity <= 0 { personalItems.remove(at: idx) }
    }

    func clearPersonalCart() { personalItems.removeAll() }

    // MARK: - Group order (host flow)

    func startGroupOrder(inviting friends: [Participant]) {
        currentUser = .me
        // Seed the shared cart with whatever the host already had.
        let seeded = personalItems.map {
            CartItem(product: $0.product, quantity: $0.quantity, addedBy: currentUser, addedAt: .now)
        }
        realtime.createSession(host: currentUser, seededWith: seeded)
        personalItems.removeAll()   // moved into the shared cart

        // "Send" a push to each invited friend, then simulate them joining.
        for (i, friend) in friends.enumerated() {
            let remaining = realtime.session?.bill.amountToFreeDelivery ?? 0
            logOutgoingInvite(to: friend, remaining: remaining)
            let delay = Double.random(in: 2.0...5.0) + Double(i) * 1.2
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(delay))
                self?.realtime.join(friend)
            }
        }
        showInviteSheet = false
        showSharedCart = true
    }

    /// Current user (host or guest) adds an item to the live shared cart.
    func addToGroup(_ product: Product) {
        realtime.addItem(product, by: currentUser)
    }

    func groupQuantity(of product: Product) -> Int {
        realtime.session?.items
            .filter { $0.product.id == product.id && $0.addedByID == currentUser.id }
            .reduce(0) { $0 + $1.quantity } ?? 0
    }

    // MARK: - Context-aware add (group cart if live, else personal)

    /// Quantity of a product in whichever cart is active for the current user.
    func contextQuantity(of product: Product) -> Int {
        isInGroup ? groupQuantity(of: product) : personalQuantity(of: product)
    }

    func contextAdd(_ product: Product) {
        if isInGroup { addToGroup(product) } else { addToPersonalCart(product) }
    }

    func contextChange(_ product: Product, delta: Int) {
        if isInGroup {
            if let line = realtime.session?.items.first(where: {
                $0.product.id == product.id && $0.addedByID == currentUser.id
            }) {
                realtime.changeQuantity(itemID: line.id, delta: delta, by: currentUser)
            } else if delta > 0 {
                addToGroup(product)
            }
        } else {
            changePersonalQuantity(product, delta: delta)
        }
    }

    // MARK: - Group order (guest / joining flow)

    /// Accept an incoming invite: join a session hosted by a friend (bot host).
    func acceptInvite(_ notification: AppNotification) {
        let host = Participant.rahul
        var hostOnline = host; hostOnline.isHost = true; hostOnline.isOnline = true
        // Seed with the host's existing items.
        let seed = [
            CartItem(product: MockCatalog.product("p_milk")!, addedBy: hostOnline),
            CartItem(product: MockCatalog.product("p_bread")!, addedBy: hostOnline),
        ]
        realtime.createSession(host: hostOnline, seededWith: seed)
        // I join as myself.
        realtime.join(currentUser, autoContribute: false)
        // Another roommate joins too, for liveliness.
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            self?.realtime.join(.aman)
        }
        scheduleHostAutoPlace(host: hostOnline)
        markRead(notification)
        showSharedCart = true
    }

    /// When I'm a guest, the host (bot) places the order once it makes sense.
    private func scheduleHostAutoPlace(host: Participant) {
        hostAutoPlaceTask?.cancel()
        hostAutoPlaceTask = Task { [weak self] in
            // Wait until free delivery is close/unlocked or a max window passes.
            for _ in 0..<20 {
                try? await Task.sleep(for: .seconds(1))
                guard let self, let s = self.realtime.session, s.status == .active else { return }
                if s.bill.freeDeliveryUnlocked { break }
            }
            try? await Task.sleep(for: .seconds(3))
            guard let self, let s = self.realtime.session, s.status == .active else { return }
            self.realtime.markPlacing()
            try? await Task.sleep(for: .seconds(1.2))
            self.finalizeGroupOrder(placedBy: host)
        }
    }

    // MARK: - Checkout

    /// Host places the group order.
    func placeGroupOrder() {
        guard isHost, let host = session?.host else { return }
        realtime.markPlacing()
        finalizeGroupOrder(placedBy: host)
    }

    private func finalizeGroupOrder(placedBy host: Participant) {
        guard let s = realtime.session else { return }
        realtime.markPlaced()
        let order = Order(
            id: "ORD" + String(Int.random(in: 10000...99999)),
            items: s.items,
            bill: s.bill,
            placedByName: host.name,
            isGroupOrder: true,
            participants: s.participants,
            placedAt: .now,
            stage: .preparing
        )
        activeOrder = order
        showCheckout = false
        showSharedCart = false
        showOrderConfirmed = true
        pushNotification(.init(
            kind: .orderPlaced,
            title: "Order Confirmed",
            body: "\(host.name) placed the group order · \(rupees(s.bill.total)). Arriving in ~11 mins."
        ), banner: true)
        startTrackingSimulation()
    }

    /// Place a normal solo order (no group).
    func placeSoloOrder() {
        guard !personalItems.isEmpty else { return }
        let bill = personalBill
        let order = Order(
            id: "ORD" + String(Int.random(in: 10000...99999)),
            items: personalItems,
            bill: bill,
            placedByName: currentUser.name,
            isGroupOrder: false,
            participants: [currentUser],
            placedAt: .now,
            stage: .preparing
        )
        activeOrder = order
        personalItems.removeAll()
        showCheckout = false
        showOrderConfirmed = true
        pushNotification(.init(kind: .orderPlaced, title: "Order Confirmed",
                               body: "Your order \(order.id) is being prepared."), banner: true)
        startTrackingSimulation()
    }

    func dismissGroup() {
        realtime.endSession()
        showSharedCart = false
    }

    // MARK: - Order tracking simulation

    private func startTrackingSimulation() {
        trackingTask?.cancel()
        trackingTask = Task { [weak self] in
            let stages = OrderStage.allCases
            for stage in stages.dropFirst() {   // start already at .preparing
                try? await Task.sleep(for: .seconds(6))
                guard let self, self.activeOrder != nil else { return }
                withAnimation(.spring) { self.activeOrder?.stage = stage }
                self.pushNotification(.init(
                    kind: stage == .delivered ? .orderPlaced : .tracking,
                    title: stage.title,
                    body: stage.subtitle
                ), banner: stage == .outForDelivery || stage == .delivered)
                if stage == .delivered {
                    if let done = self.activeOrder {
                        self.pastOrders.insert(done, at: 0)
                    }
                }
            }
        }
    }

    // MARK: - Returns

    func requestReturn(for item: CartItem, reason: ReturnReason) {
        let req = ReturnRequest(
            id: "RET" + String(Int.random(in: 1000...9999)),
            item: item,
            reason: reason.rawValue,
            requestedByID: currentUser.id,
            requestedByName: currentUser.name,
            status: .requested,
            createdAt: .now
        )
        returns.insert(req, at: 0)
        pushNotification(.init(kind: .returnUpdate, title: "Return requested",
                               body: "\(item.product.name) · refund \(rupees(item.lineTotal)) is being processed."),
                         banner: true)
        advanceReturn(req.id)
    }

    /// Whether the current user is allowed to return a given delivered item.
    func canReturn(_ item: CartItem) -> Bool {
        currentUser.isHost || item.addedByID == currentUser.id || !(activeOrder?.isGroupOrder ?? false)
    }

    private func advanceReturn(_ id: String) {
        Task { [weak self] in
            let flow: [ReturnStatus] = [.approved, .pickedUp, .refunded]
            for status in flow {
                try? await Task.sleep(for: .seconds(4))
                guard let self, let idx = self.returns.firstIndex(where: { $0.id == id }) else { return }
                withAnimation(.spring) { self.returns[idx].status = status }
            }
        }
    }

    // MARK: - Notifications

    var unreadCount: Int { notifications.filter { !$0.isRead }.count }

    func pushNotification(_ n: AppNotification, banner: Bool) {
        notifications.insert(n, at: 0)
        if banner {
            withAnimation(.spring) { self.banner = n }
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(3.2))
                if self?.banner?.id == n.id { withAnimation { self?.banner = nil } }
            }
        }
    }

    func markRead(_ n: AppNotification) {
        if let idx = notifications.firstIndex(where: { $0.id == n.id }) {
            notifications[idx].isRead = true
        }
    }

    func markAllRead() {
        for i in notifications.indices { notifications[i].isRead = true }
    }

    private func logOutgoingInvite(to friend: Participant, remaining: Double) {
        pushNotification(.init(
            kind: .groupInvite,
            title: "Invite sent to \(friend.name)",
            body: "Only \(rupees(remaining)) more needed to unlock free delivery."
        ), banner: false)
    }

    private func seedDemoInbox() {
        notifications = [
            AppNotification(
                kind: .groupInvite,
                title: "Rahul is placing a group order",
                body: "Only ₹120 more is needed to unlock free delivery. Want to add something?",
                date: Date().addingTimeInterval(-120),
                inviteSessionID: "demo"
            ),
            AppNotification(kind: .generic, title: "Rain incoming ☔️",
                            body: "Stock up on essentials before the evening showers.",
                            date: Date().addingTimeInterval(-3600)),
        ]
    }
}
