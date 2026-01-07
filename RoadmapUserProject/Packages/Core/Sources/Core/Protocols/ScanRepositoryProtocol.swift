import Foundation
import UIKit

public protocol ScanRepositoryProtocol: Sendable {
    func analyzeRoom(
        image: UIImage,
        character: BabciaCharacter,
        apiKey: String
    ) async throws -> (tasks: [String], advice: String)

    func generateDreamVision(
        image: UIImage,
        character: BabciaCharacter,
        apiKey: String
    ) async throws -> UIImage

    func verifyRoom(
        beforeImage: UIImage?,
        afterImage: UIImage,
        tasks: [CleaningTask],
        character: BabciaCharacter,
        apiKey: String
    ) async throws -> RoomVerificationResult

    func testGeminiKey(_ key: String) async throws -> Bool

    func fetchHomeAssistantCameras(
        baseURL: String,
        token: String
    ) async throws -> [HACamera]

    func fetchHomeAssistantSnapshot(
        baseURL: String,
        token: String,
        entityId: String
    ) async throws -> UIImage

    func testHomeAssistantConnection(
        baseURL: String,
        token: String
    ) async -> Bool
}
