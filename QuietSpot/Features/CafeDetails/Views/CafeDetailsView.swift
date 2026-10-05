import SwiftUI

struct CafeDetailsView: View {
    @Binding var cafe: CafeSnapshot
    @State private var showsCheckIn = false
    @State private var showsConfirmation = false
    @State private var didSubmitCheckIn = false
    @Environment(AuthenticationViewModel.self) private var authentication

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Color.clear
                    .frame(height: 240)
                    .overlay {
                        CafeImage(cafe: cafe, allowsRetry: true)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(cafe.name)
                            .font(.title.bold())
                            .accessibilityAddTraits(.isHeader)
                        Label(cafe.area, systemImage: "mappin.and.ellipse")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Button {
                        Task {
                            await authentication.setFavorite(cafeID: cafe.id, enabled: !cafe.isFavorite)
                        }
                    } label: {
                        Image(systemName: cafe.isFavorite ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundStyle(cafe.isFavorite ? Color.red : AppColor.accent)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .disabled(!authentication.isUserDataReady || authentication.savingFavoriteIDs.contains(cafe.id))
                    .accessibilityLabel(cafe.isFavorite ? "Remove from favorites" : "Add to favorites")
                    .accessibilityValue(cafe.isFavorite ? "Saved" : "Not saved")
                    .accessibilityAddTraits(cafe.isFavorite ? [.isSelected] : [])
                }

                Text(cafe.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 14) {
                    Text("Recent check-ins")
                        .font(.title3.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text(checkInSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(cafe.recentCheckIns) { checkIn in
                        VStack(alignment: .leading, spacing: 12) {
                            Label {
                                CheckInTimeText(date: checkIn.createdAt, fallback: checkIn.time)
                            } icon: {
                                Image(systemName: "clock")
                            }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            CafeStatusGrid(checkIn: checkIn)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Café details")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton("Check in here") { showsCheckIn = true }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.bar)
        }
        .sheet(isPresented: $showsCheckIn, onDismiss: {
            if didSubmitCheckIn {
                showsConfirmation = true
                didSubmitCheckIn = false
            }
        }) {
            CafeCheckInView(cafe: cafe) {
                didSubmitCheckIn = true
            }
        }
        .alert("Check-in saved", isPresented: $showsConfirmation) {
            Button("Done", role: .cancel) {}
        } message: {
            Text("Your check-in at \(cafe.name) has been saved to Firebase.")
        }
    }

    private var checkInSummary: String {
        if cafe.statusErrorMessage != nil { return "Recent check-ins are unavailable. Try refreshing Home." }
        if cafe.isLoadingStatus { return "Loading recent check-ins…" }
        return cafe.recentCheckIns.isEmpty
            ? "No check-ins yet. Be the first to share the conditions here."
            : "The three most recent check-ins from the community"
    }
}

#Preview {
    NavigationStack {
        CafeDetailsView(cafe: .constant(CafeSnapshot(
            name: "Café preview", area: "Colombo",
            description: "A comfortable spot for coffee and conversation.",
            latitude: 6.9147, longitude: 79.8610
        )))
    }
    .environment(\.loadsCafeImages, false)
    .environment(AuthenticationViewModel())
}
