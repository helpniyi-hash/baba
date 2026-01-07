import Foundation

public enum ScanCadence: String, Codable, CaseIterable, Sendable {
    case hourly
    case daily

    public var displayName: String {
        switch self {
        case .hourly:
            return "Hourly"
        case .daily:
            return "Daily"
        }
    }

    public var interval: TimeInterval {
        switch self {
        case .hourly:
            return 60 * 60
        case .daily:
            return 60 * 60 * 24
        }
    }
}

public struct ScanSchedule: Codable, Hashable, Sendable {
    public var cadence: ScanCadence
    public var enabled: Bool
    public var lastRun: Date?
    public var nextRun: Date?

    public init(
        cadence: ScanCadence = .daily,
        enabled: Bool = false,
        lastRun: Date? = nil,
        nextRun: Date? = nil
    ) {
        self.cadence = cadence
        self.enabled = enabled
        self.lastRun = lastRun
        self.nextRun = nextRun
    }

    public mutating func refreshNextRun(from date: Date = Date()) {
        nextRun = date.addingTimeInterval(cadence.interval)
    }

    public mutating func markRan(at date: Date = Date()) {
        lastRun = date
        refreshNextRun(from: date)
    }
}
