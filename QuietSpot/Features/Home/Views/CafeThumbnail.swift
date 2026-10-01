//
//  CafeThumbnail.swift
//  QuietSpot
//

import SwiftUI

struct CafeThumbnail: View {
    let cafe: CafeSnapshot
    let size: CGFloat

    var body: some View {
        Image(cafe.imageName)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            .accessibilityLabel("Photo of \(cafe.name)")
    }
}
