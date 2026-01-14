import Foundation
import UIKit

/// DreamRoom engine behavior is intentional and protected. Do not refactor casually.
public struct DreamRoomEngine {
    public init() {}

    public func generate(
        beforePhotoData: Data,
        context: DreamRoomContext,
        config: DreamRoomConfig
    ) async throws -> DreamRoomResult {
        let rawImageData = try await generateRawImageData(
            beforePhotoData: beforePhotoData,
            context: context,
            config: config
        )

        let normalization = try DreamRoomImageNormalizer.normalizeIfNeeded(
            rawImageData: rawImageData,
            targetSize: DreamRoomImageNormalizer.heroSize
        )

        return DreamRoomResult(
            heroImageData: normalization.heroImageData,
            rawImageData: rawImageData,
            metadata: DreamRoomMetadata(
                rawPixelSize: normalization.rawPixelSize,
                wasNormalized: normalization.wasNormalized
            )
        )
    }
}

public struct DreamRoomConfig: Sendable {
    public let apiKey: String
    public let modelEndpoint: URL
    public let timeoutSeconds: TimeInterval

    public init(
        apiKey: String,
        modelEndpoint: URL = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent")!,
        timeoutSeconds: TimeInterval = 120
    ) {
        self.apiKey = apiKey
        self.modelEndpoint = modelEndpoint
        self.timeoutSeconds = timeoutSeconds
    }
}

public struct DreamRoomContext: Sendable {
    public let characterPrompt: String

    public init(characterPrompt: String) {
        self.characterPrompt = characterPrompt
    }
}

public struct DreamRoomResult: Sendable {
    public let heroImageData: Data
    public let rawImageData: Data
    public let metadata: DreamRoomMetadata
}

public struct DreamRoomMetadata: Sendable {
    public let rawPixelSize: DreamRoomPixelSize?
    public let wasNormalized: Bool
}

public struct DreamRoomPixelSize: Sendable, Equatable {
    public let width: Int
    public let height: Int
}

private extension DreamRoomEngine {
    func generateRawImageData(
        beforePhotoData: Data,
        context: DreamRoomContext,
        config: DreamRoomConfig
    ) async throws -> Data {
        guard let image = UIImage(data: beforePhotoData),
              let resizedImage = image.resizedTo(maxDimension: 1024),
              let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw DreamRoomEngineError.imageProcessingFailed
        }

        let base64Image = imageData.base64EncodedString()

        let prompt = """
        Analyze the provided image to identify its permanent structural elements (walls, floors, windows, ceiling) and major furniture fixtures.

        1. ACTION (Decluttering):
           - Remove ALL 'loose' objects: wires, trash, bottles, papers, clothes, dishes, countertop appliances, bins, vacuum cleaners, laundry baskets
           - Keep ONLY 'major' furniture: cabinets, tables, chairs, sofas, major appliances (fridge, stove, oven)
           - ALL surfaces (floors, tables, counters) must be COMPLETELY EMPTY and pristine

        \(context.characterPrompt)

        3. GEOMETRY:
           - Maintain the EXACT perspective and camera angle of the original image
           - Keep the window and light source positions identical
           - Same room layout, same architectural features

        4. OUTPUT SIZE:
           - Generate image in PORTRAIT orientation (3:4 aspect ratio)
           - Target pixel size: 1200x1600
           - Keep the main subject centered with clean edges
        """

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "responseModalities": ["IMAGE"]
            ]
        ]

        var requestURL = config.modelEndpoint
        if var components = URLComponents(url: requestURL, resolvingAgainstBaseURL: false) {
            let apiKeyItem = URLQueryItem(name: "key", value: config.apiKey)
            if let existingItems = components.queryItems, !existingItems.isEmpty {
                components.queryItems = existingItems + [apiKeyItem]
            } else {
                components.queryItems = [apiKeyItem]
            }
            if let updatedURL = components.url {
                requestURL = updatedURL
            }
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = config.timeoutSeconds

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DreamRoomEngineError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw DreamRoomEngineError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        return try DreamRoomResponseParser.parseImageResponse(data)
    }
}

