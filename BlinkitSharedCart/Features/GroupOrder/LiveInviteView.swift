//
//  LiveInviteView.swift
//  BlinkitSharedCart
//
//  The invite that pops on the GUEST phone when a nearby host starts a group
//  order. Mirrors the real push banner with Join / Ignore actions.
//

import SwiftUI

struct LiveInviteView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    let invite: LiveInvite

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 18) {
                ZStack {
                    Circle().fill(LinearGradient.group).frame(width: 92, height: 92)
                    Text(invite.hostEmoji).font(.system(size: 44))
                }
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 20)).foregroundStyle(Palette.accent)
                        .background(Circle().fill(.white).frame(width: 30, height: 30))
                        .offset(x: 6, y: -2)
                }

                VStack(spacing: 8) {
                    Text("\(invite.hostName) is placing a Zipp order")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)
                    Text(invite.remaining > 0
                         ? "Only \(rupees(invite.remaining)) more is needed to unlock FREE delivery. Want to add something?"
                         : "You're invited to a shared group cart. Add whatever you need!")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(Palette.inkSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Guest must have a non-host identity to join.
                if !app.canJoinLive {
                    IdentityPickerInline()
                        .padding(.horizontal, 20)
                }

                VStack(spacing: 10) {
                    PrimaryButton(title: "Join Order", icon: "cart.fill.badge.plus",
                                  gradient: .group, enabled: app.canJoinLive) {
                        app.acceptLiveInvite()
                        dismiss()
                    }
                    Button("Ignore") {
                        app.ignoreLiveInvite()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.inkSecondary)
                }
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 30)
            .frame(maxWidth: .infinity)
            .background(.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .padding(.horizontal, 14)
            Spacer()
        }
        .background(.black.opacity(0.001))
        .presentationBackground(.ultraThinMaterial)
        .presentationDetents([.large])
    }
}

/// Compact identity chooser shown when the guest is still using the host identity.
struct IdentityPickerInline: View {
    @Environment(AppState.self) private var app

    var body: some View {
        VStack(spacing: 8) {
            Text("First, who are you on this phone?")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.warning)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Participant.friendRoster) { p in
                        Button { app.setIdentity(p) } label: {
                            VStack(spacing: 4) {
                                AvatarView(participant: p, size: 40)
                                Text(p.firstName).font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(Palette.ink)
                            }
                            .padding(8)
                            .background(app.currentUser.id == p.id ? Palette.brandSoft : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(12)
        .background(Palette.accentSoft, in: RoundedRectangle(cornerRadius: 14))
    }
}
