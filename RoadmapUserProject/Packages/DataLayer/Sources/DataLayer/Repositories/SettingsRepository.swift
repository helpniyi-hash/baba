import Foundation
import Core

public final class SettingsRepository: SettingsRepositoryProtocol {
    private enum Keys {
        static let hasCompletedSetup = "hasCompletedSetup"
        static let geminiAPIKey = "geminiAPIKey"
        static let homeAssistantURL = "homeAssistantURL"
        static let homeAssistantToken = "homeAssistantToken"
        static let defaultCameraEntityId = "defaultCameraEntityId"
        static let selectedCharacter = "selectedCharacter"
        static let lastMainCharacter = "lastMainCharacter"
        static let theme = "appTheme"
    }

    public init() {}

    public func loadSettings() async throws -> AppSettings {
        let defaults = UserDefaults.standard
        let hasCompletedSetup = defaults.bool(forKey: Keys.hasCompletedSetup)
        let homeAssistantURL = defaults.string(forKey: Keys.homeAssistantURL) ?? ""
        let defaultCameraEntityId = defaults.string(forKey: Keys.defaultCameraEntityId) ?? ""

        let selectedRaw = defaults.string(forKey: Keys.selectedCharacter)
        let selectedCharacter = BabciaCharacter(rawValue: selectedRaw ?? "") ?? .classic

        let lastMainRaw = defaults.string(forKey: Keys.lastMainCharacter)
        let lastMainCharacter = lastMainRaw.flatMap { BabciaCharacter(rawValue: $0) }

        let themeRaw = defaults.string(forKey: Keys.theme)
        let theme = themeRaw.flatMap { AppTheme(rawValue: $0) } ?? .system

        let geminiAPIKey = KeychainHelper.load(forKey: Keys.geminiAPIKey) ?? ""
        let homeAssistantToken = KeychainHelper.load(forKey: Keys.homeAssistantToken) ?? ""

        return AppSettings(
            hasCompletedSetup: hasCompletedSetup,
            geminiAPIKey: geminiAPIKey,
            homeAssistantURL: homeAssistantURL,
            homeAssistantToken: homeAssistantToken,
            defaultCameraEntityId: defaultCameraEntityId,
            selectedCharacter: selectedCharacter,
            lastMainCharacter: lastMainCharacter,
            theme: theme
        )
    }

    public func saveSettings(_ settings: AppSettings) async throws {
        let defaults = UserDefaults.standard
        defaults.set(settings.hasCompletedSetup, forKey: Keys.hasCompletedSetup)
        defaults.set(settings.homeAssistantURL, forKey: Keys.homeAssistantURL)
        defaults.set(settings.defaultCameraEntityId, forKey: Keys.defaultCameraEntityId)
        defaults.set(settings.selectedCharacter.rawValue, forKey: Keys.selectedCharacter)
        defaults.set(settings.theme.rawValue, forKey: Keys.theme)

        if let lastMain = settings.lastMainCharacter {
            defaults.set(lastMain.rawValue, forKey: Keys.lastMainCharacter)
        } else {
            defaults.removeObject(forKey: Keys.lastMainCharacter)
        }

        KeychainHelper.save(settings.geminiAPIKey, forKey: Keys.geminiAPIKey)
        KeychainHelper.save(settings.homeAssistantToken, forKey: Keys.homeAssistantToken)
    }
}