enum DreamRoomEngineError: Error, LocalizedError {
    case imageProcessingFailed
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case parsingFailed
    case noImageInResponse

    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process the image"
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let statusCode, let message):
            return "API error (\(statusCode)): \(message)"
        case .parsingFailed:
            return "Failed to parse API response"
        case .noImageInResponse:
            return "No image found in API response"
        }
    }
}

enum DreamRoomResponseParser {
    static func parseImageResponse(_ data: Data) throws -> Data {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else {
            throw DreamRoomEngineError.parsingFailed
        }

        for part in parts {
            if let inlineData = part["inlineData"] as? [String: Any],
               let base64Data = inlineData["data"] as? String,
               let imageData = Data(base64Encoded: base64Data) {
                return imageData
            }

            if let inlineData = part["inline_data"] as? [String: Any],
               let base64Data = inlineData["data"] as? String,
               let imageData = Data(base64Encoded: base64Data) {
                return imageData
            }
        }

        throw DreamRoomEngineError.noImageInResponse
    }
}

enum DreamRoomImageNormalizer {
    static let heroSize = CGSize(width: 1200, height: 1600)

    struct NormalizationResult {
        let heroImageData: Data
        let rawPixelSize: DreamRoomPixelSize?
        let wasNormalized: Bool
    }

    static func normalizeIfNeeded(
        rawImageData: Data,
        targetSize: CGSize
    ) throws -> NormalizationResult {
        guard let rawImage = UIImage(data: rawImageData) else {
            throw DreamRoomEngineError.imageProcessingFailed
        }

        let rawSize = rawImage.size
        let rawPixelSize = DreamRoomPixelSize(width: Int(rawSize.width), height: Int(rawSize.height))

        let needsNormalization = Int(rawSize.width) != Int(targetSize.width)
            || Int(rawSize.height) != Int(targetSize.height)

        guard needsNormalization else {
            return NormalizationResult(
                heroImageData: rawImageData,
                rawPixelSize: rawPixelSize,
                wasNormalized: false
            )
        }

        let cropRect = centeredCropRect(sourceSize: rawSize, targetAspect: targetSize.width / targetSize.height)
        let croppedImage = cropImage(rawImage, to: cropRect)
        let resizedImage = resizeImage(croppedImage, to: targetSize)

        guard let heroImageData = resizedImage.jpegData(compressionQuality: 0.9) else {
            throw DreamRoomEngineError.imageProcessingFailed
        }

        return NormalizationResult(
            heroImageData: heroImageData,
            rawPixelSize: rawPixelSize,
            wasNormalized: true
        )
    }

    private static func centeredCropRect(sourceSize: CGSize, targetAspect: CGFloat) -> CGRect {
        let sourceAspect = sourceSize.width / sourceSize.height

        if sourceAspect > targetAspect {
            let newWidth = sourceSize.height * targetAspect
            let xOffset = (sourceSize.width - newWidth) / 2.0
            return CGRect(x: xOffset, y: 0, width: newWidth, height: sourceSize.height)
        } else {
            let newHeight = sourceSize.width / targetAspect
            let yOffset = (sourceSize.height - newHeight) / 2.0
            return CGRect(x: 0, y: yOffset, width: sourceSize.width, height: newHeight)
        }
    }

    private static func cropImage(_ image: UIImage, to rect: CGRect) -> UIImage {
        let scale = image.scale
        let scaledRect = CGRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.size.width * scale,
            height: rect.size.height * scale
        )

        guard let cgImage = image.cgImage?.cropping(to: scaledRect) else {
            return image
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    private static func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized ?? image
    }
}

private extension UIImage {
    func resizedTo(maxDimension: CGFloat) -> UIImage? {
        let aspectRatio = size.width / size.height
        let newSize: CGSize

        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage
    }
}
