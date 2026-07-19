//
//  RealtimeService.swift
//  BlinkitSharedCart
//
//  Mock realtime backend for the shared cart. Stands in for Firebase Firestore:
//  every mutation "broadcasts" by updating the observed `session`, and simulated
//  friends act on their own timers to create a live, multiplayer feel.
//

import SwiftUI
import Observation

/// A single entry in the live group activity feed.
struct GroupActivity: Identifiable {
    let id = UUID()
    let participantName: String
    let colorHex: UInt
    let text: String
    let date: Date = .now
}

/// A transient toast surfaced when something happens in the shared cart.
struct GroupToast: Identifiable, Equatable {
    let id = UUID()
    let emoji: String
    let text: String
}

@Observable
@MainActor
final class RealtimeService {

    // Live, observed session state — the "document" every client watches.
    private(set) var session: GroupSession?
    private(set) var activities: [GroupActivity] = []

    // Ephemeral UI signals
    var toast: GroupToast?
    var celebrate: Bool = false
    private(set) var now: Date = .now

    // Hooks the app layer uses to react (post notifications, etc.)
    var onFriendActivity: ((GroupActivity) -> Void)?
    var onFreeDeliveryUnlocked: (() -> Void)?

    private var clockTask: Task<Void, Never>?
    private var botTasks: [Task<Void, Never>] = []
    private var didUnlock = false

    // MARK: - Session lifecycle

    @discardableResult
    func createSession(host: Participant, seededWith items: [CartItem], minutes: Int = 15) -> GroupSession {
        teardown()
        var host = host
        host.isHost = true
        host.isOnline = true
        let session = GroupSession(
            id: "grp_" + UUID().uuidString.prefix(6),
            inviteCode: Self.randomCode(),
            hostID: host.id,
            participants: [host],
            items: items,
            status: .active,
            createdAt: .now,
            expiresAt: Date().addingTimeInterval(TimeInterval(minutes * 60))
        )
        self.session = session
        self.activities = [GroupActivity(
            participantName: host.name, colorHex: host.colorHex,
            text: "started a group order"
        )]
        didUnlock = session.bill.freeDeliveryUnlocked
        startClock()
        return session
    }

    func endSession() { teardown() }

    private func teardown() {
        clockTask?.cancel(); clockTask = nil
        botTasks.forEach { $0.cancel() }; botTasks.removeAll()
        session = nil
        activities = []
        celebrate = false
        didUnlock = false
    }

    // MARK: - Participants

    /// A friend accepts the invite and enters the shared cart.
    func join(_ friend: Participant, autoContribute: Bool = true) {
        guard var s = session, !s.participants.contains(where: { $0.id == friend.id }) else { return }
        var friend = friend
        friend.isOnline = true
        s.participants.append(friend)
        session = s
        pushActivity(name: friend.name, color: friend.colorHex, text: "joined the order", broadcast: true)
        toast = GroupToast(emoji: friend.avatarEmoji, text: "\(friend.firstName) joined the order")
        if autoContribute { scheduleBotContributions(for: friend) }
    }

    func setBrowsing(_ participantID: String, _ browsing: Bool) {
        guard var s = session, let idx = s.participants.firstIndex(where: { $0.id == participantID }) else { return }
        s.participants[idx].isBrowsing = browsing
        session = s
    }

    // MARK: - Cart mutations (broadcast to everyone)

    func addItem(_ product: Product, by participant: Participant, animated: Bool = true) {
        guard var s = session else { return }
        if let idx = s.items.firstIndex(where: { $0.product.id == product.id && $0.addedByID == participant.id }) {
            s.items[idx].quantity += 1
        } else {
            s.items.append(.group(product, addedBy: participant))
        }
        session = s
        if animated {
            toast = GroupToast(emoji: product.emoji, text: "\(participant.firstName) added \(product.name)")
        }
        pushActivity(name: participant.name, color: participant.colorHex,
                     text: "added \(product.name)", broadcast: participant.id != Participant.me.id)
        checkUnlock()
    }

    /// Product-keyed change (used by catalogue "ADD" / steppers). Keyed by
    /// (product, participant) so ids never need to match across devices.
    func changeProductQuantity(_ product: Product, by participant: Participant, delta: Int) {
        guard var s = session else { return }
        if let idx = s.items.firstIndex(where: { $0.product.id == product.id && $0.addedByID == participant.id }) {
            s.items[idx].quantity += delta
            if s.items[idx].quantity <= 0 {
                s.items.remove(at: idx)
            } else if delta > 0 {
                toast = GroupToast(emoji: product.emoji, text: "\(participant.firstName) added \(product.name)")
            }
        } else if delta > 0 {
            s.items.append(.group(product, addedBy: participant))
            toast = GroupToast(emoji: product.emoji, text: "\(participant.firstName) added \(product.name)")
            pushActivity(name: participant.name, color: participant.colorHex,
                         text: "added \(product.name)", broadcast: participant.id != Participant.me.id)
        }
        session = s
        checkUnlock()
    }

