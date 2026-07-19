//
//  WalletSheet.swift
//  BlinkitSharedCart
//

import SwiftUI

struct WalletSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    private var deductions: [SubDelivery] {
        app.subscriptions.flatMap { $0.deliveries }
            .filter { $0.status == .delivered }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    balanceHero
                    HStack(spacing: 10) {
                        addButton(200); addButton(500); addButton(1000)
                    }.padding(.horizontal, 16)

                    if !deductions.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recent auto-payments")
                                .font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(Palette.ink)
                            ForEach(deductions.prefix(8)) { d in
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                                        .foregroundStyle(Palette.brandDark).frame(width: 20)
                                    Text("Recurring order").font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundStyle(Palette.ink)
                                    Spacer()
                                    Text("-\(rupees(d.amount))").font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(Palette.ink)
                                }
                            }
                        }
                        .cardStyle().padding(.horizontal, 16)
                    }
                    Color.clear.frame(height: 30)
                }
                .padding(.top, 8)
            }
            .background(Palette.background)
            .navigationTitle("Blinkit Money")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.tint(Palette.brandDark)
                }
            }
        }
    }

    private var balanceHero: some View {
        VStack(spacing: 6) {
            Text("Available balance").font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
            Text(rupees(app.walletBalance)).font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text("Used to auto-pay your recurring deliveries")
                .font(.system(size: 12, design: .rounded)).foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 26)
        .background(LinearGradient.brand)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 16)
    }

    private func addButton(_ amount: Double) -> some View {
        Button { app.addMoney(amount) } label: {
            Text("+ \(rupees(amount))").font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.brandDark)
                .frame(maxWidth: .infinity).frame(height: 46)
                .background(Palette.brandSoft, in: RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain)
    }
}
