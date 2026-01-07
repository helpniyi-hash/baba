import SwiftUI
import Common

struct BabciaTabBar: View {
    @Binding var selectedTab: MainTab
    @Namespace private var tabNamespace

    var body: some View {
        BabciaGlassGroup(spacing: 20) {
            HStack(spacing: BabciaSpacing.xs) {
                ForEach(MainTab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        BabciaTabItem(tab: tab, isSelected: tab == selectedTab)
                    }
                    .buttonStyle(BabciaTabButtonStyle())
                    .babciaInteractiveGlassEffect(.clear)
                    .babciaGlassEffectID(tab.id, in: tabNamespace)
                }
            }
            .padding(.horizontal, BabciaSpacing.md)
            .padding(.vertical, BabciaSpacing.sm)
            .babciaFullWidth()
        }
        .babciaGlassCard(style: .strong, cornerRadius: BabciaCorner.tabBar, shadow: .lg)
        .padding(.horizontal, BabciaSpacing.screenHorizontal)
        .padding(.bottom, BabciaSpacing.sm)
        .accessibilityLabel("Main tabs")
    }
}
