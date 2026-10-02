import SwiftUI

/// The parent supplies a bounded frame; all café photos share the same fill crop.
struct CafeImage: View {
    let cafe: CafeSnapshot
    var allowsRetry = false
    @State private var viewModel = CafeImageViewModel()

    var body: some View {
        GeometryReader { geometry in
            Group {
                if !cafe.imageName.isEmpty {
                    // Bundled photos are used only by the sample-data previews.
                    Image(cafe.imageName).resizable().scaledToFill()
                        .accessibilityLabel("Photo of \(cafe.name)")
                } else if let image = viewModel.image {
                    Image(uiImage: image).resizable().scaledToFill()
                        .accessibilityLabel("Photo of \(cafe.name)")
                } else {
                    Color(uiColor: .secondarySystemFill)
                        .overlay {
                            if let error = viewModel.errorMessage {
                                VStack(spacing: 4) {
                                    if geometry.size.height >= 100 {
                                        Text("Photo unavailable")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if allowsRetry {
                                        Button {
                                            Task { await viewModel.load(cafeID: cafe.id) }
                                        } label: {
                                            Image(systemName: "arrow.clockwise")
                                                .frame(width: 44, height: 44)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("Reload photo of \(cafe.name)")
                                        .accessibilityHint(error)
                                    } else {
                                        Image(systemName: "photo")
                                            .foregroundStyle(.secondary)
                                            .accessibilityLabel("Photo unavailable")
                                            .accessibilityHidden(geometry.size.height >= 100)
                                    }
                                }
                            } else if viewModel.isLoading {
                                ProgressView().accessibilityLabel("Loading café photo")
                            } else {
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                                    .accessibilityLabel("Photo of \(cafe.name)")
                            }
                        }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .accessibilityElement(children: .contain)
        .task(id: cafe.id) {
            if cafe.imageName.isEmpty { await viewModel.load(cafeID: cafe.id) }
        }
    }
}
