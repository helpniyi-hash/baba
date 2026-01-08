import SwiftUI

private struct BabciaUsesCustomTabBarKey: EnvironmentKey {
    static let defaultValue = false
}

public extension EnvironmentValues {
    var babciaUsesCustomTabBar: Bool {
        get { self[BabciaUsesCustomTabBarKey.self] }
        set { self[BabciaUsesCustomTabBarKey.self] = newValue }
    }
}

public extension View {
    func babciaScreenPadding() -> some View {
        padding(.horizontal, BabciaSpacing.screenHorizontal)
            .padding(.vertical, BabciaSpacing.screenVertical)
    }

    func babciaHorizontalPadding() -> some View {
        padding(.horizontal, BabciaSpacing.screenHorizontal)
    }

    func babciaTabBarPadding() -> some View {
        modifier(BabciaTabBarPaddingModifier())
    }

    func babciaCardPadding() -> some View {
        padding(BabciaSpacing.cardPadding)
    }

    func babciaCardPaddingCompact() -> some View {
        padding(BabciaSpacing.cardPaddingCompact)
    }

    func babciaTouchTarget(min: CGFloat = BabciaSize.touchMin) -> some View {
        frame(minWidth: min, minHeight: min)
    }

    func babciaFullWidth() -> some View {
        frame(maxWidth: .infinity)
    }

    func babciaFullWidthLeading() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
    }

    func babciaShadow(_ token: BabciaShadowToken) -> some View {
        let values = BabciaShadow.values(token)
        return shadow(color: values.color, radius: values.radius, x: 0, y: values.y)
    }

    func babciaGlassCard(
        style: BabciaSurfaceStyle = .card,
        cornerRadius: CGFloat = BabciaCorner.card,
        shadow: BabciaShadowToken = .sm,
        variant: BabciaGlassVariant = .clear,
        interactive: Bool = false,
        fullWidth: Bool = true
    ) -> some View {
        modifier(BabciaGlassCardModifier(
            style: style,
            cornerRadius: cornerRadius,
            shadow: shadow,
            variant: variant,
            interactive: interactive,
            fullWidth: fullWidth
        ))
    }

    func babciaGlassButton() -> some View {
        modifier(BabciaGlassButtonModifier(prominent: false))
    }

    func babciaGlassButtonProminent() -> some View {
        modifier(BabciaGlassButtonModifier(prominent: true))
    }
}

private struct BabciaGlassCardModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let style: BabciaSurfaceStyle
    let cornerRadius: CGFloat
    let shadow: BabciaShadowToken
    let variant: BabciaGlassVariant
    let interactive: Bool
    let fullWidth: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let sizedContent: AnyView = fullWidth
            ? AnyView(content.frame(maxWidth: .infinity, alignment: .leading))
            : AnyView(content)
        // Liquid Glass is reserved for navigation/controls; content surfaces use Materials.
        // Reduce Transparency is handled by the system materials automatically.
        return AnyView(
            sizedContent
                .background(shape.fill(style.fallbackMaterial))
                .overlay(shape.stroke(Color.primary.opacity(style.strokeOpacity), lineWidth: 0.5))
                .babciaShadow(reduceTransparency ? .none : shadow)
        )
    }
}

private struct BabciaGlassButtonModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let prominent: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if prominent {
                return AnyView(
                    content
                        .buttonStyle(.glassProminent)
                )
            }
            return AnyView(
                content
                    .buttonStyle(.glass)
            )
        }
        if prominent {
            return AnyView(content.buttonStyle(BorderedProminentButtonStyle()))
        }
        return AnyView(content.buttonStyle(BorderedButtonStyle()))
    }
}

private struct BabciaTabBarPaddingModifier: ViewModifier {
    @Environment(\.babciaUsesCustomTabBar) private var usesCustomTabBar

    func body(content: Content) -> some View {
        if usesCustomTabBar {
            return AnyView(content.padding(.bottom, BabciaSpacing.tabBarClearance))
        }
        return AnyView(content)
    }
}
