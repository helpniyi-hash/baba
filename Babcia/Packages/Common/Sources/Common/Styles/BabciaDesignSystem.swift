import SwiftUI

public enum BabciaSpacing {
    public static let xs: CGFloat = 6
    public static let sm: CGFloat = 10
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 20
    public static let xl: CGFloat = 28
    public static let cardPadding: CGFloat = 16
    public static let tabBarInset: CGFloat = 110
}

public enum BabciaCorner {
    public static let card: CGFloat = 16
    public static let image: CGFloat = 18
    public static let pill: CGFloat = 999
    public static let tabBar: CGFloat = 26
    public static let icon: CGFloat = 10
}

public enum BabciaShadow {
    public static let soft = Color.black.opacity(0.08)
    public static let softRadius: CGFloat = 8
    public static let softYOffset: CGFloat = 4
}

public enum BabciaSurfaceStyle {
    case card
    case subtle
    case strong

    var strokeOpacity: Double {
        switch self {
        case .card: return 0.1
        case .subtle: return 0.06
        case .strong: return 0.14
        }
    }

    var fallbackMaterial: Material {
        switch self {
        case .card: return .ultraThinMaterial
        case .subtle: return .thinMaterial
        case .strong: return .regularMaterial
        }
    }
}

@available(iOS 26.0, *)
private extension BabciaSurfaceStyle {
    var glassStyle: GlassEffectStyle {
        switch self {
        case .card, .subtle:
            return .thin
        case .strong:
            return .regular
        }
    }
}

public struct BabciaSurface: View {
    private let style: BabciaSurfaceStyle
    private let cornerRadius: CGFloat

    public init(style: BabciaSurfaceStyle = .card, cornerRadius: CGFloat = BabciaCorner.card) {
        self.style = style
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(iOS 26.0, *) {
            shape
                .glassEffect(style.glassStyle, in: shape)
                .overlay(
                    shape.stroke(Color.white.opacity(style.strokeOpacity), lineWidth: 1)
                )
        } else {
            shape
                .fill(style.fallbackMaterial)
                .overlay(
                    shape.stroke(Color.white.opacity(style.strokeOpacity), lineWidth: 1)
                )
        }
    }
}

public extension View {
    func babciaCardSurface(
        style: BabciaSurfaceStyle = .card,
        cornerRadius: CGFloat = BabciaCorner.card,
        shadow: Bool = true
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(iOS 26.0, *) {
            return AnyView(
                GlassEffectContainer {
                    self
                        .glassEffect(style.glassStyle, in: shape)
                        .clipShape(shape)
                        .overlay(
                            shape.stroke(Color.white.opacity(style.strokeOpacity), lineWidth: 1)
                        )
                }
                .shadow(
                    color: shadow ? BabciaShadow.soft : .clear,
                    radius: shadow ? BabciaShadow.softRadius : 0,
                    x: 0,
                    y: shadow ? BabciaShadow.softYOffset : 0
                )
            )
        }
        return AnyView(
            self
                .background(
                    shape.fill(style.fallbackMaterial)
                )
                .overlay(
                    shape.stroke(Color.white.opacity(style.strokeOpacity), lineWidth: 1)
                )
                .shadow(
                    color: shadow ? BabciaShadow.soft : .clear,
                    radius: shadow ? BabciaShadow.softRadius : 0,
                    x: 0,
                    y: shadow ? BabciaShadow.softYOffset : 0
                )
        )
    }

    func babciaGlassButton() -> some View {
        if #available(iOS 26.0, *) {
            return AnyView(self.buttonStyle(GlassProminentButtonStyle()))
        }
        return AnyView(self.buttonStyle(.borderedProminent))
    }
}
