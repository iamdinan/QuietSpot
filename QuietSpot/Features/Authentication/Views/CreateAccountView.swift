//
//  CreateAccountView.swift
//  QuietSpot
//

import SwiftUI

struct CreateAccountView: View {
    let onCreateAccount: () -> Void

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Create your account")
                        .font(.largeTitle.bold())

                    Text("Save your favorite cafés and make every break feel more intentional.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)

                VStack(spacing: 16) {
                    TextField("Display name", text: $displayName)
                        .textContentType(.nickname)
                        .inputFieldStyle()

                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .inputFieldStyle()

                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                        .inputFieldStyle()
                }
                .padding(.top, 36)

                PrimaryButton("Create account", action: onCreateAccount)
                    .padding(.top, 32)

                Text("You can update your profile and notification preferences at any time.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
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
        CreateAccountView(onCreateAccount: {})
    }
}
