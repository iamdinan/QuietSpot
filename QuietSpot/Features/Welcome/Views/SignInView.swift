//
//  SignInView.swift
//  QuietSpot
//

import SwiftUI

struct SignInView: View {
    let onForgotPassword: () -> Void
    let onRegister: () -> Void

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Welcome back")
                        .font(.largeTitle.bold())

                    Text("Sign in to keep your favorite quiet cafés close by.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)

                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(14)
                        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding(14)
                        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.top, 36)

                HStack {
                    Spacer()
                    TextLinkButton("Forgot password?", action: onForgotPassword)
                }
                .padding(.top, 12)

                PrimaryButton("Sign in", action: {})
                    .padding(.top, 32)

                Spacer(minLength: 36)

                HStack(spacing: 4) {
                    Text("New to QuietSpot?")
                        .foregroundStyle(.secondary)
                    TextLinkButton("Create an account", action: onRegister)
                }
                .font(.body)
                .frame(maxWidth: .infinity)
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
        SignInView(onForgotPassword: {}, onRegister: {})
    }
}
