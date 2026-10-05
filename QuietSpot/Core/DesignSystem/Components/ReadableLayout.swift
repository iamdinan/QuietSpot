import SwiftUI

extension View {
    /// Cap the content column while letting the surrounding screen fill its window.
    /// Uses the available layout width, so narrow iPad windows stay usable too.
    func readableContent(maxWidth: CGFloat = 680) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }

    /// Keep lists and forms centered against a continuous grouped background.
    func readableGroupedContent() -> some View {
        scrollContentBackground(.hidden)
            .readableContent()
            .background(Color(uiColor: .systemGroupedBackground))
    }
}
