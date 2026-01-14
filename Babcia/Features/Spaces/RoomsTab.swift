import SwiftUI
import Core
import Presentation

struct AreasTab: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var showingCreateRoom = false

    var body: some View {
        NavigationStack {
            ScrollView {
                BabciaVStack(spacing: .small) {
                    if appViewModel.rooms.isEmpty {
                        Text("Create your first area to get started.")
                            .babciaTextStyle(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(appViewModel.rooms) { room in
                            NavigationLink(value: room.id) {
                                AreaRow(room: room)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .babciaPadding()
            }
            .babciaScreen()
            .navigationTitle("Areas")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateRoom = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create area")
                }
            }
            .sheet(isPresented: $showingCreateRoom) {
                CreateRoomSheet()
            }
            .navigationDestination(for: UUID.self) { roomID in
                RoomDetailView(roomID: roomID)
            }
        }
    }
}

// MARK: - Categories1 Row

extension AreasTab {
    struct AreaRow: View {
        let room: Room

        var body: some View {
            BabciaHStack(spacing: .medium) {
                RoomThumbnail(room: room)
                    .babciaPadding(.leading, .regular)
                    .babciaPadding(.vertical, .regular)

                BabciaVStack(alignment: .leading, spacing: .zero) {
                    Text(room.name)
                        .babciaTextStyle(.smallHeadline)
                    Text("\(room.pendingTaskCount) pending")
                        .babciaTextStyle(.caption1)
                        .foregroundColor(.secondary)
                }
                .babciaPadding(.vertical, .regular)
                .babciaFullWidth()
            }
            .overlay(alignment: .trailing) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .babciaPadding(.regular)
            }
            .babciaSecondaryBackground()
            .babciaCornerRadius()
        }
    }

    struct RoomThumbnail: View {
        let room: Room

        var body: some View {
            ZStack {
                if let url = room.dreamVisionURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            Image(room.character.headshotAssetName)
                                .resizable()
                                .scaledToFit()
                        }
                    }
                } else {
                    Image(room.character.headshotAssetName)
                        .resizable()
                        .scaledToFit()
                }
            }
            .frame(width: 60, height: 60)
            .clipped()
            .babciaCornerRadius()
        }
    }
}
