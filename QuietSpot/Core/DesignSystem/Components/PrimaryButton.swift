//
//  PrimaryButton.swift
//  QuietSpot
//

import SwiftUI

struct PrimaryButton: View {
    let title: LocalizedStringKey
    let action: () -> Void

    init(_ title: LocalizedStringKey, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(AppColor.accent)
        .accessibilityHint("Opens sign in")
    }
}

#Preview {
    PrimaryButton("Sign in to continue", action: {})
        .padding()
}
