import SwiftUI

public enum BabciaIcon {
    case home
    case spaces
    case capture
    case gallery
    case profile
    case rooms
    case settings
    case add
    case back
    case camera
    case homeAssistant
    case xp
    case level
    case streak
    case info
    case warning
    case checklist
    case chevronRight
    case taskComplete
    case taskPending

    public var systemName: String {
        switch self {
        case .home:
            return "house.fill"
        case .spaces:
            return "square.grid.2x2.fill"
        case .capture:
            return "camera.fill"
        case .gallery:
            return "photo.on.rectangle.angled"
        case .profile:
            return "person.fill"
        case .rooms:
            return "chart.bar.fill"
        case .settings:
            return "gear"
        case .add:
            return "plus"
        case .back:
            return "chevron.left"
        case .camera:
            return "camera.fill"
        case .homeAssistant:
            return "video.fill"
        case .xp:
            return "bolt.fill"
        case .level:
            return "star.fill"
        case .streak:
            return "flame.fill"
        case .info:
            return "info.circle"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .checklist:
            return "checklist"
        case .chevronRight:
            return "chevron.right"
        case .taskComplete:
            return "checkmark.circle.fill"
        case .taskPending:
            return "circle"
        }
    }
}
