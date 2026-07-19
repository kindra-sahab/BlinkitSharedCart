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

/// An incoming live (multipeer) invite awaiting Join / Ignore.
struct LiveInvite: Identifiable, Equatable {
    let id = UUID()
    let hostName: String
    let hostEmoji: String
    let remaining: Double
    let sessionID: String
}

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

    // Recurring delivery + wallet ("Blinkit Money").
    private(set) var subscriptions: [Subscription] = []
    private(set) var walletBalance: Double = 480
    /// Bumped on any subscription change so pushed subscription views refresh.
    private(set) var subsTick = 0
    var showCreateSubscription = false
    var showSubscriptions = false
    var showWallet = false
    private var subTasks: [String: Task<Void, Never>] = [:]

    // Navigation
    var selectedTab: AppTab = .home
    var showInviteSheet = false
    var showSharedCart = false
    var showCheckout = false
    var showOrderConfirmed = false
    var showSettlement = false

    // MARK: Live (two-phone) group order over Multipeer
    private(set) var multipeer: MultipeerService
    /// True when the active session is a real multi-device one (vs. simulated friends).
    private(set) var isLiveSession = false
    /// Incoming live invite awaiting Join / Ignore on this device.
    var liveInvite: LiveInvite?

    private var trackingTask: Task<Void, Never>?
    private var hostAutoPlaceTask: Task<Void, Never>?
    /// Host heartbeat: re-broadcasts full cart state every 2s so a missed
    /// packet self-heals and guests can never be left with a stale cart.
    private var stateHeartbeatTask: Task<Void, Never>?
    /// Link watchdog: pings + detects a zombie MPC link and rebuilds it,
    /// so a stuck connection never requires killing the app.
    private var linkWatchdogTask: Task<Void, Never>?

    init() {
        multipeer = MultipeerService(displayName: Participant.me.name)
        wireRealtime()
        wireMultipeer()
        seedDemoInbox()
        LocalNotifier.shared.configure()
        LocalNotifier.shared.onJoinTapped = { [weak self] in self?.acceptLiveInvite() }
        multipeer.start()
        startLinkWatchdog()
    }

    // MARK: - Link watchdog (self-healing transport)

    /// Guests ping every 2.5s while an order is live — pings keep the link warm
    /// and (with the host's 2s state heartbeat) continuously repair sync.
    /// NOTE: we deliberately never tear down / recreate the MPC stack — rapid
    /// churn of advertiser/browser objects crashes CoreFoundation.
    private func startLinkWatchdog() {
        linkWatchdogTask?.cancel()
        linkWatchdogTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.5))
                guard let self else { return }
                let active = self.realtime.session?.status == .active
                if self.isLiveSession && !self.isHost && active {
                    self.multipeer.send(.ping)
                }
            }
        }
    }

    // MARK: - Identity (each phone picks who they are)

    func setIdentity(_ participant: Participant) {
        guard participant.id != currentUser.id else { return }
        var p = participant
        p.isHost = (participant.id == Participant.me.id)   // only the owner identity hosts
        currentUser = p
        // NOTE: the transport is intentionally NOT recreated — identity travels
        // in message payloads, and churning MPC objects crashes CoreFoundation.
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

    // MARK: - Multipeer wiring

    private func wireMultipeer() {
        multipeer.onReceive = { [weak self] message in self?.handleSync(message) }
        multipeer.onPeersChanged = { [weak self] count in
            // A phone just connected (e.g. the guest opened the app). If we're
            // hosting a live order, (re)send the invite + snapshot so they get
            // notified immediately — the host doesn't have to wait for them.
            guard let self, self.isLiveSession, self.isHost, count > 0 else { return }
            self.resendLiveInviteToPeers()
        }
    }

    private func resendLiveInviteToPeers() {
        // Only re-invite while the order is still being collected — never after
        // it's been placed/expired (which caused stale invite popups).
        guard isLiveSession, isHost, let s = session, s.status == .active, let host = s.host else { return }
        multipeer.send(.invite(host: host, remaining: s.bill.amountToFreeDelivery, sessionID: s.id))
        multipeer.send(.state(s))
    }

    private func handleSync(_ message: SyncMessage) {
        switch message {
        case .invite(let host, let remaining, let sessionID):
            guard !isHost else { return }
            // Already joined THIS session (any status)? Ignore re-broadcasts of it.
            if let s = session, s.id == sessionID, s.participant(currentUser.id) != nil { return }
            // Already showing the invite for this session? Ignore.
            if liveInvite?.sessionID == sessionID { return }
            // A NEW round is starting — drop any leftover finished session so
            // round 2 begins with a completely clean slate.
            if let s = session, s.id != sessionID, s.status != .active {
                realtime.endSession()
                isLiveSession = false
            }
            liveInvite = LiveInvite(hostName: host.name, hostEmoji: host.avatarEmoji,
                                    remaining: remaining, sessionID: sessionID)
            LocalNotifier.shared.postGroupInvite(hostName: host.name, remaining: remaining)
            pushNotification(.init(
                kind: .groupInvite,
                title: "\(host.name) is placing a Zipp order",
                body: remaining > 0
                    ? "Only \(rupees(remaining)) more is needed to unlock free delivery. Want to add something?"
                    : "You've been invited to a shared group cart.",
                inviteSessionID: "live"), banner: true)

        case .joinRequest(let participant):
            guard isLiveSession, isHost else { return }
            realtime.join(participant, autoContribute: false)
            broadcastStateIfHost()

        case .state(let session):
            // Host is authoritative — it must NEVER apply an incoming state
            // (a stale third device broadcasting old state was corrupting the
            // host session and wiping joined participants).
            guard !isHost else { return }
            isLiveSession = true
            realtime.applyRemoteState(session)

        case .addItemIntent(let productID, let by):
            guard isLiveSession, isHost, let product = MockCatalog.product(productID) else { return }
            ensureParticipant(by)
            realtime.addItem(product, by: by)
            broadcastStateIfHost()

        case .changeProductIntent(let productID, let delta, let by):
            guard isLiveSession, isHost, let product = MockCatalog.product(productID) else { return }
            ensureParticipant(by)
            realtime.changeProductQuantity(product, by: by, delta: delta)
            broadcastStateIfHost()

        case .changeQtyIntent(let itemID, let delta, let by):
            guard isLiveSession, isHost else { return }
            ensureParticipant(by)
            realtime.changeQuantity(itemID: itemID, delta: delta, by: by)
            broadcastStateIfHost()

        case .browsingIntent(let pid, let browsing):
            guard isLiveSession, isHost else { return }
            realtime.setBrowsing(pid, browsing)
            broadcastStateIfHost()

        case .orderPlaced(let order):
            guard !isHost else { return }
            realtime.markPlaced()
            liveInvite = nil            // clear any lingering invite for this session
            activeOrder = order
            showSharedCart = false
            showOrderConfirmed = true
            pushNotification(.init(kind: .orderPlaced, title: "Order Confirmed",
                body: "\(order.placedByName) placed the group order · \(rupees(order.bill.total))."), banner: true)

        case .stageUpdate(let orderID, let stage):
            guard activeOrder?.id == orderID else { return }
            withAnimation(.spring) { activeOrder?.stage = stage }
            if stage == .delivered, let done = activeOrder { pastOrders.insert(done, at: 0) }
            pushNotification(.init(kind: stage == .delivered ? .orderPlaced : .tracking,
                title: stage.title, body: stage.subtitle),
                banner: stage == .outForDelivery || stage == .delivered)

        case .returnUpdate(let req):
            if let idx = returns.firstIndex(where: { $0.id == req.id }) { returns[idx] = req }
            else { returns.insert(req, at: 0) }

        case .endSession:
            guard !isHost else { return }
            realtime.endSession()
            isLiveSession = false
            showSharedCart = false

        case .ping:
            break   // receiving it already refreshed lastRxDate — that's its job
        }
    }

    private func broadcastStateIfHost() {
        guard isLiveSession, isHost, let s = session else { return }
        multipeer.send(.state(s))
    }

    /// If a message arrives from someone not yet in the session, register them —
    /// so even a lost joinRequest can never make a contributor invisible.
    private func ensureParticipant(_ p: Participant) {
        guard realtime.session?.participant(p.id) == nil else { return }
        realtime.join(p, autoContribute: false)
    }

    // MARK: - Live group order (host)

    /// Host starts a real, cross-device group order and invites nearby phones.
    func startLiveGroupOrder() {
        currentUser.isHost = true
        var host = currentUser; host.isHost = true
        let seeded = personalItems.map {
            CartItem.group($0.product, quantity: $0.quantity, addedBy: host)
        }
        isLiveSession = true
        realtime.createSession(host: host, seededWith: seeded)
        personalItems.removeAll()
        let remaining = realtime.session?.bill.amountToFreeDelivery ?? 0
        multipeer.send(.invite(host: host, remaining: remaining, sessionID: realtime.session?.id ?? ""))
        broadcastStateIfHost()
        startStateHeartbeat()
        showInviteSheet = false
        showSharedCart = true
    }

    /// Host re-broadcasts the full state every 2s while collecting items, so
    /// even a dropped packet can never leave a guest with a stale cart.
    private func startStateHeartbeat() {
        stateHeartbeatTask?.cancel()
        stateHeartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard let self else { return }
                guard let s = self.realtime.session, s.status == .active, self.isHost else {
                    self.stateHeartbeatTask = nil
                    return
                }
                self.multipeer.send(.state(s))
            }
        }
    }

    // MARK: - Live group order (guest)

    var canJoinLive: Bool { currentUser.id != Participant.me.id }   // must pick a non-host identity

    func acceptLiveInvite() {
        guard liveInvite != nil else { return }
        isLiveSession = true
        liveInvite = nil
        multipeer.send(.joinRequest(currentUser))
        showSharedCart = true
        selectedTab = .cart
    }

    func ignoreLiveInvite() { liveInvite = nil }

    // MARK: - Live-aware cart mutations

    func groupChangeQuantity(itemID: String, delta: Int) {
        if isLiveSession && !isHost {
            realtime.changeQuantity(itemID: itemID, delta: delta, by: currentUser)   // optimistic
            multipeer.send(.changeQtyIntent(itemID: itemID, delta: delta, by: currentUser))
            return
        }
        realtime.changeQuantity(itemID: itemID, delta: delta, by: currentUser)
        broadcastStateIfHost()
    }

    func setGroupBrowsing(_ browsing: Bool) {
        guard isInGroup else { return }
        if isLiveSession && !isHost {
            multipeer.send(.browsingIntent(participantID: currentUser.id, browsing: browsing)); return
        }
        realtime.setBrowsing(currentUser.id, browsing)
        broadcastStateIfHost()
    }

    // MARK: - Settlement

    var settlement: Settlement? {
        guard let o = activeOrder, o.isGroupOrder else { return nil }
        return Settlement(order: o)
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
            CartItem.group($0.product, quantity: $0.quantity, addedBy: currentUser)
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
        groupChangeProduct(product, delta: 1)
    }

    /// Product-keyed group mutation. Guests apply optimistically for instant
    /// feedback, then send an intent; the host's broadcast reconciles.
    func groupChangeProduct(_ product: Product, delta: Int) {
        if isLiveSession && !isHost {
            realtime.changeProductQuantity(product, by: currentUser, delta: delta)   // optimistic
            multipeer.send(.changeProductIntent(productID: product.id, delta: delta, by: currentUser))
            return
        }
        realtime.changeProductQuantity(product, by: currentUser, delta: delta)
        broadcastStateIfHost()
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
            groupChangeProduct(product, delta: delta)
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
            CartItem.group(MockCatalog.product("p_milk")!, addedBy: hostOnline),
            CartItem.group(MockCatalog.product("p_bread")!, addedBy: hostOnline),
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
        // Tell every guest phone the order is placed.
        if isLiveSession { multipeer.send(.orderPlaced(order)) }
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
                guard let self, let orderID = self.activeOrder?.id else { return }
                withAnimation(.spring) { self.activeOrder?.stage = stage }
                if self.isLiveSession { self.multipeer.send(.stageUpdate(orderID: orderID, stage: stage)) }
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

    // MARK: - Recurring delivery (subscriptions)

    /// Demo cadence: how long one "day" lasts before the next auto-delivery fires.
    private let demoDaySeconds: Double = 22
    private let demoFirstRunSeconds: Double = 6

    func createSubscription(title: String, items: [CartItem], startDate: Date,
                            endDate: Date, hour: Int, minute: Int, weekdays: Set<Int>) {
        let id = "SUB" + String(Int.random(in: 1000...9999))
        let next = nextRunDate(after: startDate.addingTimeInterval(-60), hour: hour, minute: minute,
                               weekdays: weekdays, endDate: endDate)
        let sub = Subscription(
            id: id, title: title.isEmpty ? "Daily Essentials" : title,
            items: items, startDate: startDate, endDate: endDate,
            hour: hour, minute: minute, weekdays: weekdays,
            status: .active, nextRunDate: next, deliveries: [], createdAt: .now
        )
        subscriptions.insert(sub, at: 0)
        subsTick += 1
        pushNotification(.init(kind: .generic, title: "Subscription started 🔁",
            body: "\(sub.title) · \(sub.scheduleText). We'll deliver & auto-pay from Blinkit Money."),
            banner: true)
        startSubTask(id)
        showCreateSubscription = false
    }

    private func nextRunDate(after date: Date, hour: Int, minute: Int,
                             weekdays: Set<Int>, endDate: Date) -> Date {
        let cal = Calendar.current
        for offset in 0..<400 {
            guard let day = cal.date(byAdding: .day, value: offset, to: date) else { break }
            var comps = cal.dateComponents([.year, .month, .day], from: day)
            comps.hour = hour; comps.minute = minute
            guard let candidate = cal.date(from: comps) else { continue }
            if candidate < date { continue }
            if candidate > endDate { break }
            if weekdays.contains(cal.component(.weekday, from: candidate)) { return candidate }
        }
        return date
    }

    private func startSubTask(_ id: String) {
        subTasks[id]?.cancel()
        subTasks[id] = Task { [weak self] in
            try? await Task.sleep(for: .seconds(self?.demoFirstRunSeconds ?? 6))
            while true {
                guard let self,
                      let sub = self.subscriptions.first(where: { $0.id == id }),
                      sub.status == .active else { return }
                self.fireDelivery(id)
                try? await Task.sleep(for: .seconds(self.demoDaySeconds))
            }
        }
    }

    /// Runs one delivery for a subscription (auto-paid from the wallet).
    func fireDelivery(_ id: String) {
        guard let idx = subscriptions.firstIndex(where: { $0.id == id }) else { return }
        var sub = subscriptions[idx]
        guard sub.status == .active else { return }
        let amount = sub.perDeliveryTotal

        // Insufficient balance → fail this run and pause.
        if walletBalance < amount {
            sub.deliveries.insert(SubDelivery(date: .now, status: .failed, amount: amount), at: 0)
            sub.status = .paused
            subscriptions[idx] = sub
            subsTick += 1
            subTasks[id]?.cancel()
            pushNotification(.init(kind: .returnUpdate, title: "Subscription paused — low balance",
                body: "Add money to Blinkit Money to resume \(sub.title). Needed \(rupees(amount))."), banner: true)
            return
        }

        walletBalance -= amount
        let order = Order(
            id: "ORD" + String(Int.random(in: 10000...99999)),
            items: sub.items,
            bill: Bill(items: sub.items),
            placedByName: currentUser.name,
            isGroupOrder: false,
            isRecurring: true,
            participants: [currentUser],
            placedAt: .now,
            stage: .preparing
        )
        activeOrder = order
        startTrackingSimulation()

        sub.deliveries.insert(SubDelivery(date: .now, status: .delivered, amount: amount, orderID: order.id), at: 0)
        // Advance to the next scheduled day.
        let cal = Calendar.current
        let tomorrow = cal.date(byAdding: .day, value: 1, to: sub.nextRunDate) ?? sub.nextRunDate
        sub.nextRunDate = nextRunDate(after: tomorrow, hour: sub.hour, minute: sub.minute,
                                      weekdays: sub.weekdays, endDate: sub.endDate)
        if sub.nextRunDate > sub.endDate || sub.nextRunDate == tomorrow && tomorrow > sub.endDate {
            sub.status = .ended
            subTasks[id]?.cancel()
        }
        subscriptions[idx] = sub
        subsTick += 1

        let names = sub.items.prefix(3).map { $0.product.name }.joined(separator: ", ")
        pushNotification(.init(kind: .orderPlaced, title: "Recurring order placed 🔁",
            body: "\(names) · \(rupees(amount)) auto-paid from Blinkit Money. Arriving soon."), banner: true)
    }

    func pauseSubscription(_ id: String) {
        updateSub(id) { $0.status = .paused }
        subTasks[id]?.cancel()
    }

    func resumeSubscription(_ id: String) {
        guard let sub = subscriptions.first(where: { $0.id == id }) else { return }
        guard sub.endDate > .now else { updateSub(id) { $0.status = .ended }; return }
        updateSub(id) { s in
            s.status = .active
            s.nextRunDate = nextRunDate(after: .now, hour: s.hour, minute: s.minute,
                                        weekdays: s.weekdays, endDate: s.endDate)
        }
        startSubTask(id)
    }

    func cancelSubscription(_ id: String) {
        updateSub(id) { $0.status = .cancelled }
        subTasks[id]?.cancel()
        subTasks[id] = nil
    }

    func skipNextDelivery(_ id: String) {
        updateSub(id) { s in
            s.deliveries.insert(SubDelivery(date: s.nextRunDate, status: .skipped, amount: s.perDeliveryTotal), at: 0)
            let cal = Calendar.current
            let tomorrow = cal.date(byAdding: .day, value: 1, to: s.nextRunDate) ?? s.nextRunDate
            s.nextRunDate = self.nextRunDate(after: tomorrow, hour: s.hour, minute: s.minute,
                                             weekdays: s.weekdays, endDate: s.endDate)
        }
        pushNotification(.init(kind: .generic, title: "Next delivery skipped",
            body: "We'll resume on your following scheduled day."), banner: false)
    }

    func addMoney(_ amount: Double) {
        walletBalance += amount
        pushNotification(.init(kind: .generic, title: "Blinkit Money added",
            body: "\(rupees(amount)) added. New balance \(rupees(walletBalance))."), banner: true)
    }

    private func updateSub(_ id: String, _ change: (inout Subscription) -> Void) {
        guard let idx = subscriptions.firstIndex(where: { $0.id == id }) else { return }
        var sub = subscriptions[idx]
        change(&sub)
        subscriptions[idx] = sub
        subsTick += 1
    }

    var activeSubscriptionCount: Int { subscriptions.filter { $0.status == .active }.count }

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
        if isLiveSession { multipeer.send(.returnUpdate(req)) }
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
                if self.isLiveSession { self.multipeer.send(.returnUpdate(self.returns[idx])) }
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
