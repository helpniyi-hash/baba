import SwiftUI
import Common

struct BabciaTabItem: View {
    let tab: MainTab
    let isSelected: Bool

    var body: some View {
        VStack(spacing: BabciaSpacing.xxs) {
            Image(systemName: tab.icon.systemName)
                .font(.system(size: BabciaSize.iconSm, weight: .semibold))
                .contentTransition(.symbolEffect(.replace))

            Text(tab.title)
                .font(.babcia(.labelSm))
        }
        .foregroundColor(isSelected ? .primary : .secondary)
        .babciaFullWidth()
        .padding(.vertical, BabciaSpacing.xs)
        .accessibilityLabel(tab.title)
        .accessibilityValue(Text(isSelected ? "Selected" : "Not selected"))
    }
}
