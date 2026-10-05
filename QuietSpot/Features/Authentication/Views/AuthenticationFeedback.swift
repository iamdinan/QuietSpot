import SwiftUI

struct AuthenticationFeedback: View {
    @Environment(AuthenticationViewModel.self) private var authentication
    let progressMessage: String

    var body: some View {
        if authentication.isBusy {
            ProgressView(progressMessage)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
        } else if let message = authentication.configurationError {
            Label(message, systemImage: "info.circle")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 16)
        }
    }
}
