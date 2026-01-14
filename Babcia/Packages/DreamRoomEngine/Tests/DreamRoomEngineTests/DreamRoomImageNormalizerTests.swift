import XCTest
import UIKit
@testable import DreamRoomEngine

final class DreamRoomImageNormalizerTests: XCTestCase {
    func testNormalizationPassThroughForExactSize() throws {
        let image = makeImage(width: 1200, height: 1600, color: .red)
        let rawData = try XCTUnwrap(image.jpegData(compressionQuality: 1.0))

        let result = try DreamRoomImageNormalizer.normalizeIfNeeded(
            rawImageData: rawData,
            targetSize: DreamRoomImageNormalizer.heroSize
        )

        XCTAssertEqual(result.heroImageData, rawData)
        XCTAssertEqual(result.rawPixelSize, DreamRoomPixelSize(width: 1200, height: 1600))
        XCTAssertFalse(result.wasNormalized)
    }

    func testNormalizationForSquareImage() throws {
        let image = makeImage(width: 1000, height: 1000, color: .blue)
        let rawData = try XCTUnwrap(image.jpegData(compressionQuality: 1.0))

        let result = try DreamRoomImageNormalizer.normalizeIfNeeded(
            rawImageData: rawData,
            targetSize: DreamRoomImageNormalizer.heroSize
        )

        let heroImage = try XCTUnwrap(UIImage(data: result.heroImageData))
        XCTAssertEqual(Int(heroImage.size.width), 1200)
        XCTAssertEqual(Int(heroImage.size.height), 1600)
        XCTAssertEqual(result.rawPixelSize, DreamRoomPixelSize(width: 1000, height: 1000))
        XCTAssertTrue(result.wasNormalized)
    }

    private func makeImage(width: Int, height: Int, color: UIColor) -> UIImage {
        let size = CGSize(width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
}
