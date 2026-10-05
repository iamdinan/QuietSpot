import Foundation
import Observation
import PhotosUI
import SwiftUI

@MainActor
@Observable
final class EditProfileViewModel {
    var displayName: String
    var photoData: Data?
    var photoErrorMessage: String?
    private(set) var isLoadingPhoto = false
    @ObservationIgnored private var photoRequestID = UUID()

    init(profile: UserProfile) {
        displayName = profile.displayName
        photoData = profile.photoData
    }

    var trimmedName: String { displayName.trimmingCharacters(in: .whitespacesAndNewlines) }

    func hasChanges(comparedTo profile: UserProfile) -> Bool {
        displayName != profile.displayName || photoData != profile.photoData
    }

    func loadPhoto(_ selection: PhotosPickerItem?) async {
        let requestID = UUID()
        photoRequestID = requestID
        isLoadingPhoto = selection != nil
        photoErrorMessage = nil
        guard let selection else { return }
        defer { if photoRequestID == requestID { isLoadingPhoto = false } }
        do {
            guard let data = try await selection.loadTransferable(type: Data.self) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            try Task.checkCancellation()
            guard photoRequestID == requestID else { return }
            photoData = try ProfilePhotoService.resizedJPEG(from: data)
        } catch is CancellationError {
            // A newer selection or a closed editor superseded this request.
        } catch {
            guard photoRequestID == requestID, !Task.isCancelled else { return }
            photoErrorMessage = "Please try again or choose a different photo."
        }
    }

    func save(using authentication: AuthenticationViewModel) async -> Bool {
        guard !trimmedName.isEmpty, !isLoadingPhoto, !authentication.isBusy else { return false }
        return await authentication.saveProfile(displayName: trimmedName, photoData: photoData)
    }
}
