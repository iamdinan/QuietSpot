//
//  ForgotPasswordView.swift
//  QuietSpot
//

import SwiftUI

struct ForgotPasswordView: View {
    @State private var email = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Reset your password")
                        .font(.largeTitle.bold())

                    Text("Enter the email address associated with your QuietSpot account.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)

                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .inputFieldStyle()
                    .padding(.top, 36)

                PrimaryButton("Send reset link", action: {})
                    .padding(.top, 24)

                Label("We’ll send a password-reset link to this address.", systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
    }
}
