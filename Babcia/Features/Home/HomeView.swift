import SwiftUI
import Common

struct HomeView: View {
    @State private var selectedTab: MainTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeTab()
                .tag(MainTab.home)
                .tabItem { Label(MainTab.home.title, systemImage: MainTab.home.icon.systemName) }

            AreasTab()
                .tag(MainTab.spaces)
                .tabItem { Label(MainTab.spaces.title, systemImage: MainTab.spaces.icon.systemName) }

            CaptureTab()
                .tag(MainTab.capture)
                .tabItem { Label(MainTab.capture.title, systemImage: MainTab.capture.icon.systemName) }

            GalleryTab()
                .tag(MainTab.gallery)
                .tabItem { Label(MainTab.gallery.title, systemImage: MainTab.gallery.icon.systemName) }

            SettingsTab()
                .tag(MainTab.settings)
                .tabItem { Label(MainTab.settings.title, systemImage: MainTab.settings.icon.systemName) }
        }
    }
}
