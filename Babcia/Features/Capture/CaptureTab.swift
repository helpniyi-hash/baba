import SwiftUI
import Presentation
import Common
import Core
import UIKit

struct CaptureTab: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var selectedRoomID: UUID?
    @State private var showingCreateRoom = false
    @State private var showingScanOptions = false
    @State private var showingImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary

    private var selectedRoom: Room? {
        if let selectedRoomID {
            return appViewModel.rooms.first { $0.id == selectedRoomID }
        }
        return appViewModel.rooms.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BabciaBackground(style: .gradient(appViewModel.settings.selectedCharacter, .subtle))

                ScrollView {
                    VStack(spacing: BabciaSpacing.sectionGap) {
                        if let room = selectedRoom {
                            RoomPreviewCard(room: room)

                            Button {
                                showingScanOptions = true
                            } label: {
                                HStack(spacing: BabciaSpacing.sm) {
                                    Image(systemName: BabciaIcon.capture.systemName)
                                    Text("Scan Now")
                                        .font(.babcia(.headingSm))
                                }
                                .foregroundColor(.white)
                                .babciaFullWidth()
                                .padding(.vertical, BabciaSpacing.md)
                            }
                            .tint(.black)
                            .babciaGlassButtonProminent()
                            .controlSize(.large)
                            .accessibilityLabel("Scan now")
                        } else {
                            EmptyStateCard(
                                title: "No rooms yet",
                                message: "Create a room to start scanning."
                            ) {
                                showingCreateRoom = true
                            }
                        }

                        if !appViewModel.rooms.isEmpty {
                            RoomPickerCard(
                                rooms: appViewModel.rooms,
                                selectedRoomID: Binding(
                                    get: { selectedRoom?.id },
                                    set: { selectedRoomID = $0 }
                                )
                            )
                        }
                    }
                    .babciaScreenPadding()
                }
            }
            .navigationTitle("Capture")
            .sheet(isPresented: $showingCreateRoom) {
                CreateRoomSheet()
            }
            .confirmationDialog("Scan Room", isPresented: $showingScanOptions) {
                if let room = selectedRoom {
                    if room.imageSource == .homeAssistant {
                        Button("Use Home Assistant") {
                            appViewModel.scanHomeAssistant(roomID: room.id)
                        }
                    }
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button("Take Photo") {
                            imagePickerSource = .camera
                            showingImagePicker = true
                        }
                    }
                    Button("Choose Photo") {
                        imagePickerSource = .photoLibrary
                        showingImagePicker = true
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(sourceType: imagePickerSource) { image in
                    if let room = selectedRoom {
                        let source: CaptureSource = imagePickerSource == .camera ? .camera : .manual
                        appViewModel.scanRoom(roomID: room.id, image: image, captureSource: source)
                    }
                }
            }
            .onAppear {
                if selectedRoomID == nil {
                    selectedRoomID = appViewModel.rooms.first?.id
                }
            }
        }
    }
}

struct RoomPreviewCard: View {
    let room: Room

    var body: some View {
        let accent = Color(hex: room.character.accentHex)
        VStack(alignment: .leading, spacing: BabciaSpacing.md) {
            Text(room.name)
                .font(.babcia(.headingSm))

            ZStack {
                if let url = room.dreamVisionURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            Image(room.character.headshotAssetName)
                                .resizable()
                                .scaledToFit()
                                .padding(BabciaSpacing.xxl)
                        }
                    }
                } else {
                    Image(room.character.headshotAssetName)
                        .resizable()
                        .scaledToFit()
                        .padding(BabciaSpacing.xxl)
                }
            }
            .frame(height: BabciaSize.cardImageMd)
            .background(Color(.secondarySystemBackground))
            .clipped()
            .cornerRadius(BabciaCorner.cardImage)
            .overlay(
                RoundedRectangle(cornerRadius: BabciaCorner.cardImage)
                    .stroke(accent.opacity(0.4), lineWidth: 1)
            )

            Text("Character: \(room.character.displayName)")
                .font(.babcia(.caption))
                .foregroundColor(.secondary)
        }
        .babciaCardPadding()
        .babciaGlassCard()
        .babciaFullWidthLeading()
    }
}

struct RoomPickerCard: View {
    let rooms: [Room]
    @Binding var selectedRoomID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: BabciaSpacing.md) {
            Text("Select Room")
                .font(.babcia(.headingSm))

            Picker("Room", selection: $selectedRoomID) {
                ForEach(rooms) { room in
                    Text(room.name).tag(Optional(room.id))
                }
            }
            .pickerStyle(.menu)
        }
        .babciaCardPadding()
        .babciaGlassCard()
        .babciaFullWidthLeading()
    }
}
