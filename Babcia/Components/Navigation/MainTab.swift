import SwiftUI
import Common

enum MainTab: String, CaseIterable, Identifiable {
    case home
    case spaces
    case capture
    case gallery
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .spaces: return "Areas"
        case .capture: return "Capture"
        case .gallery: return "Gallery"
        case .settings: return "Settings"
        }
    }

    var icon: BabciaIcon {
        switch self {
        case .home: return .home
        case .spaces: return .spaces
        case .capture: return .capture
        case .gallery: return .gallery
        case .settings: return .settings
        }
    }
}
