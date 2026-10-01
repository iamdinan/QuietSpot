//
//  WelcomeView.swift
//  QuietSpot
//

import SwiftUI

struct WelcomeView: View {
    let onSignIn: () -> Void
    let onToggleAppearance: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    heroImage(
                        height: min(max(proxy.size.height * 0.42, 280), 380),
                        topSafeAreaInset: proxy.safeAreaInsets.top
                    )

                    VStack(alignment: .leading, spacing: 16) {
                        Label("QuietSpot", systemImage: "cup.and.saucer.fill")
                            .font(.headline)
                            .foregroundStyle(AppColor.accent)
                            .accessibilityElement(children: .combine)

                        Text("Find your next quiet corner.")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Discover cafés that fit your pace, from focused work sessions to a slow coffee break.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 28)
                    .padding(.horizontal, 24)

                    Spacer(minLength: 32)

                    PrimaryButton("Sign in to continue", action: onSignIn)
                        .padding(.horizontal, 24)
                }
                .frame(minHeight: proxy.size.height, alignment: .top)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color(uiColor: .systemBackground))
        .ignoresSafeArea(edges: .top)
    }

    private func heroImage(height: CGFloat, topSafeAreaInset: CGFloat) -> some View {
        Image("CafeHero")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay(AppColor.heroOverlay)
            .overlay(alignment: .topTrailing) {
                Button(action: onToggleAppearance) {
                    Image(systemName: colorScheme == .dark ? "sun.max.fill" : "moon.fill")
                        .font(.headline)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .background(.ultraThinMaterial, in: Circle())
                .padding(.top, topSafeAreaInset + 8)
                .padding(.trailing, 20)
                .accessibilityLabel(colorScheme == .dark ? "Switch to Light Mode" : "Switch to Dark Mode")
            }
            .clipped()
            .accessibilityLabel("A sunlit, quiet café interior with a cup of coffee")
    }
}

#Preview {
    WelcomeView(onSignIn: {}, onToggleAppearance: {})
}
