import Core

public struct FetchHACamerasUseCase: Sendable {
    private let repository: ScanRepositoryProtocol

    public init(repository: ScanRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(baseURL: String, token: String) async throws -> [HACamera] {
        try await repository.fetchHomeAssistantCameras(baseURL: baseURL, token: token)
    }
}
