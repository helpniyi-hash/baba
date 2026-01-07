import Core

public struct SaveSettingsUseCase: Sendable {
    private let repository: SettingsRepositoryProtocol

    public init(repository: SettingsRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(_ settings: AppSettings) async throws {
        try await repository.saveSettings(settings)
    }
}
