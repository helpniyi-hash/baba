import SwiftUI
import Common
import Core

struct HistoryEntry: Identifiable {
    let id = UUID()
    let roomID: UUID
    let date: Date
    let title: String
    let subtitle: String
    let imageURL: URL?
    let fallbackAssetName: String

    static func build(from rooms: [Room]) -> [HistoryEntry] {
        var entries: [HistoryEntry] = []

        for room in rooms {
            let fallback = room.character.headshotAssetName

            for history in room.scanHistory {
                entries.append(
                    HistoryEntry(
                        roomID: room.id,
                        date: history.date,
                        title: room.name,
                        subtitle: "Dream scan",
                        imageURL: history.dreamVisionURL,
                        fallbackAssetName: fallback
                    )
                )
            }

            for capture in room.userCaptures {
                entries.append(
                    HistoryEntry(
                        roomID: room.id,
                        date: capture.date,
                        title: room.name,
                        subtitle: capture.source.displayName,
                        imageURL: capture.fileURL,
                        fallbackAssetName: fallback
                    )
                )
            }
        }

        return entries.sorted { $0.date > $1.date }
    }
}

struct HistoryView: View {
    let rooms: [Room]
    let character: BabciaCharacter

    private var entries: [HistoryEntry] {
        HistoryEntry.build(from: rooms)
    }

    var body: some View {
        ZStack {
            BabciaBackground(style: .gradient(character, .primary))

            ScrollView {
                VStack(alignment: .leading, spacing: BabciaSpacing.listItemGap) {
                    if entries.isEmpty {
                        Text("No history yet.")
                            .font(.babcia(.caption))
                            .foregroundColor(.secondary)
                            .padding(.top, BabciaSpacing.md)
                    } else {
                        ForEach(entries) { entry in
                            NavigationLink(value: entry.roomID) {
                                HistoryRow(entry: entry)
                            }
                        }
                    }
                }
                .babciaScreenPadding()
                .babciaTabBarPadding()
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HistoryRow: View {
    let entry: HistoryEntry
    let useSurface: Bool

    init(entry: HistoryEntry, useSurface: Bool = true) {
        self.entry = entry
        self.useSurface = useSurface
    }

    var body: some View {
        let content = HStack(spacing: BabciaSpacing.md) {
            ZStack {
                if let url = entry.imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            Image(entry.fallbackAssetName)
                                .resizable()
                                .scaledToFit()
                                .padding(BabciaSpacing.xxs)
                        }
                    }
                } else {
                    Image(entry.fallbackAssetName)
                        .resizable()
                        .scaledToFit()
                        .padding(BabciaSpacing.xxs)
                }
            }
            .frame(width: BabciaSize.thumbnailSm, height: BabciaSize.thumbnailSm)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(BabciaCorner.cardImage)
            .clipped()

            VStack(alignment: .leading, spacing: BabciaSpacing.xxs) {
                Text(entry.title)
                    .font(.babcia(.bodyLg))
                Text(entry.subtitle)
                    .font(.babcia(.caption))
                    .foregroundColor(.secondary)
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.babcia(.caption))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }

        if useSurface {
            content
                .babciaCardPadding()
                .babciaGlassCard()
                .babciaFullWidthLeading()
        } else {
            content
                .padding(.vertical, BabciaSpacing.xs)
        }
    }
}
