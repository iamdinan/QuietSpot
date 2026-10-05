//
//  QuietSpotApp.swift
//  QuietSpot
//
//  Created by Student1 on 2026-10-01.
//

import AppIntents
import SwiftUI

@main
struct QuietSpotApp: App {
    private static var isRunningUnitTests: Bool {
        #if DEBUG
        ProcessInfo.processInfo.environment["QUIETSPOT_UNIT_TESTS"] == "1"
        #else
        false
        #endif
    }

    init() {
        // Tests exercise local components without starting Firebase or system services.
        guard !Self.isRunningUnitTests else { return }
        // Remove the legacy override for users upgrading to system appearance.
        UserDefaults.standard.removeObject(forKey: "appearanceMode")
        _ = NetworkStatus.shared
        NotificationService().configurePresentation()
        QuietSpotShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            if Self.isRunningUnitTests {
                Color.clear
            } else {
                ContentView()
            }
        }
    }
}
