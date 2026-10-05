//
//  AppColor.swift
//  QuietSpot
//

import SwiftUI

enum AppColor {
    static let accent = Color("BrandAccent")
    static let heroOverlay = Color.black.opacity(0.08)

    static let positive = statusColor(light: (0.08, 0.38, 0.20), dark: (0.45, 0.88, 0.59))
    static let moderate = statusColor(light: (0.52, 0.27, 0.02), dark: (1.00, 0.73, 0.32))
    static let negative = statusColor(light: (0.60, 0.09, 0.12), dark: (1.00, 0.68, 0.70))

    private static func statusColor(
        light: (Double, Double, Double), dark: (Double, Double, Double)
    ) -> Color {
        Color(uiColor: UIColor { traits in
            let rgb = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1)
        })
    }
}
