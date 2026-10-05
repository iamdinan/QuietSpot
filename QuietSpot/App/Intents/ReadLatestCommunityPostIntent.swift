import AppIntents

struct ReadLatestCommunityPostIntent: AppIntent {
    static var title: LocalizedStringResource = "Read Latest Community Post"
    static var description = IntentDescription("Read the latest saved QuietSpot community post, its author, café, and age.")
    static var supportedModes: IntentModes { [.background] }
    static var authenticationPolicy: IntentAuthenticationPolicy { .requiresAuthentication }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let message = CommunityPostSiriSnapshot.load()?.message()
            ?? "Open QuietSpot and sign in to sync community posts first."
        return .result(value: message, dialog: "\(message)")
    }
}
