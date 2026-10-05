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
    init() {
        // Remove the legacy override for users upgrading to system appearance.
        UserDefaults.standard.removeObject(forKey: "appearanceMode")
        _ = NetworkStatus.shared
        NotificationService().configurePresentation()
        QuietSpotShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
