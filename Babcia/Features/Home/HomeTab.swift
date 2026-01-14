import SwiftUI
import Core
import Presentation

struct HomeTab: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    private var pendingTaskCount: Int {
        appViewModel.rooms.reduce(0) { $0 + $1.pendingTaskCount }
    }

    private var featuredRooms: [Room] {
        let withDreams = appViewModel.rooms.filter { $0.dreamVisionURL != nil }
        return withDreams.isEmpty ? appViewModel.rooms : withDreams
    }

    private var categoryRooms: [Room] {
        appViewModel.rooms.sorted { $0.pendingTaskCount > $1.pendingTaskCount }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                BabciaVStack {
                    ProfileView(
                        title: "Welcome back",
                        subtitle: "\(appViewModel.rooms.count) areas • \(pendingTaskCount) tasks pending",
                        character: appViewModel.settings.selectedCharacter
                    )

                    if !featuredRooms.isEmpty {
                        BabciaCoverFlow(height: 220, data: featuredRooms, id: \.id) { room in
                            NavigationLink(value: room.id) {
                                RoomCoverImage(room: room)
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        EmptyStateView(message: "Create your first area to get started.")
                    }

                    if !categoryRooms.isEmpty {
                        BabciaHScroll(spacing: .regular, data: categoryRooms, id: \.id) { room in
                            NavigationLink(value: room.id) {
                                CategoryChip(title: room.name)
                            }
                            .buttonStyle(.plain)
                        }
                        .babciaPadding(.top, .small)
                    }

                    BabciaVStack {
                        BabciaSectionHeaderView(title: "Stats", actionTitle: "View all") {}

                        BabciaGrid(columns: 2, spacing: .regular, data: stats, id: \.title) { stat in
                            StatCard(stat: stat)
                        }
                    }
                }
                .babciaPadding()
            }
            .babciaScreen()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: UUID.self) { roomID in
                RoomDetailView(roomID: roomID)
            }
        }
    }

    private var stats: [Stat] {
        [
            Stat(title: "Total XP", value: "\(appViewModel.totalXP)", icon: "star.fill", color: .yellow),
            Stat(title: "Level", value: "\(appViewModel.level)", icon: "trophy.fill", color: .orange),
            Stat(title: "Current Streak", value: "\(appViewModel.currentStreak)d", icon: "flame.fill", color: .red),
            Stat(title: "Best Streak", value: "\(appViewModel.bestStreak)d", icon: "crown.fill", color: .purple)
        ]
    }
}

// MARK: - DSKit HomeScreen3 Views

extension HomeTab {
    struct ProfileView: View {
        let title: String
        let subtitle: String
        let character: BabciaCharacter
        @Environment(\.babciaAppearance) private var appearance

        var body: some View {
            BabciaHStack {
                BabciaVStack(spacing: .zero) {
                    Text(title)
                        .babciaTextStyle(.title1, appearance.primaryText.color)
                    Text(subtitle)
                        .babciaTextStyle(.subheadline, appearance.secondaryText.color)
                }

                Spacer()

                Image(character.headshotAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            }
        }
    }

    struct RoomCoverImage: View {
        let room: Room
        @Environment(\.babciaAppearance) private var appearance

        var body: some View {
            coverImage
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(appearance.secondaryBackground.color)
                .clipped()
                .babciaCornerRadius()
        }

        @ViewBuilder
        private var coverImage: some View {
            if let url = room.dreamVisionURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        fallbackImage
                    }
                }
            } else {
                fallbackImage
            }
        }

        private var fallbackImage: some View {
            Image(room.character.portraitAssetName)
                .resizable()
                .scaledToFill()
        }
    }

    struct CategoryChip: View {
        let title: String
        @Environment(\.babciaAppearance) private var appearance

        var body: some View {
            Text(title)
                .babciaTextStyle(.smallHeadline, appearance.primaryText.color)
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: 35)
                .babciaPadding(.horizontal, .large)
                .babciaSecondaryBackground()
                .babciaCornerRadius()
        }
    }

    struct Stat: Hashable {
        let title: String
        let value: String
        let icon: String
        let color: Color
    }

    struct StatCard: View {
        let stat: Stat
        @Environment(\.babciaAppearance) private var appearance

        var body: some View {
            BabciaVStack(alignment: .leading, spacing: .zero) {
                Image(systemName: stat.icon)
                    .foregroundColor(stat.color)

                BabciaVStack(alignment: .leading, spacing: .zero) {
                    Text(stat.value)
                        .babciaTextStyle(.smallHeadline, appearance.primaryText.color)
                    Text(stat.title)
                        .babciaTextStyle(.smallSubheadline, appearance.secondaryText.color)
                }
                .babciaPadding(.top, .small)
            }
            .babciaPadding()
            .babciaSecondaryBackground()
            .babciaCornerRadius()
        }
    }

    struct EmptyStateView: View {
        let message: String
        @Environment(\.babciaAppearance) private var appearance

        var body: some View {
            Text(message)
                .babciaTextStyle(.subheadline, appearance.secondaryText.color)
                .babciaFullWidth()
        }
    }
}
