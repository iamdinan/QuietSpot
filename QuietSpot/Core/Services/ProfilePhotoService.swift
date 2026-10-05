import Foundation
import ImageIO
import UIKit

enum ProfilePhotoService {
    static func resizedJPEG(from data: Data) throws -> Data {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 512,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
              let resized = UIImage(cgImage: thumbnail).jpegData(compressionQuality: 0.85) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return resized
    }
}
