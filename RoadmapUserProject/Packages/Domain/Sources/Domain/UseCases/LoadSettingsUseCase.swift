import Core

public struct LoadSettingsUseCase: Sendable {
    private let repository: SettingsRepositoryProtocol

    public init(repository: SettingsRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> AppSettings {
        try await repository.loadSettings()
    }
}
