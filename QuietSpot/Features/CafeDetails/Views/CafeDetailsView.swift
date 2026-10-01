import SwiftUI

struct CafeDetailsView: View {
    @Binding var cafe: CafeSnapshot
    @State private var showsCheckIn = false
    @State private var showsConfirmation = false
    @State private var didSubmitCheckIn = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Color.clear
                    .frame(height: 240)
                    .overlay {
                        Image(cafe.imageName)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .accessibilityLabel("Photo of \(cafe.name)")

                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(cafe.name)
                            .font(.title.bold())
                        Label(cafe.area, systemImage: "mappin.and.ellipse")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Button {
                        cafe.isFavorite.toggle()
                    } label: {
                        Image(systemName: cafe.isFavorite ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundStyle(cafe.isFavorite ? Color.red : AppColor.accent)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(cafe.isFavorite ? "Remove from favorites" : "Add to favorites")
                    .accessibilityValue(cafe.isFavorite ? "Saved" : "Not saved")
                }

                Text(cafe.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 14) {
                    Text("Recent check-ins")
                        .font(.title3.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text("The three latest community updates")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(cafe.recentCheckIns) { checkIn in
                        VStack(alignment: .leading, spacing: 12) {
                            Label(checkIn.time, systemImage: "clock")
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
            CafeCheckInView(cafe: cafe) { checkIn in
                cafe.record(checkIn)
                didSubmitCheckIn = true
            }
        }
        .alert("Check-in added", isPresented: $showsConfirmation) {
            Button("Done", role: .cancel) {}
        } message: {
            Text("Thanks for sharing the latest conditions at \(cafe.name).")
        }
    }
}

#Preview {
    NavigationStack {
        CafeDetailsView(cafe: .constant(CafeSampleData.cafes[0]))
    }
}
