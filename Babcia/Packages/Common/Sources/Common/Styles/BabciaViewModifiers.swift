import SwiftUI

public extension View {
    func babciaScreenPadding() -> some View {
        padding(.horizontal, BabciaSpacing.screenHorizontal)
            .padding(.vertical, BabciaSpacing.screenVertical)
    }

    func babciaHorizontalPadding() -> some View {
        padding(.horizontal, BabciaSpacing.screenHorizontal)
    }

    func babciaTabBarPadding() -> some View {
        padding(.bottom, BabciaSpacing.tabBarClearance)
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
        if #available(iOS 26.0, *) {
            let resolvedVariant: BabciaGlassVariant = reduceTransparency ? .identity : variant
            return AnyView(
                sizedContent
                    .glassEffect(interactive ? resolvedVariant.glass.interactive() : resolvedVariant.glass, in: shape)
                    .clipShape(shape)
                    .overlay(shape.stroke(Color.white.opacity(style.strokeOpacity), lineWidth: 1))
                    .babciaShadow(shadow)
            )
        }
        return AnyView(
            sizedContent
                .background(shape.fill(style.fallbackMaterial))
                .overlay(shape.stroke(Color.white.opacity(style.strokeOpacity), lineWidth: 1))
                .babciaShadow(shadow)
        )
    }
}

private struct BabciaGlassButtonModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let prominent: Bool

    func body(content: Content) -> some View {
        let variant: BabciaGlassVariant = reduceTransparency ? .identity : .clear
        if #available(iOS 26.0, *) {
            if prominent {
                return AnyView(
                    content
                        .buttonStyle(.glassProminent)
                        .babciaInteractiveGlassEffect(variant)
                )
            }
            return AnyView(
                content
                    .buttonStyle(.glass)
                    .babciaInteractiveGlassEffect(variant)
            )
        }
        if prominent {
            return AnyView(content.buttonStyle(BorderedProminentButtonStyle()))
        }
        return AnyView(content.buttonStyle(BorderedButtonStyle()))
    }
}
