//
//  InviteFriendsView.swift
//  BlinkitSharedCart
//

import SwiftUI

struct InviteFriendsView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<String> = [Participant.rahul.id, Participant.aman.id]

    private var roster: [Participant] { Participant.friendRoster }
    private var remaining: Double { app.personalBill.amountToFreeDelivery }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                    nearbyLiveCard
                    demoFriendsSection
                    shareLinkRow
                    Color.clear.frame(height: 100)
                }
                .padding(.top, 8)
            }
            .background(Palette.background)
            .navigationTitle("Invite to Group Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Palette.inkSecondary)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(LinearGradient.group).frame(width: 66, height: 66)
                Image(systemName: "person.2.badge.plus.fill")
                    .font(.system(size: 26)).foregroundStyle(.white)
            }
            Text("You'll be the Host")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.ink)
            Text(remaining > 0
                 ? "Everyone adds to one cart. Only \(rupees(remaining)) more unlocks FREE delivery — split it together!"
                 : "Everyone adds to one cart and shares a single delivery.")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(Palette.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.top, 8)
    }

    // MARK: Live (real two-phone) section

    private var nearbyLiveCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .foregroundStyle(.white)
                Text("LIVE · NEARBY DEVICES").tracking(1)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                connectionPill
            }

            Text(app.multipeer.isConnected
                 ? "\(app.multipeer.connectedCount) phone\(app.multipeer.connectedCount == 1 ? "" : "s") connected nearby. Start now — they'll get the invite instantly."
                 : "Start anytime. Friends get the invite the moment they open Zipp nearby (same WiFi / Bluetooth on).")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))
                .fixedSize(horizontal: false, vertical: true)

            Button {
                app.startLiveGroupOrder()
            } label: {
                HStack {
                    Image(systemName: "paperplane.fill")
                    Text("Start Live Group Order & Notify")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.violet)
                .padding(.horizontal, 14).frame(height: 46)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(LinearGradient.group, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .softShadow(18, y: 10, opacity: 0.2)
        .padding(.horizontal, 16)
    }

    private var connectionPill: some View {
        HStack(spacing: 5) {
            Circle().fill(app.multipeer.isConnected ? Palette.success : Palette.accent)
                .frame(width: 7, height: 7)
            Text(app.multipeer.isConnected ? "Connected" : "Searching")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(.white.opacity(0.15), in: Capsule())
    }

    private var demoFriendsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Or simulate with demo friends")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.inkSecondary)
                Spacer()
                Text("single device")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.inkTertiary)
            }
            ForEach(roster) { friend in
                FriendRow(friend: friend, isSelected: selected.contains(friend.id)) {
                    toggle(friend)
                }
            }
            PrimaryButton(
                title: "Start Simulated Group Order",
                subtitle: selected.isEmpty ? "Select at least one demo friend" : "Invite \(selected.count) simulated friend\(selected.count == 1 ? "" : "s")",
                icon: "person.2.fill",
                gradient: .brand,
                enabled: !selected.isEmpty
            ) {
                let friends = roster.filter { selected.contains($0.id) }
                app.startGroupOrder(inviting: friends)
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 16)
    }

    private var shareLinkRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "link").foregroundStyle(Palette.brandDark)
                .frame(width: 38, height: 38).background(Palette.brandSoft, in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text("Share invite link").font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                Text("zipp.app/join/GRP-7K2QX").font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Palette.inkSecondary)
            }
            Spacer()
            Image(systemName: "square.and.arrow.up").foregroundStyle(Palette.brandDark)
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.hairline, lineWidth: 1))
        .padding(.horizontal, 16)
    }

    private func toggle(_ friend: Participant) {
        Haptics.tap()
        if selected.contains(friend.id) { selected.remove(friend.id) }
        else { selected.insert(friend.id) }
    }
}

struct FriendRow: View {
    let friend: Participant
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AvatarView(participant: friend, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.name).font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.ink)
                    Text(friend.isOnline ? "Active now" : "Last seen recently")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(friend.isOnline ? Palette.success : Palette.inkTertiary)
                }
                Spacer()
                ZStack {
                    Circle().stroke(isSelected ? Palette.brand : Palette.hairline, lineWidth: 2)
                        .frame(width: 26, height: 26)
                    if isSelected {
                        Circle().fill(Palette.brand).frame(width: 26, height: 26)
                        Image(systemName: "checkmark").font(.system(size: 12, weight: .black))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(12)
            .background(.white, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Palette.brand.opacity(0.5) : Palette.hairline, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}
