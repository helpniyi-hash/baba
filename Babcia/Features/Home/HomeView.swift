import SwiftUI
import Common

struct HomeView: View {
    @State private var selectedTab: MainTab = .home

    var body: some View {
        ZStack {
            switch selectedTab {
            case .home:
                HomeTab()
            case .spaces:
                RoomsTab()
            case .capture:
                CaptureTab()
            case .gallery:
                GalleryTab()
            case .settings:
                SettingsTab()
            }
        }
        .safeAreaInset(edge: .bottom) {
            BabciaTabBar(selectedTab: $selectedTab)
        }
    }
}
