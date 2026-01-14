import SwiftUI
import Core
import Presentation

struct SettingsTab: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var showingSettingsDetail = false
    @State private var showingResetAlert = false

    private var connectionsStatus: String {
        let geminiOK = !appViewModel.settings.geminiAPIKey.isEmpty
        let haOK = !appViewModel.settings.homeAssistantURL.isEmpty
        if geminiOK && haOK { return "All connected" }
        if geminiOK { return "Gemini only" }
        if haOK { return "Home Assistant only" }
        return "Not configured"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                BabciaVStack {
                    ProfileHeader(character: appViewModel.settings.selectedCharacter)

                    SettingsGroup(title: "Setup") {
                        SettingsActionRow(
                            icon: "link",
                            title: "Connections",
                            detail: connectionsStatus
                        ) {
                            showingSettingsDetail = true
                        }
                    }

                    SettingsGroup(title: "Appearance") {
                        SettingsMenuRow(
                            icon: "paintbrush",
                            title: "Theme",
                            value: appViewModel.settings.theme.displayName,
                            options: AppTheme.allCases.map { ($0.displayName, $0) },
                            onSelect: { appViewModel.updateTheme($0) }
                        )

                        SettingsMenuRow(
                            icon: "person.crop.circle",
                            title: "Character",
                            value: appViewModel.settings.selectedCharacter.displayName,
                            options: BabciaCharacter.allCases.map { ($0.displayName, $0) },
                            onSelect: { appViewModel.updateSelectedCharacter($0) }
                        )
                    }
                }
                .babciaPadding()
            }
            .safeAreaInset(edge: .bottom) {
                BabciaBottomContainer {
                    BabciaButton(title: "Reset Setup", style: .secondary) {
                        showingResetAlert = true
                    }
                }
            }
            .babciaScreen()
            .navigationTitle("Settings")
            .sheet(isPresented: $showingSettingsDetail) {
                SetupConnectionsView()
            }
            .alert("Reset Setup", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    appViewModel.resetSetup()
                }
            } message: {
                Text("This will clear all your settings and data.")
            }
        }
    }
}

// MARK: - Profile Header

extension SettingsTab {
    struct ProfileHeader: View {
        let character: BabciaCharacter

        var body: some View {
            BabciaVStack(alignment: .center, spacing: .regular) {
                Image(character.headshotAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color(hex: character.accentHex), lineWidth: 3)
                    )

                BabciaVStack(alignment: .center, spacing: .zero) {
                    Text(character.displayName)
                        .babciaTextStyle(.headline)
                    Text(character.tagline)
                        .babciaTextStyle(.smallSubheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .babciaPadding(.vertical, .large)
        }
    }
}

// MARK: - Settings Group

extension SettingsTab {
    struct SettingsGroup<Content: View>: View {
        let title: String
        @ViewBuilder let content: () -> Content

        var body: some View {
            BabciaVStack(spacing: .small) {
                Text(title)
                    .babciaTextStyle(.smallSubheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                BabciaVStack(spacing: .small) {
                    content()
                }
            }
        }
    }
}

// MARK: - Action Row

extension SettingsTab {
    struct SettingsActionRow: View {
        @Environment(\.babciaAppearance) private var appearance

        let icon: String
        let title: String
        let detail: String?
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                BabciaHStack {
                    Image(systemName: icon)
                        .foregroundColor(appearance.accentColor.color)
                        .frame(width: 24)

                    Text(title)
                        .babciaTextStyle(.smallHeadline)

                    Spacer()

                    if let detail {
                        Text(detail)
                            .babciaTextStyle(.caption1)
                            .foregroundColor(.secondary)
                    }

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .babciaPadding(.horizontal, .regular)
                .frame(height: appearance.actionElementHeight)
                .babciaSecondaryBackground()
                .babciaCornerRadius()
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Menu Row

extension SettingsTab {
    struct SettingsMenuRow<T: Hashable>: View {
        let icon: String
        let title: String
        let value: String
        let options: [(String, T)]
        let onSelect: (T) -> Void

        var body: some View {
            Menu {
                ForEach(options, id: \.1) { option in
                    Button(option.0) { onSelect(option.1) }
                }
            } label: {
                SettingsActionLabel(icon: icon, title: title, detail: value)
            }
            .buttonStyle(.plain)
        }
    }

    struct SettingsActionLabel: View {
        @Environment(\.babciaAppearance) private var appearance

        let icon: String
        let title: String
        let detail: String

        var body: some View {
            BabciaHStack {
                Image(systemName: icon)
                    .foregroundColor(appearance.accentColor.color)
                    .frame(width: 24)

                Text(title)
                    .babciaTextStyle(.smallHeadline)

                Spacer()

                Text(detail)
                    .babciaTextStyle(.caption1)
                    .foregroundColor(.secondary)

                Image(systemName: "chevron.up.chevron.down")
                    .foregroundColor(.secondary)
            }
            .babciaPadding(.horizontal, .regular)
            .frame(height: appearance.actionElementHeight)
            .babciaSecondaryBackground()
            .babciaCornerRadius()
        }
    }
}

// MARK: - Placeholder Views

struct SetupConnectionsView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Text("Connections Setup")
                .navigationTitle("Connections")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

#Preview {
    SettingsTab()
}
