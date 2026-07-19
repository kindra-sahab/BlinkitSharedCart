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

    func start() {
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }

    func stop() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        mcSession.disconnect()
    }

    func send(_ message: SyncMessage) {
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
        connectedCount = count
        onPeersChanged?(count)
        print("[MPC] 🔗 connected peers = \(count)")
    }

    fileprivate func deliver(_ data: Data) {
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
