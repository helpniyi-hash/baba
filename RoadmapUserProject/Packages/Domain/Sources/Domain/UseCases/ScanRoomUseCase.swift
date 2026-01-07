import Core
import Foundation
import UIKit

public struct ScanRoomUseCase: Sendable {
    private let repository: ScanRepositoryProtocol

    public init(repository: ScanRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(
        room: Room,
        image: UIImage,
        apiKey: String,
        captureSource: CaptureSource = .scan
    ) async throws -> Room {
        guard !apiKey.isEmpty else {
            throw ScanRoomError.missingAPIKey
        }

        var updatedRoom = room
        updatedRoom.archiveCurrentScan()

        if let capturePath = try? saveCaptureImage(image, roomID: room.id) {
            let capture = UserCapture(
                roomID: room.id,
                date: Date(),
                path: capturePath,
                source: captureSource
            )
            updatedRoom.userCaptures.append(capture)
        }

        let analysis = try await repository.analyzeRoom(
            image: image,
            character: room.character,
            apiKey: apiKey
        )

        updatedRoom.tasks = analysis.tasks.map { CleaningTask(title: $0) }
        updatedRoom.babciaAdvice = analysis.advice
        updatedRoom.lastScanDate = Date()
        updatedRoom.verificationAttempts = 0

        do {
            let dreamImage = try await repository.generateDreamVision(
                image: image,
                character: room.character,
                apiKey: apiKey
            )

            let fileName = "dream_\(room.id.uuidString)_\(UUID().uuidString).png"
            let url = try dreamVisionURL(for: fileName)
            guard let imageData = dreamImage.pngData() else {
                throw ScanRoomError.imageEncodingFailed
            }
            try imageData.write(to: url, options: .atomic)

            updatedRoom.dreamVisionPath = fileName
        } catch {
            // Keep tasks and advice even if the dream image fails.
        }

        return updatedRoom
    }

    private func dreamVisionURL(for fileName: String) throws -> URL {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw ScanRoomError.documentsDirectoryUnavailable
        }
        return documentsURL.appendingPathComponent(fileName)
    }

    private func saveCaptureImage(_ image: UIImage, roomID: UUID) throws -> String {
        let fileName = "capture_\(roomID.uuidString)_\(UUID().uuidString).jpg"
        let url = try dreamVisionURL(for: fileName)
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw ScanRoomError.imageEncodingFailed
        }
        try imageData.write(to: url, options: .atomic)
        return fileName
    }
}

public enum ScanRoomError: Error {
    case missingAPIKey
    case documentsDirectoryUnavailable
    case imageEncodingFailed
}
