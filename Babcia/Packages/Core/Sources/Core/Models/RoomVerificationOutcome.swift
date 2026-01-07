import Foundation

public struct RoomVerificationOutcome: Sendable {
    public let room: Room
    public let needsRescan: Bool
    public let summary: String

    public init(room: Room, needsRescan: Bool, summary: String) {
        self.room = room
        self.needsRescan = needsRescan
        self.summary = summary
    }
}
