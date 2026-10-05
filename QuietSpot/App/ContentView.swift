//
//  ContentView.swift
//  QuietSpot
//
//  Created by Student1 on 2026-10-01.
//

import SwiftUI

struct ContentView: View {
    @State private var navigationPath = NavigationPath()
    @State private var authentication = AuthenticationViewModel()
    @AppStorage("appearanceMode") private var appearanceMode = AppAppearance.system.rawValue

    private var selectedAppearance: AppAppearance {
        AppAppearance(rawValue: appearanceMode) ?? .system
    }

    var body: some View {
        @Bindable var authentication = authentication
        Group {
            if authentication.isRestoringSession {
                ProgressView("Restoring your session…")
            } else if authentication.isCreatingAccount {
                ProgressView("Creating your account…")
            } else if let userID = authentication.userID {
                MainTabView(onSignOut: authentication.signOut, profile: $authentication.profile)
                    .id(userID)
            } else {
                NavigationStack(path: $navigationPath) {
                    WelcomeView(
                        onSignIn: {
                            navigationPath.append(AppRoute.signIn)
                        },
                        onToggleAppearance: {
                            appearanceMode = selectedAppearance.toggled.rawValue
                        }
                    )
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .signIn:
                            SignInView(
                                onForgotPassword: {
                                    navigationPath.append(AppRoute.forgotPassword)
                                },
                                onRegister: {
                                    navigationPath.append(AppRoute.createAccount)
                                }
                            )
                        case .forgotPassword:
                            ForgotPasswordView()
                        case .createAccount:
                            CreateAccountView()
                        }
                    }
                }
            }
        }
        .environment(authentication)
        .task { authentication.start() }
        .onChange(of: authentication.userID) { _, _ in
            navigationPath = NavigationPath()
        }
        .alert("Account notice", isPresented: Binding(
            get: { authentication.errorMessage != nil },
            set: { if !$0 { authentication.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { authentication.errorMessage = nil }
        } message: {
            Text(authentication.errorMessage ?? "")
        }
        .preferredColorScheme(selectedAppearance.colorScheme)
    }
}

#Preview {
    ContentView()
        .environment(\.loadsCafeImages, false)
}
