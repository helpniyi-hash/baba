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
                    .babciaGlassEffectID(tab.id, in: tabNamespace)
                }
            }
            .padding(.horizontal, BabciaSpacing.md)
            .padding(.vertical, BabciaSpacing.sm)
            .babciaFullWidth()
            .background(tabBarBackground)
        }
        .padding(.horizontal, BabciaSpacing.screenHorizontal)
        .padding(.bottom, BabciaSpacing.sm)
        .accessibilityLabel("Main tabs")
    }

    private var tabBarBackground: some View {
        let shape = RoundedRectangle(cornerRadius: BabciaCorner.tabBar, style: .continuous)
        return shape
            .babciaGlassEffect(.clear, in: shape)
            .overlay(shape.stroke(Color.white.opacity(0.14), lineWidth: 1))
            .babciaShadow(.lg)
    }
}
