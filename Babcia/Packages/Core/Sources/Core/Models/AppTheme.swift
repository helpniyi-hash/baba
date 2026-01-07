import Foundation

public enum AppTheme: String, Codable, CaseIterable, Sendable {
    case system
    case light
    case dark

    public var displayName: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
}
