import Foundation

struct UserProfile {
    // A stable identity for the local account until authentication is connected.
    static let localUserID = UUID(uuidString: "8F3640CB-02E4-45A5-B56A-87B32BDB83F1")!

    let id = localUserID
    var displayName = "You"
    var photoData: Data? = nil
}
