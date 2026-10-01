//
//  ForgotPasswordView.swift
//  QuietSpot
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(AuthenticationViewModel.self) private var authentication
    @State private var email = ""
    @State private var showsResetConfirmation = false

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

                PrimaryButton("Send reset link") {
                    Task {
                        showsResetConfirmation = await authentication.sendPasswordReset(email: email)
                    }
                }
                    .disabled(!authentication.canAuthenticate || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.top, 24)

                AuthenticationFeedback(progressMessage: "Requesting reset link…")

                Label("We’ll send a password-reset link to this address.", systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .disabled(authentication.isBusy)
        .navigationBarBackButtonHidden(authentication.isBusy)
        .alert("Check your email", isPresented: $showsResetConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("If an account exists for that email, you’ll receive a password-reset link. Check your spam folder too.")
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
    }
    .environment(AuthenticationViewModel())
}
