// Profile details shown in the account screen and on community posts.

import Foundation

struct UserProfile {
    let id: String
    var displayName: String
    var photoData: Data?

    init(id: String = "preview-user", displayName: String = "You", photoData: Data? = nil) {
        self.id = id
        self.displayName = displayName
        self.photoData = photoData
    }
}
