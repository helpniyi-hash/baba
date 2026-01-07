import Foundation

public struct HACamera: Identifiable, Codable, Hashable, Sendable {
    public let entityId: String
    public let name: String
    public let state: String

    public var id: String { entityId }

    public init(entityId: String, name: String, state: String) {
        self.entityId = entityId
        self.name = name
        self.state = state
    }
}
