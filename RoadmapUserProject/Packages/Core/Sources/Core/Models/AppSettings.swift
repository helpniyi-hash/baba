import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public var hasCompletedSetup: Bool
    public var geminiAPIKey: String
    public var homeAssistantURL: String
    public var homeAssistantToken: String
    public var defaultCameraEntityId: String
    public var selectedCharacter: BabciaCharacter
    public var lastMainCharacter: BabciaCharacter?
    public var theme: AppTheme

    public init(
        hasCompletedSetup: Bool = false,
        geminiAPIKey: String = "",
        homeAssistantURL: String = "",
        homeAssistantToken: String = "",
        defaultCameraEntityId: String = "",
        selectedCharacter: BabciaCharacter = .classic,
        lastMainCharacter: BabciaCharacter? = nil,
        theme: AppTheme = .system
    ) {
        self.hasCompletedSetup = hasCompletedSetup
        self.geminiAPIKey = geminiAPIKey
        self.homeAssistantURL = homeAssistantURL
        self.homeAssistantToken = homeAssistantToken
        self.defaultCameraEntityId = defaultCameraEntityId
        self.selectedCharacter = selectedCharacter
        self.lastMainCharacter = lastMainCharacter
        self.theme = theme
    }
}
