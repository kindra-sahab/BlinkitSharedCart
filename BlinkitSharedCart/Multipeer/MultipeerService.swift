//
//  MultipeerService.swift
//  BlinkitSharedCart
//
//  Real cross-device transport using MultipeerConnectivity (WiFi/Bluetooth,
//  no server). Auto-discovers and connects nearby phones running the app,
//  then ships `SyncMessage`s between them. This is the real replacement for
//  the simulated friends in a live two-phone demo.
//

import Foundation
import MultipeerConnectivity

@MainActor
@Observable
final class MultipeerService: NSObject {

    static let serviceType = "zipp-group"   // must be 1–15 chars, lowercase + hyphen

    // Observed connection state (drives the "connected" UI).
    private(set) var connectedCount: Int = 0
    var isConnected: Bool { connectedCount > 0 }
    private(set) var myName: String

    // Live diagnostics (surfaced in the on-screen debug chip).
    private(set) var lastRx: String = "—"
    private(set) var lastTx: String = "—"
    private(set) var lastError: String = ""
    private(set) var rxCount: Int = 0
    private(set) var txCount: Int = 0
    /// Last time ANY data arrived — used by the link watchdog to detect a
    /// zombie connection (looks connected, but nothing flows).
    private(set) var lastRxDate: Date = .now

    // Callbacks into the app layer.
    var onReceive: ((SyncMessage) -> Void)?
    var onPeersChanged: ((Int) -> Void)?

    // MC objects are touched from delegate callbacks on background queues, so
    // they're held as nonisolated references (standard bridging pattern).
    nonisolated(unsafe) private let mcSession: MCSession
    nonisolated(unsafe) private let advertiser: MCNearbyServiceAdvertiser
    nonisolated(unsafe) private let browser: MCNearbyServiceBrowser
    nonisolated(unsafe) private let peerID: MCPeerID

    init(displayName: String) {
        // Unique transport name so two phones never collide even if the human
        // identity (Rahul/Jatin) is the same. Real identity travels in payloads.
        let unique = "\(displayName)-\(UUID().uuidString.prefix(4))"
        myName = displayName
        let peer = MCPeerID(displayName: unique)
        peerID = peer
        mcSession = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .required)
        advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: Self.serviceType)
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: Self.serviceType)
        super.init()
        mcSession.delegate = self
        advertiser.delegate = self
        browser.delegate = self
    }

    /// True once stop() has been called — all further work is refused so a
    /// discarded (rebuilt) service can never fire zombie callbacks or restarts.
    private var isStopped = false
    private var restartTask: Task<Void, Never>?

    func start() {
        guard !isStopped else { return }
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }

    func stop() {
        isStopped = true
        restartTask?.cancel()
        onReceive = nil
        onPeersChanged = nil
        mcSession.delegate = nil
        advertiser.delegate = nil
        browser.delegate = nil
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        mcSession.disconnect()
    }

    func send(_ message: SyncMessage) {
        guard !isStopped else { return }
        let peers = mcSession.connectedPeers
        guard !peers.isEmpty else {
            print("[MPC] send \(message.debugLabel) skipped — no peers")
            return
        }
        do {
            let data = try JSONEncoder().encode(message)
            try mcSession.send(data, toPeers: peers, with: .reliable)
            lastTx = message.debugLabel
            txCount += 1
            print("[MPC] ⬆︎ sent \(message.debugLabel) to \(peers.count) peer(s)")
        } catch {
            lastError = "tx: \(error.localizedDescription)"
            print("[MPC] ⚠️ send error: \(error)")
        }
    }

    fileprivate func refreshPeers(_ count: Int) {
        guard !isStopped else { return }
        connectedCount = count
        lastRxDate = .now   // fresh link — give the watchdog a clean slate
        onPeersChanged?(count)
        print("[MPC] 🔗 connected peers = \(count)")
        // Link dropped — force a fresh discovery cycle so the phones re-pair
        // automatically instead of needing an app restart.
        if count == 0 { restartDiscovery() }
    }

    /// Gentle re-discovery after a disconnect: restart ONLY the browser, once,
    /// after a calm delay. (Aggressively cycling advertiser+browser+session
    /// objects triggers CoreFoundation type-assert crashes in MPC.)
    private func restartDiscovery() {
        guard !isStopped else { return }
        restartTask?.cancel()
        restartTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard let self, !self.isStopped, !Task.isCancelled else { return }
            self.browser.stopBrowsingForPeers()
            try? await Task.sleep(for: .seconds(1))
            guard !self.isStopped, !Task.isCancelled else { return }
            self.browser.startBrowsingForPeers()
            print("[MPC] 🔄 browser restarted")
        }
    }

    fileprivate func deliver(_ data: Data) {
        guard !isStopped else { return }
        lastRxDate = .now
        do {
            let message = try JSONDecoder().decode(SyncMessage.self, from: data)
            lastRx = message.debugLabel
            rxCount += 1
            print("[MPC] ⬇︎ received \(message.debugLabel)")
            onReceive?(message)
        } catch {
            lastError = "rx: \(error.localizedDescription)"
            print("[MPC] ⚠️ decode error: \(error)")
        }
    }
}

// MARK: - MCSessionDelegate

extension MultipeerService: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let count = session.connectedPeers.count
        Task { @MainActor in self.refreshPeers(count) }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in self.deliver(data) }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - Advertiser (auto-accept invitations)

extension MultipeerService: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                                didReceiveInvitationFromPeer peerID: MCPeerID,
                                withContext context: Data?,
                                invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, mcSession)
    }

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("[MPC] advertiser error: \(error)")
    }
}

// MARK: - Browser (auto-invite found peers with a tie-break)

extension MultipeerService: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        // Deterministic tie-break so only one side sends the invite.
        if self.peerID.displayName < peerID.displayName {
            browser.invitePeer(peerID, to: mcSession, withContext: nil, timeout: 15)
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("[MPC] browser error: \(error)")
    }
}
