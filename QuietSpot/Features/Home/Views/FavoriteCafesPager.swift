//
//  FavoriteCafesPager.swift
//  QuietSpot
//

import SwiftUI

struct FavoriteCafesPager: View {
    let cafes: [CafeSnapshot]
    @State private var selectedPage = 0

    private var pages: [[CafeSnapshot]] {
        stride(from: 0, to: cafes.count, by: 2).map { startIndex in
            Array(cafes[startIndex ..< min(startIndex + 2, cafes.count)])
        }
    }

    var body: some View {
        TabView(selection: $selectedPage) {
            ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                VStack(spacing: 10) {
                    ForEach(page) { cafe in
                        CafeStatusCard(cafe: cafe, showsDetails: true)
                    }
                    Spacer(minLength: 0)
                }
                .tag(index)
                .padding(.bottom, 28)
            }
        }
        .frame(height: 336)
        .tabViewStyle(.page(indexDisplayMode: .always))
        .accessibilityLabel("Favorite cafés, page \(selectedPage + 1) of \(pages.count)")
    }
}
