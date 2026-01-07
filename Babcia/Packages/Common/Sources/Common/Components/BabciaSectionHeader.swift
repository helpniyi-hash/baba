import SwiftUI

public struct BabciaSectionHeader: View {
    private let title: String
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(_ title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack(spacing: BabciaSpacing.sm) {
            Text(title)
                .font(.babcia(.headingSm))
                .foregroundColor(.primary)

            Spacer(minLength: BabciaSpacing.sm)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.babcia(.labelMd))
                    .babciaGlassButton()
                    .accessibilityLabel(Text(actionTitle))
            }
        }
        .babciaFullWidthLeading()
        .padding(.bottom, BabciaSpacing.sectionHeaderGap)
    }
}
