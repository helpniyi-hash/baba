import Foundation
import Core

actor MemoryService {
    static let shared = MemoryService()

    private static let fileName = "memory_core_v1.json"
    private var history: [Interaction]

    private init() {
        history = Self.loadFromDisk()
    }

    func log(character: BabciaCharacter, action: String, response: String) {
        let interaction = Interaction(characterId: character.id, userAction: action, aiResponse: response)
        history.append(interaction)
        saveToDisk()
    }

    func getFullHistory(for character: BabciaCharacter) -> [Interaction] {
        history.filter { $0.characterId == character.id }.sorted { $0.timestamp < $1.timestamp }
    }

    func getLastInteraction(for character: BabciaCharacter) -> Interaction? {
        getFullHistory(for: character).last
    }

    private static func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private static func getFileURL() -> URL {
        getDocumentsDirectory().appendingPathComponent(fileName)
    }

    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(history)
            try data.write(to: Self.getFileURL())
        } catch {
            // Fail silently
        }
    }

    private static func loadFromDisk() -> [Interaction] {
        let url = getFileURL()
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Interaction].self, from: data)
        } catch {
            return []
        }
    }
}
