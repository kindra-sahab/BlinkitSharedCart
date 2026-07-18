//
//  CategoriesView.swift
//  BlinkitSharedCart
//

import SwiftUI

struct CategoriesView: View {
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    NavigationLink(value: SearchRoute.search) { SearchField() }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)

                    ForEach(sections, id: \.title) { section in
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: section.title)
                                .padding(.horizontal, 16)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 14) {
                                ForEach(section.categories) { cat in
                                    CategoryTile(category: cat)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    Color.clear.frame(height: 120)
                }
                .padding(.top, 8)
            }
            .background(Palette.background)
            .safeAreaInset(edge: .top) { NavBarTitle(title: "All Categories") }
            .navigationDestination(for: Category.self) { ProductListView(category: $0) }
            .navigationDestination(for: Product.self) { ProductDetailView(product: $0) }
            .navigationDestination(for: SearchRoute.self) { _ in SearchView() }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var sections: [(title: String, categories: [Category])] {
        let all = MockCatalog.categories
        return [
            ("Grocery & Kitchen", Array(all[0..<4])),
            ("Snacks & Drinks", Array(all[4..<7])),
            ("Household & Personal Care", Array(all[7...])),
        ]
    }
}

struct CategoryTile: View {
    let category: Category
    var body: some View {
        NavigationLink(value: category) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: category.tint))
                    Text(category.emoji).font(.system(size: 30))
                }
                .frame(height: 74)
                Text(category.name)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 28, alignment: .top)
            }
        }
        .buttonStyle(.plain)
    }
}

/// A minimal top bar used on non-home tabs.
struct NavBarTitle: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.ink)
            Spacer()
            NotificationBell()
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(.white.opacity(0.96))
    }
}
