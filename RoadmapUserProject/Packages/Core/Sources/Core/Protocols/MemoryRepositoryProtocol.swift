import Foundation

public protocol MemoryRepositoryProtocol: Sendable {
    func log(character: BabciaCharacter, action: String, response: String) async
    func getFullHistory(for character: BabciaCharacter) async -> [Interaction]
    func getLastInteraction(for character: BabciaCharacter) async -> Interaction?
}
