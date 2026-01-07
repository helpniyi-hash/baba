//
//  BabciaApp.swift
//  Babcia
//
//  Created by Prank on 17/9/25.
//

import SwiftUI
import DI
import Common
import UIKit

@main
struct BabciaApp: App {
    @StateObject private var appViewModel = DIContainer.shared.makeAppViewModel()

    init() {
        BabciaFontRegistrar.registerFonts()
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel)
        }
    }

    private func configureAppearance() {
        let titleFont = UIFont(name: "LinLibertineB", size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .semibold)
        let largeTitleFont = UIFont(name: "LinLibertineB", size: 32) ?? UIFont.systemFont(ofSize: 32, weight: .bold)

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.titleTextAttributes = [.font: titleFont]
        navAppearance.largeTitleTextAttributes = [.font: largeTitleFont]

        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = navAppearance
        navBar.scrollEdgeAppearance = navAppearance
        navBar.compactAppearance = navAppearance

        let tabFont = UIFont(name: "LinLibertine", size: 11) ?? UIFont.systemFont(ofSize: 11, weight: .regular)
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithTransparentBackground()
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.font: tabFont]
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.font: tabFont]

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = tabAppearance
        tabBar.scrollEdgeAppearance = tabAppearance
    }
}
