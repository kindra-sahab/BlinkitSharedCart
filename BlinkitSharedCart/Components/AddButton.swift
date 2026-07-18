//
//  AddButton.swift
//  BlinkitSharedCart
//
//  The signature ADD → quantity-stepper control.
//

import SwiftUI

struct AddButton: View {
    let quantity: Int
    var compact: Bool = false
    let onAdd: () -> Void
    let onIncrement: () -> Void
    let onDecrement: () -> Void

    var body: some View {
        Group {
            if quantity == 0 {
                Button(action: tapAdd) {
                    Text("ADD")
                        .font(.system(size: compact ? 13 : 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.brandDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: compact ? 30 : 34)
                        .background(Palette.brandSoft, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(Palette.brand.opacity(0.55), lineWidth: 1.2)
                        )
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 0) {
                    stepButton("minus", action: onDecrement)
                    Text("\(quantity)")
                        .font(.system(size: compact ? 14 : 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .contentTransition(.numericText())
                    stepButton("plus", action: onIncrement)
                }
                .frame(height: compact ? 30 : 34)
                .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            }
        }
        .frame(width: compact ? 92 : 100)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: quantity)
    }

    private func tapAdd() {
        Haptics.tap()
        onAdd()
    }

    private func stepButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: compact ? 11 : 12, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 30, height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
