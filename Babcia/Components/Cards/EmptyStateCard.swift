import SwiftUI
import Common

struct EmptyStateCard: View {
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    init(title: String, message: String, actionTitle: String = "Create Room", action: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: BabciaSpacing.md) {
            Text(title)
                .font(.babcia(.headingSm))
            Text(message)
                .font(.babcia(.caption))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            BabciaPrimaryButton(actionTitle, action: action)
                .frame(maxWidth: 220)
        }
        .babciaCardPadding()
        .babciaGlassCard()
        .babciaFullWidth()
        .accessibilityElement(children: .combine)
    }
}
