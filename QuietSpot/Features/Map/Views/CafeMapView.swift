import SwiftUI
import MapKit

struct CafeMapView: View {
    @Binding var cafes: [CafeSnapshot]
    @AppStorage("mapRadiusKilometers") private var radius = 5.0
    @StateObject private var location = LocationProvider()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @State private var path: [UUID] = []
    @State private var hasCenteredOnLocation = false
    @State private var isVisible = false
    @State private var camera: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 6.9147, longitude: 79.8610),
            latitudinalMeters: 12000, longitudinalMeters: 12000
        )
    )

    private var nearbyCafes: [CafeSnapshot] {
        guard let userLocation = location.currentLocation else { return cafes }
        return cafes.filter {
            userLocation.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude)) <= radius * 1000
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            Map(position: $camera) {
                UserAnnotation()

                if let userLocation = location.currentLocation {
                    MapCircle(center: userLocation.coordinate, radius: radius * 1000)
                        .foregroundStyle(AppColor.accent.opacity(0.12))
                        .stroke(AppColor.accent.opacity(0.6), lineWidth: 2)
                }

                ForEach(nearbyCafes) { cafe in
                    Annotation(cafe.name, coordinate: cafe.coordinate) {
                        Button {
                            path.append(cafe.id)
                        } label: {
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.headline)
                                .foregroundStyle(Color(uiColor: .systemBackground))
                                .frame(width: 44, height: 44)
                                .background(AppColor.accent, in: Circle())
                                .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(cafe.name), \(cafe.area)")
                        .accessibilityHint("Opens café details")
                    }
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 10) {
                    locationSummary
                    MapRadiusControl()
                }
                .padding(16)
                .background(.regularMaterial)
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if location.currentLocation != nil {
                            centerOnUser()
                        } else {
                            location.start()
                        }
                    } label: {
                        Label("My location", systemImage: "location.fill")
                    }
                    .disabled(location.permissionDenied)
                }
            }
            .navigationDestination(for: UUID.self) { cafeID in
                if let index = cafes.firstIndex(where: { $0.id == cafeID }) {
                    CafeDetailsView(cafe: $cafes[index])
                }
            }
            .onAppear {
                isVisible = true
                location.start()
            }
            .onDisappear {
                isVisible = false
                location.stop()
            }
            .onChange(of: scenePhase) {
                if scenePhase == .active && isVisible && path.isEmpty {
                    location.start()
                } else {
                    location.stop()
                }
            }
            .onChange(of: location.currentLocation) {
                if !hasCenteredOnLocation && location.currentLocation != nil {
                    centerOnUser()
                    hasCenteredOnLocation = true
                }
            }
            .onChange(of: radius) { centerOnUser() }
        }
    }

    @ViewBuilder
    private var locationSummary: some View {
        if location.permissionDenied {
            Text("Location access is off. Showing cafés around Colombo.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Open location settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
        } else if let message = location.errorMessage {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Try location again") { location.start() }
        } else if location.currentLocation == nil {
            Label("Finding your location · Colombo preview", systemImage: "location")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            Text(nearbyCafes.isEmpty
                 ? "No cafés within \(Int(radius)) km. Try a larger radius."
                 : "\(nearbyCafes.count) café\(nearbyCafes.count == 1 ? "" : "s") within \(Int(radius)) km")
                .font(.subheadline.weight(.semibold))
            if location.isApproximate {
                Text("Using your approximate location.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func centerOnUser() {
        guard let userLocation = location.currentLocation else { return }
        camera = .region(MKCoordinateRegion(
            center: userLocation.coordinate,
            latitudinalMeters: radius * 2600,
            longitudinalMeters: radius * 2600
        ))
    }
}

#Preview {
    CafeMapView(cafes: .constant(CafeSampleData.cafes))
}
