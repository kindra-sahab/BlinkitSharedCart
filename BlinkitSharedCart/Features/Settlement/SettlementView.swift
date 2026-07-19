//
//  SettlementView.swift
//  BlinkitSharedCart
//
//  "Who owes whom" after a group order — the host paid the whole bill, so each
//  friend owes back their items + an equal share of the fees.
//

import SwiftUI

struct SettlementView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if let s = app.settlement {
                    content(s)
                } else {
                    Text("No group order to settle").foregroundStyle(Palette.inkSecondary)
                }
            }
            .background(Palette.background)
            .navigationTitle("Split & Settle Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.brandDark)
                }
            }
        }
    }

    @ViewBuilder
    private func content(_ s: Settlement) -> some View {
        let iAmHost = app.currentUser.id == s.host.id
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                heroCard(s, iAmHost: iAmHost)

                VStack(alignment: .leading, spacing: 10) {
                    Text(iAmHost ? "Collect from friends" : "Everyone's share")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.ink)
                    ForEach(s.dues) { due in
                        DueRow(due: due, host: s.host, meID: app.currentUser.id)
                    }
                }
                .cardStyle()
                .padding(.horizontal, 16)

                howItWorks(s)
                Color.clear.frame(height: 40)
            }
            .padding(.top, 8)
        }
    }

    private func heroCard(_ s: Settlement, iAmHost: Bool) -> some View {
        VStack(spacing: 10) {
            if iAmHost {
                Text("You paid the full bill").font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                Text(rupees(s.totalReceivable))
                    .font(.system(size: 34, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                Text("is owed to you by \(s.receivables.count) \(s.receivables.count == 1 ? "friend" : "friends")")
                    .font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.9))
            } else {
                Text("You owe \(s.host.name)").font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                Text(rupees(s.amountOwed(by: app.currentUser.id)))
                    .font(.system(size: 34, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                Text("for your items + your share of fees")
                    .font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.9))
            }
            if !iAmHost {
                Button {
                    Haptics.pop()
                } label: {
                    Label("Pay \(s.host.name) via UPI", systemImage: "indianrupeesign.circle.fill")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.brandDark)
                        .padding(.horizontal, 18).frame(height: 44)
                        .background(.white, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(LinearGradient.group)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 16)
    }

    private func howItWorks(_ s: Settlement) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill").foregroundStyle(Palette.inkTertiary)
            Text("Each person pays for their own items plus an equal split of the \(rupees(s.feesTotal)) fees. Free delivery means no delivery fee to split 🎉")
                .font(.system(size: 11, design: .rounded)).foregroundStyle(Palette.inkTertiary)
        }
        .padding(14)
        .background(Palette.tile, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
    }
}

struct DueRow: View {
    let due: Settlement.Due
    let host: Participant
    let meID: String

    private var isHost: Bool { due.participant.id == host.id }
    private var isMe: Bool { due.participant.id == meID }

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(participant: due.participant, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(isMe ? "You" : due.participant.name)
                        .font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink)
                    if isHost {
                        Label("Host · paid", systemImage: "crown.fill")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundStyle(Palette.accent)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Palette.accentSoft, in: Capsule())
                    }
                }
                Text("Items \(rupees(due.itemsTotal)) + fees \(rupees(due.feeShare))")
                    .font(.system(size: 11, design: .rounded)).foregroundStyle(Palette.inkSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text(rupees(due.total)).font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.ink)
                Text(isHost ? "settled" : "owes host")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(isHost ? Palette.success : Palette.warning)
            }
        }
        .padding(.vertical, 4)
    }
}
