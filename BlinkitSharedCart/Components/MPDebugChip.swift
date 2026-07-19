//
//  MPDebugChip.swift
//  BlinkitSharedCart
//
//  Live Multipeer diagnostics so you can SEE whether data is crossing the link:
//  connected peer count, sent/received counters, and the last message type.
//  Tap to hide.
//

import SwiftUI

struct MPDebugChip: View {
    @Environment(AppState.self) private var app
    @State private var hidden = false

    var body: some View {
        if hidden {
            EmptyView()
        } else {
            let mp = app.multipeer
            HStack(spacing: 8) {
                Circle().fill(mp.isConnected ? Palette.success : Palette.danger)
                    .frame(width: 7, height: 7)
                Text("peers \(mp.connectedCount)")
                Text("↑\(mp.txCount) \(mp.lastTx)")
                Text("↓\(mp.rxCount) \(mp.lastRx)")
                if !mp.lastError.isEmpty {
                    Text("⚠️").help(mp.lastError)
                }
            }
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Capsule().fill(.black.opacity(0.8)))
            .onTapGesture { hidden = true }
        }
    }
}
