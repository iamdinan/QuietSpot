//
//  TextLinkButton.swift
//  QuietSpot
//

import SwiftUI

struct TextLinkButton: View {
    let title: LocalizedStringKey
    let action: () -> Void

    init(_ title: LocalizedStringKey, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(title, action: action)
            .font(.body.weight(.semibold))
            .foregroundStyle(AppColor.accent)
    }
}
