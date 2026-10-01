import SwiftUI

struct CafeStatusGrid: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let noiseLevel: NoiseLevel
    private let wifi: String
    private let outlets: String
    private let crowd: String

    init(cafe: CafeSnapshot) {
        noiseLevel = cafe.noiseLevel
        wifi = cafe.wifi
        outlets = cafe.outlets
        crowd = cafe.crowd
    }

    init(checkIn: CafeCheckIn) {
        noiseLevel = checkIn.noiseLevel
        wifi = checkIn.wifi
        outlets = checkIn.outlets
        crowd = checkIn.crowd
    }

    var body: some View {
        LazyVGrid(
            columns: dynamicTypeSize.isAccessibilitySize
                ? [GridItem(.flexible(), alignment: .leading)]
                : [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)],
            alignment: .leading,
            spacing: 8
        ) {
            CompactStatusPill(
                title: noiseLevel.rawValue,
                icon: "speaker.wave.2",
                tint: noiseLevel.tint,
                accessibilityLabel: "Noise: \(noiseLevel.rawValue)"
            )
            CompactStatusPill(
                title: wifi,
                icon: "wifi",
                tint: wifi == "Strong Wi‑Fi" ? AppColor.positive : AppColor.negative
            )
            CompactStatusPill(
                title: outlets,
                icon: "powerplug",
                tint: outlets == "Outlets free" ? AppColor.positive : AppColor.negative
            )
            CompactStatusPill(
                title: crowd,
                icon: "person.2",
                tint: crowd == "Uncrowded" ? AppColor.positive : AppColor.negative
            )
        }
    }
}

private struct CompactStatusPill: View {
    let title: String
    let icon: String
    let tint: Color
    var accessibilityLabel: String?

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(tint.opacity(0.12), in: Capsule())
            .accessibilityLabel(accessibilityLabel ?? title)
    }
}

private extension NoiseLevel {
    var tint: Color {
        switch self {
        case .quiet: AppColor.positive
        case .moderate: AppColor.moderate
        case .loud: AppColor.negative
        }
    }
}

#Preview("Light") {
    CafeStatusGrid(cafe: CafeSampleData.cafes[0])
        .padding()
}

#Preview("Dark") {
    CafeStatusGrid(cafe: CafeSampleData.cafes[2])
        .padding()
        .preferredColorScheme(.dark)
}
