import Core
import Foundation
import UIKit

public struct VerifyRoomUseCase: Sendable {
    private let repository: ScanRepositoryProtocol

    public init(repository: ScanRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(
        room: Room,
        afterImage: UIImage,
        apiKey: String,
        modeCharacter: BabciaCharacter,
        captureSource: CaptureSource = .verify
    ) async throws -> RoomVerificationOutcome {
        guard !apiKey.isEmpty else {
            throw ScanRoomError.missingAPIKey
        }

        var updatedRoom = room

        let capturePath = try saveCaptureImage(afterImage, roomID: room.id)
        let capture = UserCapture(
            roomID: room.id,
            date: Date(),
            path: capturePath,
            source: captureSource
        )
        updatedRoom.userCaptures.append(capture)

        let beforeImage = loadImageIfAvailable(room.lastVerifiedScanPath)
        let result = try await repository.verifyRoom(
            beforeImage: beforeImage,
            afterImage: afterImage,
            tasks: room.tasks,
            character: room.character,
            apiKey: apiKey
        )

        let threshold = modeCharacter.verificationConfidenceThreshold
        var gainedXP = 0
        var didGain = false

        for verification in result.tasks {
            guard let index = updatedRoom.tasks.firstIndex(where: { $0.id == verification.taskID }) else { continue }
            var task = updatedRoom.tasks[index]

            if task.verificationState == .verified {
                continue
            }

            let isVerified = verification.status == .verified
            if isVerified {
                task.isCompleted = true
                task.completedAt = Date()
                task.verificationState = .verified
                task.verificationConfidence = verification.confidence
                if verification.confidence < threshold {
                    task.verificationNote = [verification.note, "Low confidence"].compactMap { $0 }.joined(separator: " • ")
                } else {
                    task.verificationNote = verification.note
                }
                updatedRoom.tasks[index] = task
                gainedXP += task.xpReward
                didGain = true
            } else {
                task.verificationState = .pending
                task.verificationConfidence = verification.confidence
                task.verificationNote = verification.note
                updatedRoom.tasks[index] = task
            }
        }

        if gainedXP > 0 {
            updatedRoom.totalXP += gainedXP
        }

        if didGain {
            updatedRoom.recordActivity()
        }

        if updatedRoom.pendingTaskCount == 0 {
            updatedRoom.verificationAttempts = 0
            updatedRoom.lastVerifiedAt = Date()
            updatedRoom.lastVerifiedScanPath = capturePath
        } else {
            updatedRoom.verificationAttempts += 1
        }

        return RoomVerificationOutcome(
            room: updatedRoom,
            needsRescan: result.needsRescan,
            summary: result.summary
        )
    }

    private func loadImageIfAvailable(_ path: String?) -> UIImage? {
        guard let path else { return nil }
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documentsURL.appendingPathComponent(path)
        return UIImage(contentsOfFile: url.path)
    }

    private func saveCaptureImage(_ image: UIImage, roomID: UUID) throws -> String {
        let fileName = "verify_\(roomID.uuidString)_\(UUID().uuidString).jpg"
        let url = try captureURL(for: fileName)
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw ScanRoomError.imageEncodingFailed
        }
        try imageData.write(to: url, options: .atomic)
        return fileName
    }

    private func captureURL(for fileName: String) throws -> URL {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw ScanRoomError.documentsDirectoryUnavailable
        }
        return documentsURL.appendingPathComponent(fileName)
    }
}
