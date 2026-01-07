import Foundation
import Core

public final class RoomsRepository: RoomsRepositoryProtocol {
    private let fileName = "babcia_rooms.json"

    public init() {}

    public func loadRooms() async throws -> [Room] {
        let url = try roomsFileURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([Room].self, from: data)
    }

    public func saveRooms(_ rooms: [Room]) async throws {
        let url = try roomsFileURL()
        let data = try JSONEncoder().encode(rooms)
        try data.write(to: url, options: .atomic)
    }

    private func roomsFileURL() throws -> URL {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw RoomsRepositoryError.documentsDirectoryUnavailable
        }
        return documentsURL.appendingPathComponent(fileName)
    }
}

enum RoomsRepositoryError: Error {
    case documentsDirectoryUnavailable
}
