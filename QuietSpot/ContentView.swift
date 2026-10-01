//
//  ContentView.swift
//  QuietSpot
//
//  Created by Student1 on 2026-10-01.
//

import SwiftUI

struct ContentView: View {
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            WelcomeView {
                navigationPath.append(AppRoute.signIn)
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .signIn:
                    SignInView(
                        onForgotPassword: {},
                        onRegister: {}
                    )
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
