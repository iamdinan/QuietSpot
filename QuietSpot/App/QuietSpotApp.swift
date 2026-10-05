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
        NotificationService().configurePresentation()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
