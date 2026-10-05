import SwiftUI

struct AccessibilitySettingsView: View {
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    var body: some View {
        Form {
            Section {
                LabeledContent("VoiceOver", value: voiceOverEnabled ? "On" : "Off")
                    .accessibilityElement(children: .combine)
            } header: {
                Text("Screen reader")
            } footer: {
                Text("QuietSpot follows your device’s VoiceOver setting automatically. No separate app switch is needed.")
            }

            Section("Turn on VoiceOver") {
                Text("Open Settings, choose Accessibility, then VoiceOver, and turn it on.")
                Text("You can also ask Siri to turn VoiceOver on or off.")
            }

            Section("Using QuietSpot") {
                Text("Touch an item to hear its description. Swipe right or left to move between items.")
                Text("Double-tap to activate the selected item. Swipe with three fingers to scroll.")
                Text("On the map radius slider, swipe up or down to adjust the distance.")
            }

            Section {
                Link("Apple’s VoiceOver guide", destination: URL(string: "https://support.apple.com/guide/iphone/iph3e2e415f/ios")!)
                    .accessibilityHint("Opens Apple Support in your browser")
            }
        }
        .readableGroupedContent()
        .navigationTitle("Accessibility")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { AccessibilitySettingsView() }
}
