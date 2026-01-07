import Core

public struct SaveRoomsUseCase: Sendable {
    private let repository: RoomsRepositoryProtocol

    public init(repository: RoomsRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(_ rooms: [Room]) async throws {
        try await repository.saveRooms(rooms)
    }
}
