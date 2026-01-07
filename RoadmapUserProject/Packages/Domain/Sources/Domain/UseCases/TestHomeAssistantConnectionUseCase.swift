import Core

public struct TestHomeAssistantConnectionUseCase: Sendable {
    private let repository: ScanRepositoryProtocol

    public init(repository: ScanRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(baseURL: String, token: String) async -> Bool {
        await repository.testHomeAssistantConnection(baseURL: baseURL, token: token)
    }
}
