import Foundation

struct UserProfile {
    let id: String
    var displayName = "You"
    var photoData: Data? = nil

    init(id: String = "preview-user", displayName: String = "You", photoData: Data? = nil) {
        self.id = id
        self.displayName = displayName
        self.photoData = photoData
    }
}
