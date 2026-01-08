import SwiftUI
import Presentation
import Common
import Core

struct HomeTab: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    private var verificationRooms: [Room] {
        appViewModel.rooms
            .filter { $0.pendingTaskCount > 0 }
            .sorted { $0.pendingTaskCount > $1.pendingTaskCount }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BabciaBackground(style: .gradient(appViewModel.settings.selectedCharacter, .subtle))

                ScrollView {
                    VStack(spacing: BabciaSpacing.sectionGap) {
                        ProfileHeaderCard(
                            character: appViewModel.settings.selectedCharacter,
                            displayName: "Darling",
                            level: appViewModel.level
                        )

                        StatsGrid(
                            totalXP: appViewModel.totalXP,
                            level: appViewModel.level,
                            currentStreak: appViewModel.currentStreak,
                            bestStreak: appViewModel.bestStreak
                        )

                        VerificationQueueCard(rooms: verificationRooms)

                        RecentTasksCard()

                        RecentActivityCard()
                    }
                    .babciaScreenPadding()
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: UUID.self) { roomID in
                RoomDetailView(roomID: roomID)
            }
        }
    }
}

struct ProfileHeaderCard: View {
    let character: BabciaCharacter
    let displayName: String
    let level: Int

    var body: some View {
        HStack(spacing: BabciaSpacing.lg) {
            BabciaAvatar(
                image: Image(character.headshotAssetName),
                size: .xl,
                ringColor: Color(hex: character.accentHex)
            )

            VStack(alignment: .leading, spacing: BabciaSpacing.xs) {
                Text(displayName)
                    .font(.babcia(.headingLg))

                Text(character.displayName)
                    .font(.babcia(.bodyMd))
                    .foregroundColor(.secondary)

                Text("Level \(level)")
                    .font(.babcia(.captionBold))
                    .padding(.horizontal, BabciaSpacing.sm)
                    .padding(.vertical, BabciaSpacing.xxs)
                    .background(Color(hex: character.accentHex).opacity(BabciaOpacity.light))
                    .cornerRadius(BabciaCorner.chip)
            }

            Spacer()
        }
        .babciaGlassCard()
        .babciaFullWidthLeading()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(displayName), \(character.displayName), level \(level)")
    }
}

struct StatMetric: Identifiable {
    let id: String
    let title: String
    let value: String
    let icon: BabciaIcon
    let color: Color
}

struct StatsGrid: View {
    let totalXP: Int
    let level: Int
    let currentStreak: Int
    let bestStreak: Int

    @Namespace private var statsNamespace

    private var metrics: [StatMetric] {
        [
            StatMetric(id: "xp", title: "Total XP", value: "\(totalXP)", icon: .xp, color: .purple),
            StatMetric(id: "level", title: "Level", value: "\(level)", icon: .level, color: .yellow),
            StatMetric(id: "current", title: "Current Streak", value: "\(currentStreak)d", icon: .streak, color: .orange),
            StatMetric(id: "best", title: "Best Streak", value: "\(bestStreak)d", icon: .streak, color: .blue)
        ]
    }

    var body: some View {
        BabciaGlassGroup(spacing: 40) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: BabciaSpacing.cardGap) {
                ForEach(metrics) { metric in
                    StatCard(metric: metric)
                        .babciaGlassEffectID(metric.id, in: statsNamespace)
                }
            }
        }
    }
}

struct StatCard: View {
    let metric: StatMetric

