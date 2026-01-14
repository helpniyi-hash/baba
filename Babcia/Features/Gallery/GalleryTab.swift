import SwiftUI
import Core
import Presentation

struct GalleryTab: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var selectedItem: GalleryItem?

    private var allItems: [GalleryItem] {
        (dreamItems + captureItems).sorted { $0.date > $1.date }
    }

    private var dreamItems: [GalleryItem] {
        var items: [GalleryItem] = []

        for room in appViewModel.rooms {
            if let url = room.dreamVisionURL {
                items.append(
                    GalleryItem(
                        imageURL: url,
                        title: room.name,
                        subtitle: "Dream",
                        date: room.lastScanDate ?? Date.distantPast
                    )
                )
            }
            for history in room.scanHistory {
                if let url = history.dreamVisionURL {
                    items.append(
                        GalleryItem(
                            imageURL: url,
                            title: room.name,
                            subtitle: "Dream",
                            date: history.date
                        )
                    )
                }
            }
        }

        return items
    }

    private var captureItems: [GalleryItem] {
        var items: [GalleryItem] = []

        for room in appViewModel.rooms {
            for capture in room.userCaptures {
                if let url = capture.fileURL {
                    items.append(
                        GalleryItem(
                            imageURL: url,
                            title: room.name,
                            subtitle: capture.source.displayName,
                            date: capture.date
                        )
                    )
                }
            }
        }

        return items
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                BabciaVStack {
                    if allItems.isEmpty {
                        Text("No gallery items yet.")
                            .babciaTextStyle(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(allItems) { item in
                            Button {
                                selectedItem = item
                            } label: {
                                GalleryRow(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .babciaPadding()
            }
            .babciaScreen()
            .navigationTitle("Gallery")
            .sheet(item: $selectedItem) { item in
                GalleryDetailView(item: item)
            }
        }
    }
}

struct GalleryItem: Identifiable {
    let id = UUID()
    let imageURL: URL
    let title: String
    let subtitle: String
    let date: Date
}

struct GalleryRow: View {
    let item: GalleryItem

    private var dateText: String {
        item.date.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        BabciaHStack(spacing: .medium) {
            AsyncImage(url: item.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    Color.gray.opacity(0.2)
                }
            }
            .frame(width: 100, height: 120)
            .clipped()
            .babciaCornerRadius()

            BabciaVStack(alignment: .leading, spacing: .zero) {
                Text(item.title)
                    .babciaTextStyle(.smallHeadline)

                Text(item.subtitle)
                    .babciaTextStyle(.caption1)
                    .foregroundColor(.secondary)

                Text(dateText)
                    .babciaTextStyle(.caption2)
                    .foregroundColor(.secondary)
            }
            .babciaFullWidth()
        }
        .babciaPadding(.regular)
        .babciaSecondaryBackground()
        .babciaCornerRadius()
    }
}

struct GalleryDetailView: View {
    let item: GalleryItem

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            BabciaVStack(spacing: .regular) {
                AsyncImage(url: item.imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    default:
                        ProgressView()
                    }
                }

                BabciaVStack(spacing: .zero) {
                    Text(item.title)
                        .babciaTextStyle(.headline)
                        .foregroundColor(.white)
                    Text(item.subtitle)
                        .babciaTextStyle(.caption1)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .babciaPadding()
        }
    }
}
