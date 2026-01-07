import Foundation

public struct ScanHistory: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var date: Date
    public var dreamVisionPath: String
    public var tasks: [CleaningTask]
    public var babciaAdvice: String?

    public init(
        id: UUID = UUID(),
        date: Date,
        dreamVisionPath: String,
        tasks: [CleaningTask],
        babciaAdvice: String?
    ) {
        self.id = id
        self.date = date
        self.dreamVisionPath = dreamVisionPath
        self.tasks = tasks
        self.babciaAdvice = babciaAdvice
    }

    public var dreamVisionURL: URL? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent(dreamVisionPath)
    }

    public var completedTaskCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
}
