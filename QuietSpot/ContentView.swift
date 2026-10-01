//
//  ContentView.swift
//  QuietSpot
//
//  Created by Student1 on 2026-10-01.
//

import SwiftUI

struct ContentView: View {
    @State private var navigationPath = NavigationPath()
    @State private var isAuthenticated = false
    @AppStorage("appearanceMode") private var appearanceMode = AppAppearance.system.rawValue

    private var selectedAppearance: AppAppearance {
        AppAppearance(rawValue: appearanceMode) ?? .system
    }

    var body: some View {
        Group {
            if isAuthenticated {
                MainTabView()
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
                                onSignIn: { isAuthenticated = true },
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
                            CreateAccountView(onCreateAccount: { isAuthenticated = true })
                        }
                    }
                }
            }
        }
        .preferredColorScheme(selectedAppearance.colorScheme)
    }
}

#Preview {
    ContentView()
}
