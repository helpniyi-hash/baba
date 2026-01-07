import Foundation

public enum RoomImageSource: String, Codable, CaseIterable, Sendable {
    case iphone
    case homeAssistant
    case manual
    case stream
}

public struct Room: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var character: BabciaCharacter
    public var imageSource: RoomImageSource
    public var cameraIdentifier: String?

    public var dreamVisionPath: String?
    public var tasks: [CleaningTask]
    public var babciaAdvice: String?
    public var scanHistory: [ScanHistory]
    public var userCaptures: [UserCapture]
    public var lastVerifiedScanPath: String?
    public var lastVerifiedAt: Date?
    public var verificationAttempts: Int

    public var streak: Int
    public var totalXP: Int
    public var lastActivityDate: Date?
    public var lastScanDate: Date?

    public var scanSchedule: ScanSchedule?

    public init(
        id: UUID = UUID(),
        name: String,
        character: BabciaCharacter,
        imageSource: RoomImageSource,
        cameraIdentifier: String? = nil,
        dreamVisionPath: String? = nil,
        tasks: [CleaningTask] = [],
        babciaAdvice: String? = nil,
        scanHistory: [ScanHistory] = [],
        userCaptures: [UserCapture] = [],
        lastVerifiedScanPath: String? = nil,
        lastVerifiedAt: Date? = nil,
        verificationAttempts: Int = 0,
        streak: Int = 0,
        totalXP: Int = 0,
        lastActivityDate: Date? = nil,
        lastScanDate: Date? = nil,
        scanSchedule: ScanSchedule? = nil
    ) {
        self.id = id
        self.name = name
        self.character = character
        self.imageSource = imageSource
        self.cameraIdentifier = cameraIdentifier
        self.dreamVisionPath = dreamVisionPath
        self.tasks = tasks
        self.babciaAdvice = babciaAdvice
        self.scanHistory = scanHistory
        self.userCaptures = userCaptures
        self.lastVerifiedScanPath = lastVerifiedScanPath
        self.lastVerifiedAt = lastVerifiedAt
        self.verificationAttempts = verificationAttempts
        self.streak = streak
        self.totalXP = totalXP
        self.lastActivityDate = lastActivityDate
        self.lastScanDate = lastScanDate
        self.scanSchedule = scanSchedule
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case character
        case imageSource
        case cameraIdentifier
        case dreamVisionPath
        case tasks
        case babciaAdvice
        case scanHistory
        case userCaptures
        case lastVerifiedScanPath
        case lastVerifiedAt
        case verificationAttempts
        case streak
        case totalXP
        case lastActivityDate
        case lastScanDate
        case scanSchedule
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        character = try container.decode(BabciaCharacter.self, forKey: .character)
        imageSource = try container.decode(RoomImageSource.self, forKey: .imageSource)
        cameraIdentifier = try container.decodeIfPresent(String.self, forKey: .cameraIdentifier)
        dreamVisionPath = try container.decodeIfPresent(String.self, forKey: .dreamVisionPath)
        tasks = try container.decodeIfPresent([CleaningTask].self, forKey: .tasks) ?? []
        babciaAdvice = try container.decodeIfPresent(String.self, forKey: .babciaAdvice)
        scanHistory = try container.decodeIfPresent([ScanHistory].self, forKey: .scanHistory) ?? []
        userCaptures = try container.decodeIfPresent([UserCapture].self, forKey: .userCaptures) ?? []
        lastVerifiedScanPath = try container.decodeIfPresent(String.self, forKey: .lastVerifiedScanPath)
        lastVerifiedAt = try container.decodeIfPresent(Date.self, forKey: .lastVerifiedAt)
        verificationAttempts = try container.decodeIfPresent(Int.self, forKey: .verificationAttempts) ?? 0
        streak = try container.decodeIfPresent(Int.self, forKey: .streak) ?? 0
        totalXP = try container.decodeIfPresent(Int.self, forKey: .totalXP) ?? 0
        lastActivityDate = try container.decodeIfPresent(Date.self, forKey: .lastActivityDate)
        lastScanDate = try container.decodeIfPresent(Date.self, forKey: .lastScanDate)
        scanSchedule = try container.decodeIfPresent(ScanSchedule.self, forKey: .scanSchedule)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(character, forKey: .character)
        try container.encode(imageSource, forKey: .imageSource)
        try container.encodeIfPresent(cameraIdentifier, forKey: .cameraIdentifier)
        try container.encodeIfPresent(dreamVisionPath, forKey: .dreamVisionPath)
        try container.encode(tasks, forKey: .tasks)
        try container.encodeIfPresent(babciaAdvice, forKey: .babciaAdvice)
        try container.encode(scanHistory, forKey: .scanHistory)
        try container.encode(userCaptures, forKey: .userCaptures)
        try container.encodeIfPresent(lastVerifiedScanPath, forKey: .lastVerifiedScanPath)
        try container.encodeIfPresent(lastVerifiedAt, forKey: .lastVerifiedAt)
        try container.encode(verificationAttempts, forKey: .verificationAttempts)
        try container.encode(streak, forKey: .streak)
        try container.encode(totalXP, forKey: .totalXP)
        try container.encodeIfPresent(lastActivityDate, forKey: .lastActivityDate)
        try container.encodeIfPresent(lastScanDate, forKey: .lastScanDate)
        try container.encodeIfPresent(scanSchedule, forKey: .scanSchedule)
    }
}

public extension Room {
    var dreamVisionURL: URL? {
        guard let path = dreamVisionPath else { return nil }
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent(path)
    }

    var lastVerifiedScanURL: URL? {
        guard let path = lastVerifiedScanPath else { return nil }
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent(path)
    }

    var completedTaskCount: Int {
        tasks.filter { $0.isCompleted }.count
    }

    var pendingTaskCount: Int {
        tasks.filter { $0.verificationState != .verified }.count
    }

    var manualOverrideAvailable: Bool {
        pendingTaskCount > 0 && verificationAttempts >= 2
    }

    mutating func recordActivity() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = lastActivityDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysBetween == 0 {
                // Same day - no change
            } else if daysBetween == 1 {
                streak += 1
            } else {
                streak = 1
            }
        } else {
            streak = 1
        }

        lastActivityDate = Date()
    }

    mutating func archiveCurrentScan() {
        guard let dreamPath = dreamVisionPath else { return }
        let history = ScanHistory(
            date: Date(),
            dreamVisionPath: dreamPath,
            tasks: tasks,
            babciaAdvice: babciaAdvice
        )
        scanHistory.append(history)
    }
}
