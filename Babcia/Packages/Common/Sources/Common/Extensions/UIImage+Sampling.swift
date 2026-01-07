import UIKit

public extension UIImage {
    func sampledBottomColor() -> UIColor? {
        guard let cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return nil }

        let cropRect = CGRect(x: 0, y: height - 1, width: width, height: 1)
        guard let cropped = cgImage.cropping(to: cropRect) else { return nil }

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixelData = [UInt8](repeating: 0, count: width * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(cropped, in: CGRect(x: 0, y: 0, width: width, height: 1))

        var totalR = 0
        var totalG = 0
        var totalB = 0
        let pixelCount = max(1, width)

        for index in stride(from: 0, to: pixelData.count, by: bytesPerPixel) {
            totalR += Int(pixelData[index])
            totalG += Int(pixelData[index + 1])
            totalB += Int(pixelData[index + 2])
        }

        let r = CGFloat(totalR) / CGFloat(pixelCount) / 255.0
        let g = CGFloat(totalG) / CGFloat(pixelCount) / 255.0
        let b = CGFloat(totalB) / CGFloat(pixelCount) / 255.0

        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}
