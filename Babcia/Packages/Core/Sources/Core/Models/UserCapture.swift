import Foundation

public enum CaptureSource: String, Codable, CaseIterable, Sendable {
    case scan
    case verify
    case manual
    case homeAssistant
    case camera

    public var displayName: String {
        switch self {
        case .scan:
            return "Scan"
        case .verify:
            return "Verify"
        case .manual:
            return "Manual"
        case .homeAssistant:
            return "Home Assistant"
        case .camera:
            return "Camera"
        }
    }
}

public struct UserCapture: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var roomID: UUID
    public var date: Date
    public var path: String
    public var source: CaptureSource

    public init(
        id: UUID = UUID(),
        roomID: UUID,
        date: Date,
        path: String,
        source: CaptureSource
    ) {
        self.id = id
        self.roomID = roomID
        self.date = date
        self.path = path
        self.source = source
    }

    public var fileURL: URL? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent(path)
    }
}
