import Foundation
import UIKit
import Core

public final class ScanRepository: ScanRepositoryProtocol {
    private let gemini = GeminiService.shared
    private let homeAssistant = HomeAssistantService.shared

    public init() {}

    public func analyzeRoom(
        image: UIImage,
        character: BabciaCharacter,
        apiKey: String
    ) async throws -> (tasks: [String], advice: String) {
        try await gemini.analyzeRoom(roomImage: image, character: character, apiKey: apiKey)
    }

    public func generateDreamVision(
        image: UIImage,
        character: BabciaCharacter,
        apiKey: String
    ) async throws -> UIImage {
        try await gemini.generateDreamVision(roomImage: image, character: character, apiKey: apiKey)
    }

    public func verifyRoom(
        beforeImage: UIImage?,
        afterImage: UIImage,
        tasks: [CleaningTask],
        character: BabciaCharacter,
        apiKey: String
    ) async throws -> RoomVerificationResult {
        try await gemini.verifyRoom(
            beforeImage: beforeImage,
            afterImage: afterImage,
            tasks: tasks,
            character: character,
            apiKey: apiKey
        )
    }

    public func testGeminiKey(_ key: String) async throws -> Bool {
        try await gemini.testAPIKey(key)
    }

    public func fetchHomeAssistantCameras(
        baseURL: String,
        token: String
    ) async throws -> [HACamera] {
        try await homeAssistant.fetchCameras(baseURL: baseURL, token: token)
        return await homeAssistant.cameras
    }

    public func fetchHomeAssistantSnapshot(
        baseURL: String,
        token: String,
        entityId: String
    ) async throws -> UIImage {
        try await homeAssistant.getSnapshot(baseURL: baseURL, token: token, entityId: entityId)
    }

    public func testHomeAssistantConnection(
        baseURL: String,
        token: String
    ) async -> Bool {
        await homeAssistant.testConnection(baseURL: baseURL, token: token)
    }
}
