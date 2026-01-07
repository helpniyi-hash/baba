import SwiftUI
import Presentation
import Common
import Core

struct SettingsTab: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var showingSettingsDetail = false
    @State private var showingResetAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                BabciaBackground(style: .gradient(appViewModel.settings.selectedCharacter, .subtle))

                ScrollView {
                    VStack(alignment: .leading, spacing: BabciaSpacing.sectionGap) {
                        VStack(alignment: .leading, spacing: BabciaSpacing.md) {
                            Text("Setup")
                                .font(.babcia(.headingSm))
                                .foregroundColor(.primary)

                            BabciaGlassGroup(spacing: 20) {
                                VStack(spacing: BabciaSpacing.listItemGap) {
                                    Button {
                                        showingSettingsDetail = true
                                    } label: {
                                        SettingsRow(
                                            icon: .info,
                                            title: "Connections",
                                            detail: connectionsStatus
                                        )
                                    }
                                    .buttonStyle(BabciaGlassCardButtonStyle())
                                    .babciaGlassCard(interactive: true)
                                    .babciaFullWidthLeading()

                                    Button {
                                        showingResetAlert = true
                                    } label: {
                                        SettingsRow(
                                            icon: .warning,
                                            title: "Reset Setup",
                                            detail: nil,
                                            tint: .red
                                        )
                                    }
                                    .buttonStyle(BabciaGlassCardButtonStyle())
                                    .babciaGlassCard(interactive: true)
                                    .babciaFullWidthLeading()
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: BabciaSpacing.md) {
                            Text("Appearance")
                                .font(.babcia(.headingSm))
                                .foregroundColor(.primary)

                            BabciaGlassGroup(spacing: 20) {
                                VStack(spacing: BabciaSpacing.listItemGap) {
                                    Menu {
                                        ForEach(AppTheme.allCases, id: \.self) { theme in
                                            Button(theme.displayName) {
                                                appViewModel.updateTheme(theme)
                                            }
                                        }
                                    } label: {
                                        SettingsPickerRow(title: "Theme", value: appViewModel.settings.theme.displayName)
                                    }
                                    .buttonStyle(BabciaGlassCardButtonStyle())
                                    .babciaGlassCard(interactive: true)
                                    .babciaFullWidthLeading()

                                    Menu {
                                        ForEach(BabciaCharacter.allCases) { character in
                                            Button(character.displayName) {
                                                appViewModel.updateSelectedCharacter(character)
                                            }
                                        }
                                    } label: {
                                        SettingsPickerRow(title: "Babcia Mode", value: appViewModel.settings.selectedCharacter.displayName)
                                    }
                                    .buttonStyle(BabciaGlassCardButtonStyle())
                                    .babciaGlassCard(interactive: true)
                                    .babciaFullWidthLeading()
                                }
                            }

                            Text("Babcia Mode controls how strict verification feels.")
                                .font(.babcia(.caption))
                                .foregroundColor(.secondary)
                        }
                    }
                    .babciaScreenPadding()
                    .babciaTabBarPadding()
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingSettingsDetail) {
                SettingsDetailView()
            }
            .alert("Reset Setup", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    appViewModel.resetSetup()
                }
            } message: {
                Text("This will clear API keys and setup status.")
            }
        }
    }

    private var connectionsStatus: String {
        let hasGemini = !appViewModel.settings.geminiAPIKey.isEmpty
        let hasHA = !appViewModel.settings.homeAssistantURL.isEmpty && !appViewModel.settings.homeAssistantToken.isEmpty

        switch (hasGemini, hasHA) {
        case (true, true):
            return "Gemini + Home Assistant"
        case (true, false):
            return "Gemini only"
        case (false, true):
            return "Home Assistant only"
        default:
            return "Not configured"
        }
    }
}

struct SettingsRow: View {
    let icon: BabciaIcon
    let title: String
    let detail: String?
    var tint: Color = .blue

