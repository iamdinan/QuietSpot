import SwiftUI

struct MapRadiusControl: View {
    @AppStorage("mapRadiusKilometers") private var radius = 5.0

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            LabeledContent {
                Text("\(Int(radius)) km")
                    .monospacedDigit()
            } label: {
                Label("Map radius", systemImage: "location.circle")
            }

            Slider(value: $radius, in: 1...10, step: 1) {
                Text("Map radius")
            } minimumValueLabel: {
                Text("1 km")
            } maximumValueLabel: {
                Text("10 km")
            }
            .tint(AppColor.accent)
            .accessibilityValue("\(Int(radius)) kilometers")
            .accessibilityHint("Adjusts the distance used to find nearby cafés, from 1 to 10 kilometers")
        }
        .padding(.vertical, 4)
    }
}
