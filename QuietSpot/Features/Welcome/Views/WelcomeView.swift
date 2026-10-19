//
//  WelcomeView.swift
//  QuietSpot
//

import SwiftUI

struct WelcomeView: View {
    let onSignIn: () -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .regular {
            iPadLayout
        } else {
            iPhoneLayout
        }
    }

    // MARK: - iPad layout (HIG split-view)

    private var iPadLayout: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                // Leading half: full-bleed hero image
                heroImage
                    .frame(width: proxy.size.width * 0.50)
                    .ignoresSafeArea(edges: .all)

                // Trailing half: branding + CTA, vertically centred
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 28) {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("QuietSpot", systemImage: "cup.and.saucer.fill")
                                    .font(.headline)
                                    .foregroundStyle(AppColor.accent)
                                    .accessibilityElement(children: .combine)

                                Text("Find your next\nquiet corner.")
                                    .font(.largeTitle.bold())
                                    .foregroundStyle(.primary)
                                    .accessibilityAddTraits(.isHeader)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text("Discover cafés that fit your pace — from focused work sessions to a slow coffee break.")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            PrimaryButton("Sign in to continue", action: onSignIn)
                        }
                        .padding(48)
                        .frame(maxWidth: 440, alignment: .leading)

                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: proxy.size.height)
                }
                .frame(width: proxy.size.width * 0.50)
                .background(Color(uiColor: .systemBackground))
            }
        }
        .background(Color(uiColor: .systemBackground))
        .ignoresSafeArea()
    }

    // MARK: - iPhone layout (original, unchanged)

    private var iPhoneLayout: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    heroImage
                        .frame(height: min(max(proxy.size.height * 0.42, 280), 380))

                    VStack(alignment: .leading, spacing: 16) {
                        Label("QuietSpot", systemImage: "cup.and.saucer.fill")
                            .font(.headline)
                            .foregroundStyle(AppColor.accent)
                            .accessibilityElement(children: .combine)

                        Text("Find your next quiet corner.")
                            .font(.largeTitle.bold())
                            .accessibilityAddTraits(.isHeader)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Discover cafés that fit your pace, from focused work sessions to a slow coffee break.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 28)
                    .padding(.horizontal, 24)
                    .readableContent()

                    Spacer(minLength: 32)

                    PrimaryButton("Sign in to continue", action: onSignIn)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        .readableContent()
                }
                .frame(minHeight: proxy.size.height, alignment: .top)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color(uiColor: .systemBackground))
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Shared hero image

    private var heroImage: some View {
        Color.clear
            .overlay {
                Image("CafeHero")
                    .resizable()
                    .scaledToFill()
            }
            .overlay(AppColor.heroOverlay)
            .clipped()
            .accessibilityLabel("A sunlit, quiet café interior with a cup of coffee")
    }
}

#Preview {
    WelcomeView(onSignIn: {})
}
