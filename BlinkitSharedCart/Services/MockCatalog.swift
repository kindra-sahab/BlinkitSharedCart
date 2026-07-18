//
//  MockCatalog.swift
//  BlinkitSharedCart
//
//  Static mock catalogue standing in for a products API.
//

import Foundation

enum MockCatalog {
    static let categories: [Category] = [
        Category(id: "dairy",    name: "Dairy & Breakfast",   emoji: "🥛", tint: 0xEAF2F1),
        Category(id: "fruits",   name: "Fruits & Vegetables", emoji: "🥦", tint: 0xE4F7EC),
        Category(id: "snacks",   name: "Snacks & Munchies",   emoji: "🍿", tint: 0xFFF1DC),
        Category(id: "drinks",   name: "Cold Drinks & Juices",emoji: "🥤", tint: 0xE6F3FB),
        Category(id: "bakery",   name: "Bakery & Biscuits",   emoji: "🍞", tint: 0xFFE9EF),
        Category(id: "instant",  name: "Instant & Frozen",    emoji: "🍜", tint: 0xEFEBFF),
        Category(id: "hotdrinks",name: "Tea, Coffee & More",  emoji: "☕️", tint: 0xF3EDE6),
        Category(id: "personal", name: "Personal Care",       emoji: "🧴", tint: 0xE6F3FB),
        Category(id: "home",     name: "Home & Cleaning",     emoji: "🧽", tint: 0xEAF2F1),
        Category(id: "sweet",    name: "Sweet Tooth",         emoji: "🍫", tint: 0xFFF1DC),
    ]

    static func category(_ id: String) -> Category {
        categories.first { $0.id == id } ?? categories[0]
    }