    var body: some View {
        HStack(spacing: BabciaSpacing.md) {
            Image(systemName: icon.systemName)
                .font(.system(size: BabciaSize.iconSm, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: BabciaSize.buttonSm, height: BabciaSize.buttonSm)
                .background(tint)
                .cornerRadius(BabciaCorner.sm)

            VStack(alignment: .leading, spacing: BabciaSpacing.xxs) {
                Text(title)
                    .font(.babcia(.bodyLg))

                if let detail {
                    Text(detail)
                        .font(.babcia(.caption))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
            Image(systemName: BabciaIcon.chevronRight.systemName)
                .font(.system(size: BabciaSize.iconXs, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, BabciaSpacing.xs)
        .padding(.horizontal, BabciaSpacing.md)
        .babciaFullWidthLeading()
    }
}

struct SettingsPickerRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: BabciaSpacing.md) {
            Text(title)
                .font(.babcia(.bodyLg))
                .foregroundColor(.primary)

            Spacer()

            Text(value)
                .font(.babcia(.caption))
                .foregroundColor(.secondary)

            Image(systemName: BabciaIcon.chevronRight.systemName)
                .font(.system(size: BabciaSize.iconXs, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, BabciaSpacing.xs)
        .padding(.horizontal, BabciaSpacing.md)
        .babciaFullWidthLeading()
    }
}

struct SettingsDetailView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var geminiKey = ""
    @State private var homeAssistantURL = ""
    @State private var homeAssistantToken = ""
    @State private var defaultCameraEntityId = ""
    @State private var geminiTestResult: String?
    @State private var haTestResult: String?
    @State private var isTestingGemini = false
    @State private var isTestingHA = false

    var body: some View {
        NavigationStack {
            ZStack {
                BabciaBackground(style: .gradient(appViewModel.settings.selectedCharacter, .subtle))

                ScrollView {
                    VStack(alignment: .leading, spacing: BabciaSpacing.sectionGap) {
                        VStack(alignment: .leading, spacing: BabciaSpacing.md) {
                            Text("Gemini")
                                .font(.babcia(.headingSm))

                            BabciaSecureField("Gemini API Key", text: $geminiKey)
                                .accessibilityLabel("Gemini API Key")

                            Button(isTestingGemini ? "Testing..." : "Test Gemini") {
                                testGemini()
                            }
                            .babciaGlassButton()
                            .disabled(isTestingGemini || geminiKey.isEmpty)

                            if let geminiTestResult {
                                Text(geminiTestResult)
                                    .font(.babcia(.caption))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .babciaCardPadding()
                        .babciaGlassCard()
                        .babciaFullWidthLeading()

                        VStack(alignment: .leading, spacing: BabciaSpacing.md) {
                            Text("Home Assistant")
                                .font(.babcia(.headingSm))

                            BabciaTextField(
                                "Base URL",
                                text: $homeAssistantURL,
                                keyboardType: .URL,
                                textContentType: .URL,
                                capitalization: .never,
                                disableAutocorrection: true
                            )

                            BabciaSecureField("Access Token", text: $homeAssistantToken)
                                .accessibilityLabel("Home Assistant Access Token")

                            BabciaTextField(
                                "Default Camera Entity ID",
                                text: $defaultCameraEntityId,
                                capitalization: .never,
                                disableAutocorrection: true
                            )

                            Button(isTestingHA ? "Testing..." : "Test Home Assistant") {
                                testHomeAssistant()
                            }
                            .babciaGlassButton()
                            .disabled(isTestingHA || homeAssistantURL.isEmpty || homeAssistantToken.isEmpty)

                            if let haTestResult {
                                Text(haTestResult)
                                    .font(.babcia(.caption))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .babciaCardPadding()
                        .babciaGlassCard()
                        .babciaFullWidthLeading()
                    }
                    .babciaScreenPadding()
                    .babciaTabBarPadding()
                }
            }
            .navigationTitle("Connections")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                }
            }
            .onAppear {
                geminiKey = appViewModel.settings.geminiAPIKey
                homeAssistantURL = appViewModel.settings.homeAssistantURL
                homeAssistantToken = appViewModel.settings.homeAssistantToken
                defaultCameraEntityId = appViewModel.settings.defaultCameraEntityId
            }
        }
    }

    private func save() {
        appViewModel.updateSettings(
            geminiKey: geminiKey,
            homeAssistantURL: homeAssistantURL,
            homeAssistantToken: homeAssistantToken,
            defaultCameraEntityId: defaultCameraEntityId
        )
    }

    private func testGemini() {
        isTestingGemini = true
        geminiTestResult = nil

        Task {
            let valid = await appViewModel.validateGeminiKey(geminiKey)
            await MainActor.run {
                geminiTestResult = valid ? "Gemini key is valid" : "Gemini key is invalid"
                isTestingGemini = false
            }
        }
    }

    private func testHomeAssistant() {
        isTestingHA = true
        haTestResult = nil

        Task {
            let ok = await appViewModel.testHomeAssistantConnection(
                baseURL: homeAssistantURL.trimmingCharacters(in: .whitespacesAndNewlines),
                token: homeAssistantToken.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            await MainActor.run {
                haTestResult = ok ? "Home Assistant connected" : "Home Assistant failed"
                isTestingHA = false
            }
        }
    }
}
