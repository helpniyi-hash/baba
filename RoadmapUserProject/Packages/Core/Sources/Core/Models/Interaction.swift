import Foundation

public struct Interaction: Codable, Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let characterId: String
    public let userAction: String
    public let aiResponse: String

    public init(characterId: String, userAction: String, aiResponse: String) {
        self.id = UUID()
        self.timestamp = Date()
        self.characterId = characterId
        self.userAction = userAction
        self.aiResponse = aiResponse
    }
}
