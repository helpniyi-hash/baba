import SwiftUI

/// Flexible header modifiers for stretchy header effect
/// Based on Apple's Landmarks app pattern using onScrollGeometryChange
extension View {
    /// Apply to the ScrollView to enable flexible header tracking
    @ViewBuilder
    func flexibleHeaderScrollView() -> some View {
        if #available(iOS 18.0, *) {
            self.modifier(FlexibleHeaderScrollViewModifier())
        } else {
            self
        }
    }
    
    /// Apply to the header content to enable stretchy behavior
    @ViewBuilder
    func flexibleHeaderContent(height: CGFloat = BabciaConstants.Size.heroImageHeight) -> some View {
        if #available(iOS 18.0, *) {
            self.modifier(FlexibleHeaderContentModifier(height: height))
        } else {
            self.frame(height: height)
        }
    }
}

@available(iOS 18.0, *)
private struct FlexibleHeaderScrollViewModifier: ViewModifier {
    @State private var scrollOffset: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y
            } action: { oldValue, newValue in
                scrollOffset = newValue
            }
            .environment(\.flexibleHeaderScrollOffset, scrollOffset)
    }
}

@available(iOS 18.0, *)
private struct FlexibleHeaderContentModifier: ViewModifier {
    let height: CGFloat
    @Environment(\.flexibleHeaderScrollOffset) private var scrollOffset
    
    func body(content: Content) -> some View {
        let offset = min(scrollOffset, 0)
        let scale = max(1, 1 + (-offset / height))
        
        content
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .scaleEffect(scale, anchor: .top)
            .offset(y: offset)
    }
}

// MARK: - Environment Key
@available(iOS 18.0, *)
private struct FlexibleHeaderScrollOffsetKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

@available(iOS 18.0, *)
extension EnvironmentValues {
    var flexibleHeaderScrollOffset: CGFloat {
        get { self[FlexibleHeaderScrollOffsetKey.self] }
        set { self[FlexibleHeaderScrollOffsetKey.self] = newValue }
    }
}
