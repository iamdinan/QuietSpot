//
//  SignInView.swift
//  QuietSpot
//

import SwiftUI

struct SignInView: View {
    @Environment(AuthenticationViewModel.self) private var authentication
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
                        .inputFieldStyle()

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .inputFieldStyle()
                }
                .padding(.top, 36)

                HStack {
                    Spacer()
                    TextLinkButton("Forgot password?", action: onForgotPassword)
                }
                .padding(.top, 12)

                PrimaryButton("Sign in") {
                    Task { await authentication.signIn(email: email, password: password) }
                }
                    .disabled(!authentication.canAuthenticate || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)
                    .padding(.top, 32)

                AuthenticationFeedback(progressMessage: "Signing in…")

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
        .disabled(authentication.isBusy)
        .navigationBarBackButtonHidden(authentication.isBusy)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SignInView(onForgotPassword: {}, onRegister: {})
    }
    .environment(AuthenticationViewModel())
}
