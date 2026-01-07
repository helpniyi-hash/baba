import SwiftUI

public struct BabciaCard<Content: View>: View {
    private let style: BabciaSurfaceStyle
    private let cornerRadius: CGFloat
    private let shadow: BabciaShadowToken
    private let variant: BabciaGlassVariant
    private let content: Content

    public init(
        style: BabciaSurfaceStyle = .card,
        cornerRadius: CGFloat = BabciaCorner.card,
        shadow: BabciaShadowToken = .sm,
        variant: BabciaGlassVariant = .clear,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.cornerRadius = cornerRadius
        self.shadow = shadow
        self.variant = variant
        self.content = content()
    }

    public var body: some View {
        content
            .babciaCardPadding()
            .babciaFullWidthLeading()
            .babciaGlassCard(style: style, cornerRadius: cornerRadius, shadow: shadow, variant: variant)
    }
}
