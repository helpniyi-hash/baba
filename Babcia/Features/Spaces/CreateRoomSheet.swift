import SwiftUI
import Presentation
import Common
import Core
import UIKit

struct CreateRoomSheet: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var character: BabciaCharacter = .classic
    @State private var imageSource: RoomImageSource = .iphone
    @State private var cameraIdentifier = ""
    @State private var haCameras: [HACamera] = []
    @State private var isLoadingCameras = false
    @State private var cameraError: String?
    @State private var previewImage: UIImage?
    @State private var isLoadingPreview = false
    @State private var didLoadCameras = false

    var body: some View {
        NavigationStack {
            ZStack {
                BabciaBackground(style: .gradient(appViewModel.settings.selectedCharacter, .primary))

                ScrollView {
                    VStack(alignment: .leading, spacing: BabciaSpacing.sectionGap) {
                        VStack(alignment: .leading, spacing: BabciaSpacing.md) {
                            Text("Room")
                                .font(.babcia(.headingSm))

                            BabciaTextField("Room name", text: $name, capitalization: .words)
                        }
                        .babciaCardPadding()
                        .babciaGlassCard()
                        .babciaFullWidthLeading()

                        VStack(alignment: .leading, spacing: BabciaSpacing.md) {
                            Text("Character")
                                .font(.babcia(.headingSm))

                            Menu {
                                ForEach(BabciaCharacter.allCases) { character in
                                    Button(character.displayName) {
                                        self.character = character
                                    }
                                }
                            } label: {
                                SettingsPickerRow(title: "Babcia", value: character.displayName)
                            }
                            .buttonStyle(BabciaGlassCardButtonStyle())
                            .babciaGlassCard()
                            .babciaFullWidthLeading()
                        }
                        .babciaCardPadding()
                        .babciaGlassCard()
                        .babciaFullWidthLeading()

                        VStack(alignment: .leading, spacing: BabciaSpacing.md) {
                            Text("Source")
                                .font(.babcia(.headingSm))

                            Menu {
                                Button("iPhone Camera") { imageSource = .iphone }
                                Button("Photo Library") { imageSource = .manual }
                                Button("Home Assistant") { imageSource = .homeAssistant }
                            } label: {
                                SettingsPickerRow(title: "Source", value: imageSourceName)
                            }
                            .buttonStyle(BabciaGlassCardButtonStyle())
                            .babciaGlassCard()
                            .babciaFullWidthLeading()

                            if imageSource == .homeAssistant {
                                if appViewModel.settings.homeAssistantURL.isEmpty || appViewModel.settings.homeAssistantToken.isEmpty {
                                    Text("Add your Home Assistant URL and token in Settings.")
                                        .font(.babcia(.caption))
                                        .foregroundColor(.secondary)
                                } else {
                                    Menu {
                                        ForEach(haCameras) { camera in
                                            Button(camera.name) { cameraIdentifier = camera.entityId }
                                        }
                                    } label: {
                                        SettingsPickerRow(title: "Camera", value: cameraIdentifier.isEmpty ? "Select camera" : cameraIdentifier)
                                    }
                                    .buttonStyle(BabciaGlassCardButtonStyle())
                                    .babciaGlassCard()
                                    .babciaFullWidthLeading()

                                    Button(isLoadingCameras ? "Loading Cameras..." : "Refresh Cameras") {
                                        loadHomeAssistantCameras(force: true)
                                    }
                                    .babciaGlassButton()
                                    .disabled(isLoadingCameras)

                                    if let cameraError {
                                        Text(cameraError)
                                            .font(.babcia(.caption))
                                            .foregroundColor(.red)
                                    }

                                    Group {
                                        if isLoadingPreview {
                                            ProgressView()
                                        } else if let previewImage {
                                            Image(uiImage: previewImage)
                                                .resizable()
                                                .scaledToFill()
                                        } else {
                                            Text("Select a camera to preview it.")
                                                .font(.babcia(.caption))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .frame(height: BabciaSize.cardImageSm)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(BabciaCorner.cardImage)
                                    .clipped()
                                }
                            }
                        }
                        .babciaCardPadding()
                        .babciaGlassCard()
                        .babciaFullWidthLeading()
                    }
                    .babciaScreenPadding()
                }
            }
            .navigationTitle("Create Room")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        createRoom()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              (imageSource == .homeAssistant && cameraIdentifier.isEmpty))
                }
            }
            .onAppear {
                if imageSource == .homeAssistant {
                    loadHomeAssistantCameras(force: false)
                }
            }
            .onChange(of: imageSource) { newValue in
                if newValue == .homeAssistant {
                    loadHomeAssistantCameras(force: false)
                } else {
                    cameraIdentifier = ""
                    previewImage = nil
                    cameraError = nil
                }
            }
            .onChange(of: cameraIdentifier) { newValue in
                if imageSource == .homeAssistant {
                    loadPreview(entityId: newValue)
                }
            }
        }
    }

    private func createRoom() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let identifier = imageSource == .homeAssistant ? cameraIdentifier : nil
        appViewModel.addRoom(
            name: trimmedName,
            character: character,
            imageSource: imageSource,
            cameraIdentifier: identifier
        )
        dismiss()
    }

    private var imageSourceName: String {
        switch imageSource {
        case .iphone:
            return "iPhone Camera"
        case .manual:
            return "Photo Library"
        case .homeAssistant:
            return "Home Assistant"
        case .stream:
            return "Stream"
        }
    }

    private func loadHomeAssistantCameras(force: Bool) {
        guard !appViewModel.settings.homeAssistantURL.isEmpty,
              !appViewModel.settings.homeAssistantToken.isEmpty else {
            cameraError = "Missing Home Assistant credentials."
            return
        }

        if didLoadCameras && !force { return }
        didLoadCameras = true
        isLoadingCameras = true
        cameraError = nil

        Task {
            do {
                let cameras = try await appViewModel.fetchHomeAssistantCameras()
                await MainActor.run {
                    haCameras = cameras
                    if cameraIdentifier.isEmpty {
                        cameraIdentifier = cameras.first?.entityId ?? ""
                    }
                    isLoadingCameras = false
                }
            } catch {
                await MainActor.run {
                    cameraError = error.localizedDescription
                    isLoadingCameras = false
                }
            }
        }
    }

    private func loadPreview(entityId: String) {
        guard !entityId.isEmpty else {
            previewImage = nil
            return
        }

        isLoadingPreview = true

        Task {
            do {
                let image = try await appViewModel.fetchHomeAssistantSnapshot(entityId: entityId)
                await MainActor.run {
                    previewImage = image
                    isLoadingPreview = false
                }
            } catch {
                await MainActor.run {
                    previewImage = nil
                    cameraError = error.localizedDescription
                    isLoadingPreview = false
                }
            }
        }
    }
}

private struct SettingsPickerRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: BabciaSpacing.sm) {
            Text(title)
                .font(.babcia(.bodyMd))

            Spacer(minLength: BabciaSpacing.sm)

            Text(value)
                .font(.babcia(.bodyMd))
                .foregroundColor(.secondary)

            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: BabciaSize.iconSm))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, BabciaSpacing.xs)
        .padding(.horizontal, BabciaSpacing.md)
    }
}
