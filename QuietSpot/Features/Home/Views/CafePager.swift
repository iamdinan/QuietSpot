import SwiftUI

struct CafePager: View {
    let cafes: [CafeSnapshot]
    @State private var selectedPage = 0
    private let pageSize = 3

    private var pageCount: Int {
        max(1, (cafes.count + pageSize - 1) / pageSize)
    }

    private var visibleCafes: [CafeSnapshot] {
        Array(cafes.dropFirst(selectedPage * pageSize).prefix(pageSize))
    }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(visibleCafes) { cafe in
                NavigationLink(value: cafe.id) {
                    CafeStatusCard(cafe: cafe)
                }
                .buttonStyle(.plain)
            }

            if pageCount > 1 {
                HStack {
                    Button {
                        selectedPage -= 1
                    } label: {
                        Image(systemName: "chevron.left").frame(width: 44, height: 44)
                    }
                    .disabled(selectedPage == 0)
                    .accessibilityLabel("Previous cafés page")

                    Spacer()
                    Text("Page \(selectedPage + 1) of \(pageCount)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()

                    Button {
                        selectedPage += 1
                    } label: {
                        Image(systemName: "chevron.right").frame(width: 44, height: 44)
                    }
                    .disabled(selectedPage == pageCount - 1)
                    .accessibilityLabel("Next cafés page")
                }
                .tint(AppColor.accent)
            }
        }
        .onChange(of: cafes.count) {
            selectedPage = min(selectedPage, pageCount - 1)
        }
    }
}
