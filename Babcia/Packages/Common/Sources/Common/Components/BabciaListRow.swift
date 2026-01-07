import SwiftUI

public struct BabciaListRow<Leading: View, Trailing: View, Content: View>: View {
    private let leading: Leading
    private let trailing: Trailing
    private let content: Content
    private let showsLeading: Bool
    private let showsTrailing: Bool

    public init(
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing,
        @ViewBuilder content: () -> Content
    ) {
        self.leading = leading()
        self.trailing = trailing()
        self.content = content()
        self.showsLeading = true
        self.showsTrailing = true
    }

    public init(
        @ViewBuilder content: () -> Content
    ) where Leading == EmptyView, Trailing == EmptyView {
        self.leading = EmptyView()
        self.trailing = EmptyView()
        self.content = content()
        self.showsLeading = false
        self.showsTrailing = false
    }

    public var body: some View {
        HStack(spacing: BabciaSpacing.md) {
            if showsLeading {
                leading
            }

            content
                .babciaFullWidthLeading()

            if showsTrailing {
                trailing
            }
        }
        .padding(.vertical, BabciaSpacing.sm)
        .padding(.horizontal, BabciaSpacing.cardPadding)
        .babciaFullWidthLeading()
        .babciaGlassCard(style: .card, cornerRadius: BabciaCorner.card, shadow: .sm)
    }
}
