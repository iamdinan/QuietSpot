//
//  CafeStatusCard.swift
//  QuietSpot
//

import SwiftUI

struct CafeStatusCard: View {
    let cafe: CafeSnapshot
    let showsDetails: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(cafe.name)
                        .font(.headline)
                    Text(cafe.area)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(cafe.updatedAt)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                NoisePill(level: cafe.noiseLevel)
                if showsDetails {
                    StatusPill(title: cafe.wifi, icon: "wifi")
                }
            }

            if showsDetails {
                HStack(spacing: 8) {
                    StatusPill(title: cafe.outlets, icon: "powerplug")
                    StatusPill(title: cafe.crowd, icon: "person.2")
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct NoisePill: View {
    let level: NoiseLevel

    private var tint: Color {
        switch level {
        case .quiet: .green
        case .moderate: .orange
        case .loud: .red
        }
    }

    var body: some View {
        Label(level.rawValue, systemImage: "speaker.wave.2")
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.14), in: Capsule())
    }
}

private struct StatusPill: View {
    let title: String
    let icon: String

    private var tone: StatusTone {
        if title == "Strong Wi‑Fi" || title == "Outlets free" || title == "Uncrowded" {
            return .positive
        }

        if title == "Spotty Wi‑Fi" || title == "Outlets full" || title == "Crowded" {
            return .negative
        }

        return .neutral
    }

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.medium))
            .foregroundStyle(tone.foregroundColor)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tone.backgroundColor, in: Capsule())
    }
}

private enum StatusTone {
    case positive
    case negative
    case neutral

    var foregroundColor: Color {
        switch self {
        case .positive: .green
        case .negative: .red
        case .neutral: .secondary
        }
    }

    var backgroundColor: Color {
        switch self {
        case .positive: Color.green.opacity(0.14)
        case .negative: Color.red.opacity(0.14)
        case .neutral: Color(uiColor: .tertiarySystemFill)
        }
    }
}
