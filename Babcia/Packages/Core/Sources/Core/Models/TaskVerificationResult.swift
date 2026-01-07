import Foundation

public enum TaskVerificationStatus: String, Codable, Sendable {
    case verified
    case notDone
    case unclear
}

public struct TaskVerificationResult: Codable, Hashable, Sendable {
    public var taskID: UUID
    public var status: TaskVerificationStatus
    public var confidence: Double
    public var note: String?

    public init(
        taskID: UUID,
        status: TaskVerificationStatus,
        confidence: Double,
        note: String? = nil
    ) {
        self.taskID = taskID
        self.status = status
        self.confidence = confidence
        self.note = note
    }
}

public struct RoomVerificationResult: Codable, Hashable, Sendable {
    public var tasks: [TaskVerificationResult]
    public var summary: String
    public var needsRescan: Bool

    public init(
        tasks: [TaskVerificationResult],
        summary: String,
        needsRescan: Bool
    ) {
        self.tasks = tasks
        self.summary = summary
        self.needsRescan = needsRescan
    }
}
