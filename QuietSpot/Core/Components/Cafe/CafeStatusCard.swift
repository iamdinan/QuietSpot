import SwiftUI

struct CafeStatusCard: View {
    enum Style { case widget, photo }

    let cafe: CafeSnapshot
    var style: Style = .photo

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if style == .photo {
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
                if style == .widget {
                    CafeThumbnail(cafe: cafe, size: 48)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(cafe.name).font(.headline)
                    Text(cafe.area).font(.subheadline).foregroundStyle(.secondary)
                    Text("Updated \(cafe.updatedAt)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
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
        .accessibilityHint("Opens café details")
    }
}
