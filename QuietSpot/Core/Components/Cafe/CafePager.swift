// Splits cafe cards into pages and adapts their grid to screen width.

import SwiftUI

struct CafePager: View {
    let cafes: [CafeSnapshot]
    let pageSize: Int
    let accessibilityContext: String
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedPage = 0

    private var pageCount: Int {
        max(1, (cafes.count + pageSize - 1) / pageSize)
    }

    // Slice the current page before the grid lays out its cards.
    private var visibleCafes: [CafeSnapshot] {
        Array(cafes.dropFirst(selectedPage * pageSize).prefix(pageSize))
    }

    private let topAnchorID = "cafePagerTop"

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 12) {
                Color.clear
                    .frame(height: 0)
                    .id(topAnchorID)

                LazyVGrid(
                    columns: horizontalSizeClass != .regular || dynamicTypeSize.isAccessibilitySize
                        ? [GridItem(.flexible(), alignment: .top)]
                        : [GridItem(.adaptive(minimum: 300), spacing: 16, alignment: .top)],
                    spacing: 16
                ) {
                    ForEach(visibleCafes) { cafe in
                        NavigationLink(value: cafe.id) {
                            CafeStatusCard(cafe: cafe)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if pageCount > 1 {
                    HStack {
                        Button {
                            selectedPage -= 1
                        } label: {
                            Image(systemName: "chevron.left").frame(width: 44, height: 44)
                        }
                        .disabled(selectedPage == 0)
                        .accessibilityLabel("Previous page of \(accessibilityContext)")
                        .accessibilityValue("Page \(selectedPage + 1) of \(pageCount)")

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
                        .accessibilityLabel("Next page of \(accessibilityContext)")
                        .accessibilityValue("Page \(selectedPage + 1) of \(pageCount)")
                    }
                    .tint(AppColor.accent)
                }
            }
            // A refresh may leave the current page beyond the end of the list.
            .onChange(of: cafes.map(\.id)) {
                selectedPage = min(selectedPage, pageCount - 1)
            }
            .onChange(of: selectedPage) {
                withAnimation {
                    proxy.scrollTo(topAnchorID, anchor: .top)
                }
                if voiceOverEnabled {
                    AccessibilityNotification.Announcement("\(accessibilityContext), page \(selectedPage + 1) of \(pageCount)").post()
                }
            }
        }
    }
}
