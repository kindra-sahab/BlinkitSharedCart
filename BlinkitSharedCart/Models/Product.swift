//
//  Product.swift
//  BlinkitSharedCart
//

import SwiftUI

struct Category: Identifiable, Hashable {
    let id: String
    let name: String
    let emoji: String
    let tint: UInt   // hex tint for the tile background wash
}

struct Product: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let emoji: String
    let unit: String          // e.g. "500 ml", "1 pack"
    let price: Double
    let mrp: Double
    let categoryID: String
    let etaMinutes: Int

    var hasDiscount: Bool { mrp > price }
    var discountPercent: Int {
        guard mrp > price, mrp > 0 else { return 0 }
        return Int(((mrp - price) / mrp * 100).rounded())
    }

    /// Pastel wash behind the emoji, derived from the product name for stable variety.
    var tileTint: Color {
        let palette: [UInt] = [0xEAF2F1, 0xFFF1DC, 0xEFEBFF, 0xE4F7EC, 0xFFE9EF, 0xE6F3FB]
        let idx = abs(name.hashValue) % palette.count
        return Color(hex: palette[idx])
    }
}
