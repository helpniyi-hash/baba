import Foundation

public enum TaskVerificationState: String, Codable, Sendable {
    case pending
    case verified
    case manual
}

public struct CleaningTask: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var title: String
    public var isCompleted: Bool
    public var verificationState: TaskVerificationState?
    public var verificationConfidence: Double?
    public var verificationNote: String?
    public var xpReward: Int
    public var completedAt: Date?

    public init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        verificationState: TaskVerificationState? = nil,
        verificationConfidence: Double? = nil,
        verificationNote: String? = nil,
        xpReward: Int = 10,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.verificationState = verificationState
        self.verificationConfidence = verificationConfidence
        self.verificationNote = verificationNote
        self.xpReward = xpReward
        self.completedAt = completedAt
    }
}

public extension CleaningTask {
    var isVerified: Bool {
        verificationState == .verified
    }

    var resolvedVerificationState: TaskVerificationState {
        if let verificationState {
            return verificationState
        }
        return isCompleted ? .manual : .pending
    }
}