    var body: some View {
        VStack(alignment: .leading, spacing: BabciaSpacing.md) {
            HStack {
                Image(systemName: metric.icon.systemName)
                    .font(.system(size: BabciaSize.iconLg, weight: .semibold))
                    .foregroundColor(metric.color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: BabciaSpacing.xxs) {
                Text(metric.value)
                    .font(.babcia(.headingSm))
                    .contentTransition(.numericText())

                Text(metric.title)
                    .font(.babcia(.caption))
                    .foregroundColor(.secondary)
            }
        }
        .babciaCardPadding()
        .babciaFullWidthLeading()
        .babciaGlassCard(style: .subtle, cornerRadius: BabciaCorner.card, shadow: .sm)
    }
}

struct RecentActivityCard: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    private var entries: [HistoryEntry] {
        HistoryEntry.build(from: appViewModel.rooms)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BabciaSpacing.md) {
            HStack {
                Text("Recent Activity")
                    .font(.babcia(.headingSm))
                Spacer()
                NavigationLink {
                    HistoryView(rooms: appViewModel.rooms, character: appViewModel.settings.selectedCharacter)
                } label: {
                    Text("View all")
                        .font(.babcia(.labelSm))
                        .foregroundColor(.secondary)
                }
            }

            if entries.isEmpty {
                Text("No history yet. Scan a room to get started.")
                    .font(.babcia(.caption))
                    .foregroundColor(.secondary)
            } else {
                BabciaGlassGroup(spacing: 12) {
                    VStack(spacing: BabciaSpacing.listItemGap) {
                        ForEach(entries.prefix(3)) { entry in
                            NavigationLink(value: entry.roomID) {
                                HistoryRow(entry: entry, useSurface: false)
                            }
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

struct VerificationQueueCard: View {
    let rooms: [Room]
    @Namespace private var queueNamespace

    var body: some View {
        VStack(alignment: .leading, spacing: BabciaSpacing.md) {
            Text("Needs Verification")
                .font(.babcia(.headingSm))

            if rooms.isEmpty {
                Text("All rooms are verified. Nice work.")
                    .font(.babcia(.caption))
                    .foregroundColor(.secondary)
            } else {
                BabciaGlassGroup(spacing: 20) {
                    VStack(spacing: BabciaSpacing.listItemGap) {
                        ForEach(rooms.prefix(4)) { room in
                            NavigationLink(value: room.id) {
                                VerificationQueueRow(room: room)
                            }
                            .babciaGlassEffectID(room.id, in: queueNamespace)
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

struct VerificationQueueRow: View {
    let room: Room

    var body: some View {
        HStack(spacing: BabciaSpacing.md) {
            Image(room.character.headshotAssetName)
                .resizable()
                .scaledToFill()
                .frame(width: BabciaSize.avatarSm, height: BabciaSize.avatarSm)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: BabciaSpacing.xxs) {
                Text(room.name)
                    .font(.babcia(.bodyLg))
                Text("\(room.pendingTaskCount) tasks pending")
                    .font(.babcia(.caption))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("Verify")
                .font(.babcia(.captionBold))
                .foregroundColor(.secondary)
        }
    }
}

struct AppModeCard: View {
    let character: BabciaCharacter

    var body: some View {
        VStack(alignment: .leading, spacing: BabciaSpacing.sm) {
            Text("App Mode")
                .font(.babcia(.headingSm))

            HStack(spacing: BabciaSpacing.md) {
                BabciaAvatar(
                    image: Image(character.headshotAssetName),
                    size: .sm,
                    ringColor: Color(hex: character.accentHex)
                )

                VStack(alignment: .leading, spacing: BabciaSpacing.xxs) {
                    Text("\(character.displayName) - \(character.verificationModeName)")
                        .font(.babcia(.bodyMd))
                    Text(character.verificationModeDescription)
                        .font(.babcia(.caption))
                        .foregroundColor(.secondary)
                }
            }
        }
        .babciaCardPadding()
        .babciaGlassCard()
        .babciaFullWidthLeading()
    }
}

struct RecentTasksCard: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @Namespace private var tasksNamespace

    private var taskItems: [(Room, CleaningTask)] {
        let items = appViewModel.rooms.flatMap { room in
            room.tasks.filter { $0.verificationState != .verified }.map { (room, $0) }
        }
        return Array(items.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BabciaSpacing.md) {
            Text("Today's Tasks")
                .font(.babcia(.headingSm))

            if taskItems.isEmpty {
                Text("Scan a room to get your first task list.")
                    .font(.babcia(.caption))
                    .foregroundColor(.secondary)
            } else {
                BabciaGlassGroup(spacing: 20) {
                    VStack(spacing: BabciaSpacing.listItemGap) {
                        ForEach(taskItems, id: \.1.id) { room, task in
                            NavigationLink(value: room.id) {
                                RecentTaskRow(room: room, task: task)
                            }
                            .babciaGlassEffectID(task.id, in: tasksNamespace)
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

struct RecentTaskRow: View {
    let room: Room
    let task: CleaningTask

    var body: some View {
        HStack(spacing: BabciaSpacing.md) {
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
            .frame(width: BabciaSize.avatarMd, height: BabciaSize.avatarMd)
            .background(Color(.secondarySystemBackground))
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: BabciaSpacing.xxs) {
                Text(room.name)
                    .font(.babcia(.caption))
                    .foregroundColor(.secondary)
                Text(task.title)
                    .font(.babcia(.bodyLg))
            }

            Spacer()

            Text("+\(task.xpReward)")
                .font(.babcia(.caption))
                .foregroundColor(.secondary)
        }
    }
}
