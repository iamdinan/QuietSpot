import SwiftUI

/// The parent supplies a bounded frame; all café photos share the same fill crop.
struct CafeImage: View {
    let cafe: CafeSnapshot

    var body: some View {
        GeometryReader { geometry in
            Group {
                if let imageURL = cafe.imageURL {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            Color(uiColor: .secondarySystemFill)
                                .overlay {
                                    if phase.error != nil || URL(string: imageURL) == nil {
                                        Image(systemName: "photo").foregroundStyle(.secondary)
                                    } else {
                                        ProgressView()
                                    }
                                }
                        }
                    }
                } else {
                    Image(cafe.imageName).resizable().scaledToFill()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Photo of \(cafe.name)")
    }
}
