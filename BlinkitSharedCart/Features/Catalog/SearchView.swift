//
//  SearchView.swift
//  BlinkitSharedCart
//

import SwiftUI

struct SearchView: View {
    @Environment(AppState.self) private var app
    @State private var query = ""
    @FocusState private var focused: Bool

    private var results: [Product] {
        query.isEmpty ? MockCatalog.featured : MockCatalog.search(query)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(Palette.inkSecondary)
                TextField("Search for milk, bread, eggs…", text: $query)
                    .font(.system(size: 15, design: .rounded))
                    .focused($focused)
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Palette.inkTertiary)
                    }
                }
            }
            .padding(.horizontal, 14).frame(height: 48)
            .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.hairline, lineWidth: 1))
            .padding(.horizontal, 16)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(results) { product in
                        ProductCard(
                            product: product,
                            quantity: app.contextQuantity(of: product),
                            onAdd: { app.contextAdd(product) },
                            onIncrement: { app.contextChange(product, delta: 1) },
                            onDecrement: { app.contextChange(product, delta: -1) }
                        )
                    }
                }
                .padding(16)
                Color.clear.frame(height: 100)
            }
        }
        .background(Palette.background)
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { focused = true }
    }
}
