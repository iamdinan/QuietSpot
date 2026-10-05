import SwiftUI

private struct TabScreenTitle: ViewModifier {
    let title: String
    let systemImage: String

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: systemImage)
                            .foregroundStyle(AppColor.accent)
                            .accessibilityHidden(true)
                        Text(title)
                            .foregroundStyle(.primary)
                    }
                    .font(.headline.weight(.semibold))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(title)
                    .accessibilityAddTraits(.isHeader)
                }
            }
    }
}

extension View {
    func tabScreenTitle(_ title: String, systemImage: String) -> some View {
        modifier(TabScreenTitle(title: title, systemImage: systemImage))
    }
}
