import Foundation
import ImageIO
import Testing
import UIKit
@testable import QuietSpot

@Suite("Profile photo processing")
@MainActor
struct ProfilePhotoTests {
    @Test("Large photos become JPEGs bounded to 512 pixels without stretching")
    func resizeLargePhoto() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 1200, height: 600), format: format).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1200, height: 600))
        }
        let result = try ProfilePhotoService.resizedJPEG(from: image.pngData()!)
        let decoded = try #require(UIImage(data: result)?.cgImage)
        #expect(decoded.width == 512)
        #expect(decoded.height == 256)
        let source = try #require(CGImageSourceCreateWithData(result as CFData, nil))
        #expect(CGImageSourceGetType(source) as String? == "public.jpeg")
    }

    @Test("Invalid image data fails rather than saving a broken photo", arguments: [Data(), Data("not an image".utf8)])
    func corruptPhoto(data: Data) {
        #expect(throws: CocoaError.self) { try ProfilePhotoService.resizedJPEG(from: data) }
    }
}
