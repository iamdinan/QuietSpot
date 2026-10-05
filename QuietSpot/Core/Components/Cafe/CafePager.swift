import SwiftUI

struct CafePager: View {
    let cafes: [CafeSnapshot]
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var selectedPage = 0
    private let pageSize: Int
    private let accessibilityContext: String

    init(cafes: [CafeSnapshot], pageSize: Int = 3, accessibilityContext: String = "Cafés") {
        self.cafes = cafes
        self.pageSize = pageSize
        self.accessibilityContext = accessibilityContext
    }

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
        .onChange(of: cafes.map(\.id)) {
            selectedPage = min(selectedPage, pageCount - 1)
        }
        .onChange(of: selectedPage) {
            if voiceOverEnabled {
                AccessibilityNotification.Announcement("\(accessibilityContext), page \(selectedPage + 1) of \(pageCount)").post()
            }
        }
    }
}
