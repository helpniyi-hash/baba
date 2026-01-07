import Foundation

public protocol SettingsRepositoryProtocol: Sendable {
    func loadSettings() async throws -> AppSettings
    func saveSettings(_ settings: AppSettings) async throws
}