    func changeQuantity(itemID: String, delta: Int, by participant: Participant) {
        guard var s = session, let idx = s.items.firstIndex(where: { $0.id == itemID }) else { return }
        guard canEdit(s.items[idx], as: participant) else { return }
        s.items[idx].quantity += delta
        if s.items[idx].quantity <= 0 { s.items.remove(at: idx) }
        session = s
        checkUnlock()
    }

    func removeItem(itemID: String, by participant: Participant) {
        guard var s = session, let item = s.items.first(where: { $0.id == itemID }) else { return }
        guard canEdit(item, as: participant) else { return }
        s.items.removeAll { $0.id == itemID }
        session = s
        checkUnlock()
    }

    /// A participant may only edit items they added. The host may edit anything.
    func canEdit(_ item: CartItem, as participant: Participant) -> Bool {
        participant.isHost || item.addedByID == participant.id
    }

    func markPlacing() { session?.status = .placing }

    func markPlaced() {
        session?.status = .placed
        botTasks.forEach { $0.cancel() }; botTasks.removeAll()
    }

    // MARK: - Free delivery celebration

    private func checkUnlock() {
        guard let s = session else { return }
        let unlocked = s.bill.freeDeliveryUnlocked
        if unlocked && !didUnlock {
            didUnlock = true
            triggerCelebration()
            toast = GroupToast(emoji: "🎉", text: "Free Delivery Unlocked!")
            onFreeDeliveryUnlocked?()
            pushActivity(name: "Everyone", color: 0x0FA958, text: "unlocked free delivery 🎉", broadcast: false)
        } else if !unlocked {
            didUnlock = false
        }
    }

    private func triggerCelebration() {
        celebrate = true
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            self?.celebrate = false
        }
    }

    // MARK: - Remote state (guest mirror)

    /// Apply an authoritative snapshot received from the host, deriving a local
    /// activity feed / toast / celebration from the delta versus what we had.
    func applyRemoteState(_ incoming: GroupSession) {
        if let old = session {
            let oldParticipants = Set(old.participants.map { $0.id })
            for p in incoming.participants where !oldParticipants.contains(p.id) && p.id != Participant.me.id {
                activities.append(GroupActivity(participantName: p.name, colorHex: p.colorHex, text: "joined the order"))
                toast = GroupToast(emoji: p.avatarEmoji, text: "\(p.firstName) joined the order")
            }
            let oldItems = Set(old.items.map { $0.id })
            for item in incoming.items where !oldItems.contains(item.id) {
                let who = incoming.participant(item.addedByID)
                let name = who?.firstName ?? item.addedByName
                activities.append(GroupActivity(participantName: name, colorHex: who?.colorHex ?? 0x9AA4AF,
                                                text: "added \(item.product.name)"))
                toast = GroupToast(emoji: item.product.emoji, text: "\(name) added \(item.product.name)")
            }
        }
        session = incoming
        let unlocked = incoming.bill.freeDeliveryUnlocked
        if unlocked && !didUnlock {
            didUnlock = true
            triggerCelebration()
            toast = GroupToast(emoji: "🎉", text: "Free Delivery Unlocked!")
            onFreeDeliveryUnlocked?()
        } else if !unlocked {
            didUnlock = false
        }
        if clockTask == nil { startClock() }
    }

    // MARK: - Activity feed

    private func pushActivity(name: String, color: UInt, text: String, broadcast: Bool) {
        let a = GroupActivity(participantName: name, colorHex: color, text: text)
        activities.append(a)
        if broadcast { onFriendActivity?(a) }
    }

    // MARK: - Simulated friend behaviour (bots)

    private func scheduleBotContributions(for friend: Participant) {
        let count = Int.random(in: 1...2)
        let task = Task { [weak self] in
            for i in 0..<count {
                let browseDelay = Double.random(in: 2.5...5.5)
                try? await Task.sleep(for: .seconds(browseDelay))
                guard let self, self.session?.status == .active else { return }
                self.setBrowsing(friend.id, true)

                try? await Task.sleep(for: .seconds(Double.random(in: 1.5...3.0)))
                guard self.session?.status == .active else { return }
                self.setBrowsing(friend.id, false)

                let product = MockCatalog.botPicks.randomElement()!
                self.addItem(product, by: friend)
                if i < count - 1 { try? await Task.sleep(for: .seconds(Double.random(in: 3...6))) }
            }
        }
        botTasks.append(task)
    }

    // MARK: - Countdown clock

    private func startClock() {
        clockTask?.cancel()
        clockTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.now = .now
                if let s = self?.session, s.status == .active, Date() >= s.expiresAt {
                    self?.session?.status = .expired
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    var timeRemaining: TimeInterval {
        guard let s = session else { return 0 }
        return max(0, s.expiresAt.timeIntervalSince(now))
    }

    // MARK: - Helpers

    private static func randomCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}
