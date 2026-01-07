import Core

public struct LoadRoomsUseCase: Sendable {
    private let repository: RoomsRepositoryProtocol

    public init(repository: RoomsRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> [Room] {
        try await repository.loadRooms()
    }
}
