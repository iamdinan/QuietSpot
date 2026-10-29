// Introduces the app and leads the user to sign in.

import SwiftUI

struct OnboardingView: View {
    let onIntroductionCompleted: () -> Void
    let onSignIn: () -> Void
    @State private var page: Int

    init(startAtWelcome: Bool = false, onIntroductionCompleted: @escaping () -> Void, onSignIn: @escaping () -> Void) {
        self.onIntroductionCompleted = onIntroductionCompleted
        self.onSignIn = onSignIn
        _page = State(initialValue: startAtWelcome ? 2 : 0)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Label("QuietSpot", systemImage: "cup.and.saucer.fill")
                    .font(.headline)
                    .foregroundStyle(AppColor.accent)
                Spacer()
                if page < 2 {
                    Button("Skip") { page = 2 }
                        .frame(minHeight: 44)
                }
            }
            .padding(.horizontal, 24)

            TabView(selection: $page) {
                introduction(
                    kind: .discovery,
                    title: "Find a café that fits.",
                    message: "A quiet corner or a lively coffee break? Check the conditions before you go."
                )
                .tag(0)

                introduction(
                    kind: .sharing,
                    title: "Share what it’s like.",
                    message: "A quick update from you can make someone else’s visit better."
                )
                .tag(1)

                introduction(
                    kind: .welcome,
                    title: "Make yourself at home.",
                    message: "Sign in or create an account to get started with QuietSpot."
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Capsule()
                            .fill(index == page ? AppColor.accent : Color.secondary.opacity(0.25))
                            .frame(width: index == page ? 24 : 8, height: 8)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Introduction, page \(page + 1) of 3")
                PrimaryButton(page == 2 ? "Sign in to continue" : "Next") {
                    if page < 2 { page += 1 } else { onSignIn() }
                }
            }
            .padding(24)
            .readableContent(maxWidth: 480)
        }
        .background(Color(uiColor: .systemBackground))
        .tint(AppColor.accent)
        .onChange(of: page) { _, newPage in
            if newPage == 2 { onIntroductionCompleted() }
        }
    }

    private func introduction(
        kind: OnboardingPreview.Kind,
        title: String,
        message: String
    ) -> some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 28) {
                    OnboardingPreview(kind: kind)

                    VStack(spacing: 16) {
                        Text(title)
                            .font(.largeTitle.bold())
                            .foregroundStyle(.primary)
                            .accessibilityAddTraits(.isHeader)
                        Text(message)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                }
                .padding(24)
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height)
            }
        }
    }
}

#Preview("Light") {
    OnboardingView(onIntroductionCompleted: {}, onSignIn: {})
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    OnboardingView(onIntroductionCompleted: {}, onSignIn: {})
        .preferredColorScheme(.dark)
}
