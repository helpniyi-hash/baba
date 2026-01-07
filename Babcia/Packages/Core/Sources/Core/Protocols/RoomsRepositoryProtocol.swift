import Foundation

public protocol RoomsRepositoryProtocol: Sendable {
    func loadRooms() async throws -> [Room]
    func saveRooms(_ rooms: [Room]) async throws
}
