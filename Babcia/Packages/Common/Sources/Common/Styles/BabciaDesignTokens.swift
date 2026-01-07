import SwiftUI

public enum BabciaSpacing {
    public static let none: CGFloat = 0
    public static let hairline: CGFloat = 2
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 6
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 20
    public static let xxl: CGFloat = 24
    public static let xxxl: CGFloat = 32
    public static let xxxxl: CGFloat = 40
    public static let huge: CGFloat = 48
    public static let massive: CGFloat = 64

    public static let iconGap: CGFloat = xs
    public static let cardPadding: CGFloat = lg
    public static let cardPaddingCompact: CGFloat = md
    public static let cardGap: CGFloat = md
    public static let sectionGap: CGFloat = xxl
    public static let screenHorizontal: CGFloat = lg
    public static let screenVertical: CGFloat = md
    public static let listItemGap: CGFloat = sm
    public static let sectionHeaderGap: CGFloat = md
    public static let tabBarClearance: CGFloat = 100
}

public enum BabciaCorner {
    public static let none: CGFloat = 0
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 6
    public static let md: CGFloat = 8
    public static let lg: CGFloat = 12
    public static let xl: CGFloat = 16
    public static let xxl: CGFloat = 20
    public static let xxxl: CGFloat = 24
    public static let full: CGFloat = 999

    public static let card: CGFloat = xl
    public static let cardImage: CGFloat = lg
    public static let image: CGFloat = cardImage
    public static let button: CGFloat = lg
    public static let input: CGFloat = md
    public static let chip: CGFloat = full
    public static let avatar: CGFloat = full
    public static let sheet: CGFloat = xxxl
    public static let tabBar: CGFloat = xxl
}

public enum BabciaSize {
    public static let iconXs: CGFloat = 12
    public static let iconSm: CGFloat = 16
    public static let iconMd: CGFloat = 20
    public static let iconLg: CGFloat = 24
    public static let iconXl: CGFloat = 28
    public static let iconXxl: CGFloat = 32

    public static let avatarXs: CGFloat = 24
    public static let avatarSm: CGFloat = 32
    public static let avatarMd: CGFloat = 40
    public static let avatarLg: CGFloat = 48
    public static let avatarXl: CGFloat = 64
    public static let avatarXxl: CGFloat = 80
    public static let avatarHuge: CGFloat = 120

    public static let touchMin: CGFloat = 44
    public static let touchComfortable: CGFloat = 48
    public static let touchLarge: CGFloat = 56

    public static let buttonSm: CGFloat = 32
    public static let buttonMd: CGFloat = 44
    public static let buttonLg: CGFloat = 52
    public static let buttonXl: CGFloat = 56

    public static let thumbnailSm: CGFloat = 60
    public static let thumbnailMd: CGFloat = 80
    public static let thumbnailLg: CGFloat = 100
    public static let cardImageSm: CGFloat = 140
    public static let cardImageMd: CGFloat = 180
    public static let cardImageLg: CGFloat = 220
    public static let heroImage: CGFloat = 280

    public static let inputHeight: CGFloat = 44
}

public enum BabciaOpacity {
    public static let transparent: Double = 0
    public static let faint: Double = 0.05
    public static let subtle: Double = 0.1
    public static let light: Double = 0.2
    public static let medium: Double = 0.4
    public static let strong: Double = 0.6
    public static let veryStrong: Double = 0.8
    public static let opaque: Double = 1

    public static let disabled: Double = 0.4
    public static let placeholder: Double = 0.6
    public static let overlay: Double = 0.8
    public static let scrim: Double = 0.5
}

public enum BabciaShadowToken {
    case none
    case sm
    case md
    case lg
    case xl
}

public struct BabciaShadowValues {
    public let color: Color
    public let radius: CGFloat
    public let y: CGFloat

    public init(color: Color, radius: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.y = y
    }
}

public enum BabciaShadow {
    public static func values(_ token: BabciaShadowToken) -> BabciaShadowValues {
        switch token {
        case .none:
            return BabciaShadowValues(color: .clear, radius: 0, y: 0)
        case .sm:
            return BabciaShadowValues(color: Color.black.opacity(0.06), radius: 4, y: 2)
        case .md:
            return BabciaShadowValues(color: Color.black.opacity(0.08), radius: 8, y: 4)
        case .lg:
            return BabciaShadowValues(color: Color.black.opacity(0.12), radius: 16, y: 8)
        case .xl:
            return BabciaShadowValues(color: Color.black.opacity(0.16), radius: 24, y: 12)
        }
    }
}

public enum BabciaAnimation {
    public static let fast: TimeInterval = 0.15
    public static let normal: TimeInterval = 0.25
    public static let slow: TimeInterval = 0.35
    public static let verySlow: TimeInterval = 0.5

    public static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)
    public static let springSubtle = Animation.spring(response: 0.3, dampingFraction: 0.85)
    public static let easeOut = Animation.easeOut(duration: normal)
    public static let easeInOut = Animation.easeInOut(duration: normal)
}
