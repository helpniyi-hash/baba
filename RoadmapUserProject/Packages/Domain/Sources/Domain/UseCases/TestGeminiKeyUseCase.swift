import Core

public struct TestGeminiKeyUseCase: Sendable {
    private let repository: ScanRepositoryProtocol

    public init(repository: ScanRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(_ key: String) async throws -> Bool {
        try await repository.testGeminiKey(key)
    }
}
