import SwiftUI

struct MapPreviewView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ContentUnavailableView("Nearby cafés", systemImage: "map", description: Text("Your nearby café map is coming next."))
                }
                Section {
                    MapRadiusControl()
                } footer: {
                    Text("Choose a proximity radius around your location for the upcoming map.")
                }
            }
            .navigationTitle("Map")
        }
    }
}
