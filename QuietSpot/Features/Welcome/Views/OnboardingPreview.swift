import SwiftUI

/// Local examples that introduce the experience without requesting access or saving data.
struct OnboardingPreview: View {
    enum Kind {
        case discovery, sharing, welcome
    }

    let kind: Kind
    @State private var sharedExample = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.accent)

            if kind == .discovery {
                Image("CafeHero")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 170)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .accessibilityHidden(true)

                Text("Your next quiet corner")
                    .font(.title3.bold())
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 16) { conditions }
                    VStack(alignment: .leading, spacing: 12) { conditions }
                }
            } else if kind == .sharing {
                HStack(spacing: 12) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.title2)
                        .foregroundStyle(AppColor.accent)
                        .padding(14)
                        .background(AppColor.accent.opacity(0.12), in: Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text("A little local knowledge")
                            .font(.headline)
                        Text("Example community insight")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Text("“The tables by the window are great for a quiet afternoon.”")
                    .font(.title3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(18)
                    .background(Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))

                Button {
                    sharedExample.toggle()
                } label: {
                    Label(sharedExample ? "Practice update shared" : "Try sharing an update", systemImage: sharedExample ? "checkmark.circle.fill" : "plus.bubble")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .tint(AppColor.accent)
                Text("Just practice. Nothing is posted.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Image("CafeHero")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 170)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .accessibilityHidden(true)
                Label("A place for you", systemImage: "person.crop.circle")
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                Text("New here? You can create an account on the next screen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(AppColor.accent.opacity(0.15), lineWidth: 1)
        }
        .padding(12)
        .background(AppColor.accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 36))
    }

    private var title: String {
        switch kind {
        case .discovery: "A glimpse inside"
        case .sharing: "Try an update"
        case .welcome: "Welcome to QuietSpot"
        }
    }

    private var symbol: String {
        switch kind {
        case .discovery: "location.circle"
        case .sharing: "hand.tap"
        case .welcome: "cup.and.saucer"
        }
    }

    private var conditions: some View {
        Group {
            Label("Quiet", systemImage: "ear")
            Label("Strong Wi-Fi", systemImage: "wifi")
            Label("Outlets", systemImage: "powerplug")
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(AppColor.accent)
    }
}
