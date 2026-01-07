//
//  ContentView.swift
//  Babcia
//
//  Created by Prank on 17/9/25.
//

import SwiftUI
import Presentation
import Common
import Core

struct ContentView: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    var body: some View {
        Group {
            if appViewModel.hasCompletedSetup {
                HomeView()
            } else {
                SetupView()
            }
        }
        .overlay {
            if appViewModel.isLoading {
                BabciaLoadingOverlay()
            }
        }
        .alert(item: $appViewModel.alertItem) { alertItem in
            Alert(
                title: Text(alertItem.title),
                message: Text(alertItem.message),
                dismissButton: .default(Text(alertItem.dismissButton))
            )
        }
        .task {
            appViewModel.load()
        }
        .preferredColorScheme(preferredColorScheme)
        .font(.babcia(.bodyLg))
    }

    private var preferredColorScheme: ColorScheme? {
        switch appViewModel.settings.theme {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
