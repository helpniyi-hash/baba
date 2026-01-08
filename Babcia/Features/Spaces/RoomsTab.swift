import SwiftUI
import Presentation
import Common
import Core

struct RoomsTab: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var showingCreateRoom = false

    var body: some View {
        NavigationStack {
            ZStack {
                BabciaBackground(style: .gradient(appViewModel.settings.selectedCharacter, .vibrant))

                ScrollView {
                    VStack(spacing: BabciaSpacing.sectionGap) {
                        ProgressCard(totalXP: appViewModel.totalXP, level: appViewModel.level)

                        DreamGallerySection(rooms: appViewModel.rooms)

                        RoomsListCard(rooms: appViewModel.rooms)
                    }
                    .babciaScreenPadding()
                    .babciaTabBarPadding()
                }
            }
            .navigationTitle("Spaces")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateRoom = true
                    } label: {
                        Image(systemName: BabciaIcon.add.systemName)
                    }
                    .accessibilityLabel("Create room")
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

struct DreamGallerySection: View {
    let rooms: [Room]
    @Namespace private var dreamNamespace

    var body: some View {
        VStack(alignment: .leading, spacing: BabciaSpacing.md) {
            Text("Dream Gallery")
                .font(.babcia(.headingSm))

            if rooms.isEmpty {
                Text("No rooms yet. Add one to begin.")
                    .font(.babcia(.caption))
                    .foregroundColor(.secondary)
            } else {
                BabciaGlassGroup(spacing: 40) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: BabciaSpacing.cardGap) {
                            ForEach(rooms) { room in
                                DreamThumbnail(room: room)
                                    .babciaGlassEffectID(room.id, in: dreamNamespace)
                            }
                        }
                        .padding(.horizontal, BabciaSpacing.xs)
                        .padding(.vertical, BabciaSpacing.xs)
                    }
                }
            }
        }
        .babciaCardPadding()
        .babciaGlassCard()
        .babciaFullWidthLeading()
    }
}

struct DreamThumbnail: View {
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
                            .padding(BabciaSpacing.sm)
                    }
                }
            } else {
                Image(room.character.headshotAssetName)
                    .resizable()
                    .scaledToFit()
                    .padding(BabciaSpacing.sm)
            }
        }
        .frame(width: BabciaSize.thumbnailLg, height: BabciaSize.cardImageSm)
        .background(Color(.secondarySystemBackground))
        .clipped()
        .cornerRadius(BabciaCorner.cardImage)
        .overlay(
            RoundedRectangle(cornerRadius: BabciaCorner.cardImage)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

struct RoomsListCard: View {
    let rooms: [Room]
    @Namespace private var roomsNamespace

    var body: some View {
        VStack(alignment: .leading, spacing: BabciaSpacing.md) {
            Text("Rooms")
                .font(.babcia(.headingSm))

            if rooms.isEmpty {
                Text("No rooms yet. Tap + to add one.")
                    .font(.babcia(.caption))
                    .foregroundColor(.secondary)
            } else {
                BabciaGlassGroup(spacing: 12) {
                    VStack(spacing: BabciaSpacing.listItemGap) {
                        ForEach(rooms) { room in
                            NavigationLink(value: room.id) {
                                RoomRow(room: room)
                            }
                            .babciaGlassEffectID(room.id, in: roomsNamespace)
                        }
                    }
                }
            }
        }
        .babciaCardPadding()
        .babciaGlassCard()
        .babciaFullWidthLeading()
    }
}

struct RoomRow: View {
    let room: Room

    var body: some View {
        HStack(spacing: BabciaSpacing.md) {
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
                                .padding(BabciaSpacing.xxs)
                        }
                    }
                } else {
                    Image(room.character.headshotAssetName)
                        .resizable()
                        .scaledToFit()
                        .padding(BabciaSpacing.xxs)
                }
            }
            .frame(width: BabciaSize.thumbnailSm, height: BabciaSize.thumbnailSm)
            .background(Color(.secondarySystemBackground))
            .clipped()
            .cornerRadius(BabciaCorner.cardImage)

            VStack(alignment: .leading, spacing: BabciaSpacing.xxs) {
                Text(room.name)
                    .font(.babcia(.headingSm))

                Text("\(room.pendingTaskCount) pending")
                    .font(.babcia(.caption))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(room.streak)d")
                .font(.babcia(.caption))
                .foregroundColor(.secondary)
        }
        .padding(BabciaSpacing.sm)
        .babciaFullWidthLeading()
    }
}
