import SwiftUI

struct CafeStatusCard: View {
    enum Style { case widget, favorite, standard }

    let cafe: CafeSnapshot
    var style: Style = .standard

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if style == .favorite {
                // A bounded container gives every source image the same crop.
                Color.clear
                    .frame(height: 140)
                    .overlay {
                        Image(cafe.imageName)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .accessibilityLabel("Photo of \(cafe.name)")
            }

            HStack(alignment: .center, spacing: 12) {
                if style != .favorite {
                    CafeThumbnail(cafe: cafe, size: style == .widget ? 48 : 64)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(cafe.name).font(.headline)
                    Text(cafe.area).font(.subheadline).foregroundStyle(.secondary)
                    Text("Updated \(cafe.updatedAt)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            CafeStatusGrid(cafe: cafe)
        }
        .padding(style == .widget ? 0 : 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if style != .widget {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            }
        }
        .accessibilityElement(children: .combine)
    }
}
