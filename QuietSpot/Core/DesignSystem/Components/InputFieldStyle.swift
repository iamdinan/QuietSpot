//
//  InputFieldStyle.swift
//  QuietSpot
//

import SwiftUI

private struct InputFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(
                Color(uiColor: .secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
    }
}

extension View {
    func inputFieldStyle() -> some View {
        modifier(InputFieldStyle())
    }
}
