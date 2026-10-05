//
//  QuietSpotApp.swift
//  QuietSpot
//
//  Created by Student1 on 2026-10-01.
//

import SwiftUI

@main
struct QuietSpotApp: App {
    init() {
        // Remove the legacy override for users upgrading to system appearance.
        UserDefaults.standard.removeObject(forKey: "appearanceMode")
        NotificationService().configurePresentation()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