    static let products: [Product] = [
        // Dairy
        Product(id: "p_milk",   name: "Amul Taaza Toned Milk", emoji: "🥛", unit: "500 ml",  price: 30, mrp: 32, categoryID: "dairy", etaMinutes: 11),
        Product(id: "p_eggs",   name: "Farm Fresh Eggs",       emoji: "🥚", unit: "6 pcs",    price: 66, mrp: 78, categoryID: "dairy", etaMinutes: 11),
        Product(id: "p_butter", name: "Amul Butter",           emoji: "🧈", unit: "100 g",    price: 58, mrp: 62, categoryID: "dairy", etaMinutes: 11),
        Product(id: "p_paneer", name: "Fresh Paneer",          emoji: "🧀", unit: "200 g",    price: 89, mrp: 99, categoryID: "dairy", etaMinutes: 11),
        Product(id: "p_curd",   name: "Creamy Curd",           emoji: "🍶", unit: "400 g",    price: 45, mrp: 50, categoryID: "dairy", etaMinutes: 11),
        Product(id: "p_cheese", name: "Cheese Slices",         emoji: "🧀", unit: "10 slices",price: 130, mrp: 150, categoryID: "dairy", etaMinutes: 11),

        // Fruits & veg
        Product(id: "p_banana", name: "Robusta Banana",        emoji: "🍌", unit: "6 pcs",    price: 44, mrp: 60, categoryID: "fruits", etaMinutes: 12),
        Product(id: "p_apple",  name: "Royal Gala Apple",      emoji: "🍎", unit: "4 pcs",    price: 120, mrp: 160, categoryID: "fruits", etaMinutes: 12),
        Product(id: "p_tomato", name: "Fresh Tomato",          emoji: "🍅", unit: "500 g",    price: 28, mrp: 40, categoryID: "fruits", etaMinutes: 12),
        Product(id: "p_onion",  name: "Onion",                 emoji: "🧅", unit: "1 kg",     price: 39, mrp: 55, categoryID: "fruits", etaMinutes: 12),
        Product(id: "p_potato", name: "Potato",                emoji: "🥔", unit: "1 kg",     price: 33, mrp: 45, categoryID: "fruits", etaMinutes: 12),
        Product(id: "p_lemon",  name: "Lemon",                 emoji: "🍋", unit: "4 pcs",    price: 22, mrp: 30, categoryID: "fruits", etaMinutes: 12),

        // Snacks
        Product(id: "p_chips",  name: "Classic Salted Chips",  emoji: "🥔", unit: "52 g",     price: 20, mrp: 20, categoryID: "snacks", etaMinutes: 11),
        Product(id: "p_popcorn",name: "Butter Popcorn",        emoji: "🍿", unit: "70 g",     price: 35, mrp: 40, categoryID: "snacks", etaMinutes: 11),
        Product(id: "p_nachos", name: "Cheese Nachos",         emoji: "🌮", unit: "60 g",     price: 45, mrp: 50, categoryID: "snacks", etaMinutes: 11),
        Product(id: "p_peanuts",name: "Masala Peanuts",        emoji: "🥜", unit: "200 g",    price: 55, mrp: 65, categoryID: "snacks", etaMinutes: 11),

        // Drinks
        Product(id: "p_coke",   name: "Chilled Cola",          emoji: "🥤", unit: "750 ml",   price: 40, mrp: 45, categoryID: "drinks", etaMinutes: 11),
        Product(id: "p_juice",  name: "Mixed Fruit Juice",     emoji: "🧃", unit: "1 L",      price: 99, mrp: 120, categoryID: "drinks", etaMinutes: 11),
        Product(id: "p_water",  name: "Mineral Water",         emoji: "💧", unit: "1 L",      price: 20, mrp: 22, categoryID: "drinks", etaMinutes: 11),
        Product(id: "p_energy", name: "Energy Drink",          emoji: "⚡️", unit: "250 ml",   price: 110, mrp: 125, categoryID: "drinks", etaMinutes: 11),

        // Bakery
        Product(id: "p_bread",  name: "Whole Wheat Bread",     emoji: "🍞", unit: "400 g",    price: 45, mrp: 50, categoryID: "bakery", etaMinutes: 11),
        Product(id: "p_bun",    name: "Pav Buns",              emoji: "🍔", unit: "6 pcs",    price: 30, mrp: 35, categoryID: "bakery", etaMinutes: 11),
        Product(id: "p_biscuit",name: "Choco Biscuits",        emoji: "🍪", unit: "120 g",    price: 30, mrp: 35, categoryID: "bakery", etaMinutes: 11),
        Product(id: "p_croiss", name: "Butter Croissant",      emoji: "🥐", unit: "2 pcs",    price: 79, mrp: 90, categoryID: "bakery", etaMinutes: 11),

        // Instant
        Product(id: "p_noodles",name: "Masala Noodles",        emoji: "🍜", unit: "4 pack",   price: 56, mrp: 60, categoryID: "instant", etaMinutes: 11),
        Product(id: "p_pasta",  name: "Instant Pasta",         emoji: "🍝", unit: "70 g",     price: 40, mrp: 45, categoryID: "instant", etaMinutes: 11),
        Product(id: "p_fries",  name: "Frozen Fries",          emoji: "🍟", unit: "420 g",    price: 99, mrp: 120, categoryID: "instant", etaMinutes: 11),
        Product(id: "p_nugget", name: "Veg Nuggets",           emoji: "🍗", unit: "250 g",    price: 130, mrp: 150, categoryID: "instant", etaMinutes: 11),

        // Hot drinks
        Product(id: "p_tea",    name: "Premium Tea",           emoji: "🍵", unit: "250 g",    price: 145, mrp: 170, categoryID: "hotdrinks", etaMinutes: 11),
        Product(id: "p_coffee", name: "Instant Coffee",        emoji: "☕️", unit: "50 g",     price: 175, mrp: 199, categoryID: "hotdrinks", etaMinutes: 11),
        Product(id: "p_sugar",  name: "Sugar",                 emoji: "🍚", unit: "1 kg",     price: 48, mrp: 55, categoryID: "hotdrinks", etaMinutes: 11),

        // Personal care
        Product(id: "p_soap",   name: "Moisturising Soap",     emoji: "🧼", unit: "3x100 g",  price: 99, mrp: 120, categoryID: "personal", etaMinutes: 13),
        Product(id: "p_shampoo",name: "Anti-Dandruff Shampoo", emoji: "🧴", unit: "180 ml",   price: 150, mrp: 199, categoryID: "personal", etaMinutes: 13),
        Product(id: "p_paste",  name: "Toothpaste",            emoji: "🪥", unit: "150 g",    price: 88, mrp: 99, categoryID: "personal", etaMinutes: 13),

        // Home
        Product(id: "p_wash",   name: "Dishwash Gel",          emoji: "🧽", unit: "500 ml",   price: 110, mrp: 130, categoryID: "home", etaMinutes: 13),
        Product(id: "p_deter",  name: "Detergent Powder",      emoji: "🧺", unit: "1 kg",     price: 120, mrp: 145, categoryID: "home", etaMinutes: 13),
        Product(id: "p_tissue", name: "Tissue Roll",           emoji: "🧻", unit: "4 rolls",  price: 85, mrp: 99, categoryID: "home", etaMinutes: 13),

        // Sweet
        Product(id: "p_choco",  name: "Dark Chocolate",        emoji: "🍫", unit: "80 g",     price: 90, mrp: 110, categoryID: "sweet", etaMinutes: 11),
        Product(id: "p_icecream",name: "Vanilla Ice Cream",    emoji: "🍦", unit: "700 ml",   price: 180, mrp: 220, categoryID: "sweet", etaMinutes: 11),
        Product(id: "p_gulab",  name: "Gulab Jamun",           emoji: "🍮", unit: "1 kg",     price: 199, mrp: 240, categoryID: "sweet", etaMinutes: 11),
    ]

    static func products(in categoryID: String) -> [Product] {
        products.filter { $0.categoryID == categoryID }
    }

    static func product(_ id: String) -> Product? {
        products.first { $0.id == id }
    }

    static func search(_ query: String) -> [Product] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return products }
        return products.filter { $0.name.lowercased().contains(q) }
    }

    /// A curated set for the home "featured" rail.
    static let featured: [Product] = [
        product("p_milk"), product("p_bread"), product("p_eggs"), product("p_banana"),
        product("p_coke"), product("p_chips"), product("p_choco"), product("p_icecream")
    ].compactMap { $0 }

    /// Products a simulated friend might add during a group order.
    static let botPicks: [Product] = [
        product("p_bread"), product("p_eggs"), product("p_chips"), product("p_coke"),
        product("p_choco"), product("p_noodles"), product("p_juice"), product("p_biscuit"),
        product("p_butter"), product("p_icecream")
    ].compactMap { $0 }
}
