import SwiftUI
import Core
import Presentation
import UIKit

struct CaptureTab: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var selectedRoomID: UUID?
    @State private var showingCreateRoom = false
    @State private var showingScanOptions = false
    @State private var showingImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary

    private var rooms: [Room] {
        appViewModel.rooms
    }

    private var selectedRoom: Room? {
        if let selectedRoomID {
            return appViewModel.rooms.first { $0.id == selectedRoomID }
        }
        return appViewModel.rooms.first
    }

    var body: some View {
        NavigationStack {
            BabciaVStack {
                Text("Capture")
                    .babciaPadding()
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .trailing) {
                        Button {
                            showingCreateRoom = true
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.title2)
                        }
                        .babciaPadding()
                        .accessibilityLabel("Create area")
                    }

                if rooms.isEmpty {
                    EmptyCaptureState { showingCreateRoom = true }
                } else {
                    BabciaCoverFlow(height: .fillUpTheSpace, data: rooms, id: \.id) { room in
                        Button {
                            selectedRoomID = room.id
                            showingScanOptions = true
                        } label: {
                            CaptureRoomCard(room: room)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .babciaScreen()
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
        }
    }
}

struct CaptureRoomCard: View {
    let room: Room

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let url = room.dreamVisionURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Image(room.character.portraitAssetName)
                            .resizable()
                            .scaledToFill()
                    }
                }
            } else {
                Image(room.character.portraitAssetName)
                    .resizable()
                    .scaledToFill()
            }

            Text(room.name)
                .babciaTextStyle(.headline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .babciaCornerRadius()
                .padding(16)
        }
        .frame(maxWidth: .infinity)
        .clipped()
        .babciaCornerRadius()
    }
}

struct EmptyCaptureState: View {
    let action: () -> Void

    var body: some View {
        BabciaVStack(spacing: .small) {
            Text("No areas yet")
                .babciaTextStyle(.headline)

            Text("Create an area to start scanning.")
                .babciaTextStyle(.caption1)
                .foregroundColor(.secondary)

            BabciaButton(title: "Create area", leftIcon: "plus") {
                action()
            }
        }
        .babciaPadding()
    }
}
