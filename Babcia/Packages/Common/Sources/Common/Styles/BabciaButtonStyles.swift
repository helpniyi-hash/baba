import SwiftUI

public struct BabciaCardButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(RoundedRectangle(cornerRadius: BabciaCorner.card, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(BabciaAnimation.springSubtle, value: configuration.isPressed)
            .babciaTouchTarget()
    }
}

public struct BabciaTabButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(BabciaAnimation.springSubtle, value: configuration.isPressed)
            .babciaTouchTarget()
    }
}

public struct BabciaSelectionButtonStyle: ButtonStyle {
    private let isSelected: Bool
    private let selectionColor: Color
    private let cornerRadius: CGFloat

    public init(isSelected: Bool, selectionColor: Color = .accentColor, cornerRadius: CGFloat = BabciaCorner.card) {
        self.isSelected = isSelected
        self.selectionColor = selectionColor
        self.cornerRadius = cornerRadius
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(selectionColor.opacity(isSelected ? 0.9 : 0), lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(BabciaAnimation.springSubtle, value: configuration.isPressed)
            .babciaTouchTarget()
    }
}

public struct BabciaGlassCardButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(RoundedRectangle(cornerRadius: BabciaCorner.card, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(BabciaAnimation.springSubtle, value: configuration.isPressed)
            .babciaTouchTarget()
    }
}
