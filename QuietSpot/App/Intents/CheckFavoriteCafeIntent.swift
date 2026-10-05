import AppIntents

struct CheckFavoriteCafeIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Favourite Café Stats"
    static var description = IntentDescription("Read the latest saved favourite café check-in, including noise, Wi-Fi, outlets, crowd, and report age.")
    static var supportedModes: IntentModes { [.background] }
    static var authenticationPolicy: IntentAuthenticationPolicy { .requiresAuthentication }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let message = FavoriteCafeSiriResponse.message(snapshot: PulseWidgetStore().load())
        return .result(value: message, dialog: "\(message)")
    }
}

struct QuietSpotShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CheckFavoriteCafeIntent(),
            phrases: [
                "Check my favourite cafés in \(.applicationName)",
                "Check my favorite cafes in \(.applicationName)",
                "Check cafe stats in \(.applicationName)"
            ],
            shortTitle: "Café Stats",
            systemImageName: "cup.and.saucer.fill"
        )
    }
}
