//
//  AppAppearance.swift
//  QuietSpot
//

import SwiftUI

enum AppAppearance: String {
    case system
    case light
    case dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var toggled: AppAppearance {
        switch self {
        case .system, .light: .dark
        case .dark: .light
        }
    }
}
