//
//  CreateSubscriptionView.swift
//  BlinkitSharedCart
//

import SwiftUI

struct CreateSubscriptionView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var title = "Morning Essentials"
    @State private var quantities: [String: Int] = [
        "p_milk": 1, "p_mushroom": 1, "p_coriander": 1
    ]
    @State private var preset: SubFrequencyPreset = .everyday
    @State private var customDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var time = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()

    private var selectedItems: [CartItem] {
        MockCatalog.morningEssentials.compactMap { p in
            guard let q = quantities[p.id], q > 0 else { return nil }
            return CartItem(product: p, quantity: q, addedBy: .me)
        }
    }
    private var subtotal: Double { selectedItems.reduce(0) { $0 + $1.lineTotal } }
    private var perDelivery: Double { subtotal + (selectedItems.isEmpty ? 0 : Pricing.handlingFee) }
    private var weekdays: Set<Int> { preset == .custom ? customDays : preset.days }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    hero
                    itemsSection
                    frequencySection
                    scheduleSection
                    summary
                    Color.clear.frame(height: 110)
                }
                .padding(.top, 6)
            }
            .background(Palette.background)
            .navigationTitle("Recurring Delivery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Palette.inkSecondary)
                }
            }
            .safeAreaInset(edge: .bottom) { startBar }
        }
    }

    private var hero: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(LinearGradient.brand).frame(width: 60, height: 60)
                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                    .font(.system(size: 24, weight: .bold)).foregroundStyle(.white)
            }
            Text("Set it once, get it daily")
                .font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(Palette.ink)
            Text("Same items, delivered on schedule, auto-paid from Blinkit Money. Cancel anytime.")
                .font(.system(size: 13, design: .rounded)).foregroundStyle(Palette.inkSecondary)
                .multilineTextAlignment(.center).padding(.horizontal, 30)
        }
    }

    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("What to deliver", "Tap to add your everyday items")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(MockCatalog.morningEssentials) { product in
                    itemChip(product)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func itemChip(_ product: Product) -> some View {
        let qty = quantities[product.id] ?? 0
        let selected = qty > 0
        return HStack(spacing: 10) {
            ProductImageView(product: product, size: 42, showEta: false)
            VStack(alignment: .leading, spacing: 1) {
                Text(product.name).font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.ink).lineLimit(1)
                Text(rupees(product.price)).font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.inkSecondary)
            }
            Spacer(minLength: 0)
            if selected {
                Text("\(qty)").font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.brandDark)
                    .frame(width: 22, height: 22)
                    .background(Palette.brandSoft, in: Circle())
            } else {
                Image(systemName: "plus").font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Palette.brandDark)
            }
        }
        .padding(8)
        .background(selected ? Palette.brandSoft : Color.white, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(selected ? Palette.brand.opacity(0.5) : Palette.hairline, lineWidth: 1.2))
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.tap()
            quantities[product.id] = (quantities[product.id] ?? 0) >= 3 ? 0 : (quantities[product.id] ?? 0) + 1
        }
    }

    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("How often", nil)
            HStack(spacing: 8) {
                ForEach(SubFrequencyPreset.allCases) { p in
                    Button {
                        withAnimation(.spring) { preset = p }
                    } label: {
                        Text(p.rawValue)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(preset == p ? .white : Palette.ink)
                            .padding(.horizontal, 12).frame(height: 36)
                            .background(preset == p ? AnyShapeStyle(LinearGradient.brand) : AnyShapeStyle(Color.white),
                                        in: Capsule())
                            .overlay(Capsule().stroke(Palette.hairline, lineWidth: preset == p ? 0 : 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            if preset == .custom {
                HStack(spacing: 6) {
                    ForEach(1...7, id: \.self) { day in
                        let names = ["", "S", "M", "T", "W", "T", "F", "S"]
                        let on = customDays.contains(day)
                        Button {
                            if on { customDays.remove(day) } else { customDays.insert(day) }
                        } label: {
                            Text(names[day])
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(on ? .white : Palette.inkSecondary)
                                .frame(width: 38, height: 38)
                                .background(on ? Palette.brand : Palette.tile, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("When", nil)
            VStack(spacing: 0) {
                DatePicker("Delivery time", selection: $time, displayedComponents: .hourAndMinute)
                Divider()
                DatePicker("Starts", selection: $startDate, in: Date()..., displayedComponents: .date)
                Divider()
                DatePicker("Ends", selection: $endDate, in: startDate..., displayedComponents: .date)
            }
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .tint(Palette.brand)
            .padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.hairline, lineWidth: 1))
        }
        .padding(.horizontal, 16)
    }

    private var summary: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Per delivery").font(.system(size: 13, design: .rounded)).foregroundStyle(Palette.inkSecondary)
                Spacer()
                Text(rupees(perDelivery)).font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.ink)
            }
            HStack {
                Label("FREE delivery on every order", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(Palette.success)
                Spacer()
            }
            Divider()
            HStack(spacing: 8) {
                Image(systemName: "wallet.bifold.fill").foregroundStyle(Palette.brandDark)
                Text("Auto-pay from Blinkit Money")
                    .font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(Palette.ink)
                Spacer()
                Text("Bal \(rupees(app.walletBalance))")
                    .font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(Palette.inkSecondary)
            }
        }
        .cardStyle().padding(.horizontal, 16)
    }

    private var startBar: some View {
        PrimaryButton(title: "Start Subscription",
                      subtitle: selectedItems.isEmpty ? "Add at least one item" : "\(selectedItems.count) items · \(perDelivery > 0 ? rupees(perDelivery) : "")/delivery",
                      icon: "arrow.trianglehead.2.clockwise.rotate.90",
                      enabled: !selectedItems.isEmpty) {
            let c = Calendar.current.dateComponents([.hour, .minute], from: time)
            app.createSubscription(title: title, items: selectedItems, startDate: startDate,
                                   endDate: endDate, hour: c.hour ?? 8, minute: c.minute ?? 0, weekdays: weekdays)
            dismiss()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(.white)
        .overlay(Rectangle().fill(Palette.hairline).frame(height: 1), alignment: .top)
    }

    private func sectionTitle(_ title: String, _ subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title).font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(Palette.ink)
            if let subtitle {
                Text(subtitle).font(.system(size: 12, design: .rounded)).foregroundStyle(Palette.inkSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
