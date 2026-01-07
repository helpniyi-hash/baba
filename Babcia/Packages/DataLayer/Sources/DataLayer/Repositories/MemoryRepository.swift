import Foundation
import Core

public final class MemoryRepository: MemoryRepositoryProtocol {
    private let service = MemoryService.shared

    public init() {}

    public func log(character: BabciaCharacter, action: String, response: String) async {
        await service.log(character: character, action: action, response: response)
    }

    public func getFullHistory(for character: BabciaCharacter) async -> [Interaction] {
        await service.getFullHistory(for: character)
    }

    public func getLastInteraction(for character: BabciaCharacter) async -> Interaction? {
        await service.getLastInteraction(for: character)
    }
}
