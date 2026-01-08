import SwiftUI
import Presentation
import Common
import Core

struct GalleryTab: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var selectedItem: GalleryItem?
    @State private var selectedSection: GallerySectionType?

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

        return items.sorted { $0.date > $1.date }
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

        return items.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BabciaBackground(style: .gradient(appViewModel.settings.selectedCharacter, .subtle))

                ScrollView {
                    VStack(spacing: BabciaSpacing.sectionGap) {
                        GalleryStackSection(
                            title: "Dreams",
                            items: dreamItems,
                            emptyMessage: "No dream visions yet.",
                            onSelect: { selectedItem = $0 },
                            onViewAll: { selectedSection = .dreams }
                        )

                        GalleryStackSection(
                            title: "Captures",
                            items: captureItems,
                            emptyMessage: "No captures yet.",
                            onSelect: { selectedItem = $0 },
                            onViewAll: { selectedSection = .captures }
                        )
                    }
                    .babciaScreenPadding()
                }
            }
            .navigationTitle("Gallery")
            .sheet(item: $selectedItem) { item in
                GalleryDetailView(item: item)
            }
            .sheet(item: $selectedSection) { section in
                GalleryGridView(
                    title: section.title,
                    items: section == .dreams ? dreamItems : captureItems,
                    character: appViewModel.settings.selectedCharacter,
                    onSelect: { selectedItem = $0 }
                )
            }
        }
    }
}

enum GallerySectionType: Identifiable {
    case dreams
    case captures

    var id: String { title }
    var title: String {
        switch self {
        case .dreams: return "Dreams"
        case .captures: return "Captures"
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

struct GalleryStackSection: View {
    let title: String
    let items: [GalleryItem]
    let emptyMessage: String
    let onSelect: (GalleryItem) -> Void
    let onViewAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: BabciaSpacing.md) {
            BabciaSectionHeader(title, actionTitle: "View all", action: onViewAll)

            if items.isEmpty {
                Text(emptyMessage)
                    .font(.babcia(.caption))
                    .foregroundColor(.secondary)
            } else {
                GalleryStackCarousel(items: items, onSelect: onSelect)
            }
        }
        .babciaCardPadding()
        .babciaGlassCard()
        .babciaFullWidthLeading()
    }
}

struct GalleryStackCarousel: View {
    let items: [GalleryItem]
    let onSelect: (GalleryItem) -> Void
    @State private var currentIndex = 0
    @GestureState private var dragOffset: CGFloat = 0
    @Namespace private var galleryNamespace

    private var cardWidth: CGFloat {
        min(UIScreen.main.bounds.width * 0.72, 280)
    }

    private var cardHeight: CGFloat {
        cardWidth * 1.25
    }

    var body: some View {
        BabciaGlassGroup(spacing: 22) {
            ZStack {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    let position = index - currentIndex
                    if abs(position) <= 2 {
                        Button {
                            if position == 0 {
                                onSelect(item)
                            }
                        } label: {
                            GalleryStackCard(item: item)
                        }
                        .buttonStyle(BabciaGlassCardButtonStyle())
                        .babciaInteractiveGlassEffect(.clear)
                        .babciaGlassEffectID(item.id, in: galleryNamespace)
                        .frame(width: cardWidth, height: cardHeight)
                        .scaleEffect(position == 0 ? 1.0 : 0.94)
                        .offset(
                            x: CGFloat(position) * 22 + dragOffset * 0.4,
                            y: CGFloat(abs(position)) * 12
                        )
                        .zIndex(Double(10 - abs(position)))
                        .allowsHitTesting(position == 0)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: cardHeight + BabciaSpacing.md)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        if value.translation.width < -threshold {
                            currentIndex = min(currentIndex + 1, items.count - 1)
                        } else if value.translation.width > threshold {
                            currentIndex = max(currentIndex - 1, 0)
                        }
                    }
            )
            .animation(BabciaAnimation.springSubtle, value: currentIndex)
        }
    }
}

struct GalleryStackCard: View {
    let item: GalleryItem

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: item.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    Color(.secondarySystemBackground)
                }
            }
            .clipped()
            .cornerRadius(BabciaCorner.cardImage)

            VStack(alignment: .leading, spacing: BabciaSpacing.xxs) {
                Text(item.title)
                    .font(.babcia(.headingSm))
                    .foregroundStyle(.primary)
                Text(item.subtitle)
                    .font(.babcia(.caption))
                    .foregroundStyle(.secondary)
            }
            .padding(BabciaSpacing.sm)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: BabciaCorner.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: BabciaCorner.card, style: .continuous)
                    .stroke(Color.primary.opacity(0.10), lineWidth: 0.5)
            )
            .padding(BabciaSpacing.sm)
        }
    }
}

struct GalleryGridView: View {
    let title: String
    let items: [GalleryItem]
    let character: BabciaCharacter
    let onSelect: (GalleryItem) -> Void
    @Namespace private var gridNamespace

    private let columns = [
        GridItem(.flexible(), spacing: BabciaSpacing.cardGap),
        GridItem(.flexible(), spacing: BabciaSpacing.cardGap)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                BabciaBackground(style: .gradient(character, .primary))

                ScrollView {
                    BabciaGlassGroup(spacing: 40) {
                        LazyVGrid(columns: columns, spacing: BabciaSpacing.cardGap) {
                            ForEach(items) { item in
                                Button {
                                    onSelect(item)
                                } label: {
                                    GalleryTile(item: item)
                                }
                                .buttonStyle(BabciaCardButtonStyle())
                                .babciaInteractiveGlassEffect(.clear)
                                .babciaGlassEffectID(item.id, in: gridNamespace)
                            }
                        }
                    }
                    .padding(BabciaSpacing.screenHorizontal)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct GalleryTile: View {
    let item: GalleryItem

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: item.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    Color(.secondarySystemBackground)
                }
            }
            .frame(height: BabciaSize.cardImageSm)
            .clipped()
            .cornerRadius(BabciaCorner.cardImage)

            VStack(alignment: .leading, spacing: BabciaSpacing.xxs) {
                Text(item.title)
                    .font(.babcia(.caption))
                    .foregroundStyle(.primary)
                Text(item.subtitle)
                    .font(.babcia(.caption))
                    .foregroundStyle(.secondary)
            }
            .padding(BabciaSpacing.xs)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: BabciaCorner.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: BabciaCorner.card, style: .continuous)
                    .stroke(Color.primary.opacity(0.10), lineWidth: 0.5)
            )
            .padding(BabciaSpacing.xs)
        }
    }
}

struct GalleryDetailView: View {
    let item: GalleryItem

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
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
                .padding(BabciaSpacing.lg)

                VStack(spacing: BabciaSpacing.xxs) {
                    Text(item.title)
                        .font(.babcia(.headingSm))
                        .foregroundColor(.white)
                    Text(item.subtitle)
                        .font(.babcia(.caption))
                        .foregroundColor(.white.opacity(BabciaOpacity.strong))
                }
                .padding(.bottom, BabciaSpacing.lg)
            }
        }
    }
}
