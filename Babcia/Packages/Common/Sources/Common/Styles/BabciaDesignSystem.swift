import SwiftUI

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

public struct BabciaSurface: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private let style: BabciaSurfaceStyle
    private let cornerRadius: CGFloat

    public init(style: BabciaSurfaceStyle = .card, cornerRadius: CGFloat = BabciaCorner.card) {
        self.style = style
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(iOS 26.0, *) {
            let variant: BabciaGlassVariant = reduceTransparency ? .identity : .clear
            shape
                .babciaGlassEffect(variant, in: shape)
                .overlay(shape.stroke(Color.white.opacity(style.strokeOpacity), lineWidth: 1))
        } else {
            shape
                .fill(style.fallbackMaterial)
                .overlay(shape.stroke(Color.white.opacity(style.strokeOpacity), lineWidth: 1))
        }
    }
}

public extension View {
    func babciaCardSurface(
        style: BabciaSurfaceStyle = .card,
        cornerRadius: CGFloat = BabciaCorner.card,
        shadow: Bool = true
    ) -> some View {
        let shadowToken: BabciaShadowToken = shadow ? .md : .none
        return babciaGlassCard(style: style, cornerRadius: cornerRadius, shadow: shadowToken)
    }
}
