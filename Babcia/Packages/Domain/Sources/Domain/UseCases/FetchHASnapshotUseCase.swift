import Core
import UIKit

public struct FetchHASnapshotUseCase: Sendable {
    private let repository: ScanRepositoryProtocol

    public init(repository: ScanRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(baseURL: String, token: String, entityId: String) async throws -> UIImage {
        try await repository.fetchHomeAssistantSnapshot(
            baseURL: baseURL,
            token: token,
            entityId: entityId
        )
    }
}
