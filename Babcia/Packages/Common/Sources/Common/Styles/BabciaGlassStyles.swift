import SwiftUI

public enum BabciaGlassVariant {
    case regular
    case clear
    case identity

    @available(iOS 26.0, *)
    var glass: Glass {
        switch self {
        case .regular:
            return .regular
        case .clear:
            return .clear
        case .identity:
            return .identity
        }
    }
}

@MainActor
@ViewBuilder
public func BabciaGlassGroup<Content: View>(
    spacing: CGFloat? = nil,
    @ViewBuilder content: () -> Content
) -> some View {
    if #available(iOS 26.0, *) {
        if let spacing {
            GlassEffectContainer(spacing: spacing) {
                content()
            }
        } else {
            GlassEffectContainer {
                content()
            }
        }
    } else {
        content()
    }
}

public extension View {
    func babciaGlassEffect(_ variant: BabciaGlassVariant) -> some View {
        if #available(iOS 26.0, *) {
            return AnyView(self.glassEffect(variant.glass))
        }
        return AnyView(self)
    }

    func babciaGlassEffect<S: Shape>(_ variant: BabciaGlassVariant, in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            return AnyView(self.glassEffect(variant.glass, in: shape))
        }
        return AnyView(self)
    }

    func babciaInteractiveGlassEffect(_ variant: BabciaGlassVariant) -> some View {
        if #available(iOS 26.0, *) {
            return AnyView(self.glassEffect(variant.glass.interactive()))
        }
        return AnyView(self)
    }

    func babciaInteractiveGlassEffect<S: Shape>(_ variant: BabciaGlassVariant, in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            return AnyView(self.glassEffect(variant.glass.interactive(), in: shape))
        }
        return AnyView(self)
    }

    func babciaGlassEffectID<ID: Hashable & Sendable>(_ id: ID, in namespace: Namespace.ID) -> some View {
        if #available(iOS 26.0, *) {
            return AnyView(self.glassEffectID(id, in: namespace))
        }
        return AnyView(self)
    }
}
