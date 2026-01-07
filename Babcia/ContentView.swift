//
//  ContentView.swift
//  Babcia
//
//  Created by Prank on 17/9/25.
//

import SwiftUI
import Presentation
import Common
import Core
import UIKit

struct ContentView: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    var body: some View {
        Group {
            if appViewModel.hasCompletedSetup {
                HomeView()
            } else {
                SetupView()
            }
        }
        .overlay {
            if appViewModel.isLoading {
                LoadingOverlay()
            }
        }
        .alert(item: $appViewModel.alertItem) { alertItem in
            Alert(
                title: Text(alertItem.title),
                message: Text(alertItem.message),
                dismissButton: .default(Text(alertItem.dismissButton))
            )
        }
        .task {
            appViewModel.load()
        }
        .preferredColorScheme(preferredColorScheme)
        .font(.babciaBody)
    }

    private var preferredColorScheme: ColorScheme? {
        switch appViewModel.settings.theme {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

// MARK: - Loading Overlay
struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)

                Text("Loading...")
                    .font(.babciaHeadline)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(Color.black.opacity(0.7))
            .cornerRadius(16)
        }
    }
}

// MARK: - Setup View
enum SetupStep: Int, CaseIterable {
    case welcome
    case character
    case apiKey
}

struct SetupView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var step: SetupStep = .welcome
    @State private var selectedCharacter: BabciaCharacter = .classic
    @State private var geminiKey = ""
    @State private var isValidating = false
    @State private var errorMessage: String?
    @State private var didPrefill = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CharacterBackground(character: selectedCharacter)

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.65),
                        Color.black.opacity(0.2),
                        Color.black.opacity(0.7)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Spacer(minLength: 80)

                        SetupProgressDots(step: step)

                        switch step {
                        case .welcome:
                            setupCard {
                                VStack(spacing: 16) {
                                    Text("Welcome home")
                                        .font(.babciaTitle)
                                        .foregroundColor(.white)

                                    Text("Babcia keeps each room warm, tidy, and a little bit enchanted.")
                                        .font(.babciaBody)
                                        .foregroundColor(.white.opacity(0.85))
                                        .multilineTextAlignment(.center)

                                    PrimaryButton(title: "Meet the Babcias") {
                                        step = .character
                                    }

                                    Button("Skip intro") {
                                        step = .apiKey
                                    }
                                    .font(.babciaCaption)
                                    .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        case .character:
                            setupCard {
                                VStack(spacing: 16) {
                                    Text("Choose your Babcia")
                                        .font(.babciaTitle2)
                                        .foregroundColor(.white)

                                    Text("Pick a character to guide your rooms. You can change this later.")
                                        .font(.babciaBody)
                                        .foregroundColor(.white.opacity(0.85))
                                        .multilineTextAlignment(.center)

                                    CharacterPicker(selectedCharacter: $selectedCharacter)

                                    PrimaryButton(title: "Continue") {
                                        step = .apiKey
                                    }

                                    Button("Back") {
                                        step = .welcome
                                    }
                                    .font(.babciaCaption)
                                    .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        case .apiKey:
                            setupCard {
                                VStack(spacing: 16) {
                                    Text("Connect Gemini")
                                        .font(.babciaTitle2)
                                        .foregroundColor(.white)

                                    Text("Enter your Gemini API key to unlock scans and tasks.")
                                        .font(.babciaBody)
                                        .foregroundColor(.white.opacity(0.85))
                                        .multilineTextAlignment(.center)

                                    SecureField("Gemini API Key", text: $geminiKey)
                                        .font(.babciaBody)
                                        .padding()
                                        .background(Color.white.opacity(0.15))
                                        .cornerRadius(12)
                                        .foregroundColor(.white)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()

                                    if let errorMessage {
                                        Text(errorMessage)
                                            .font(.babciaCaption)
                                            .foregroundColor(.red)
                                    }

                                    PrimaryButton(
                                        title: isValidating ? "Testing..." : "Test & Continue",
                                        isLoading: isValidating
                                    ) {
                                        validateAndContinue()
                                    }
                                    .disabled(geminiKey.isEmpty || isValidating)
                                    .opacity(geminiKey.isEmpty ? 0.6 : 1.0)

                                    Button("Back") {
                                        step = .character
                                    }
                                    .font(.babciaCaption)
                                    .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }

                        Spacer(minLength: 80)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            if !didPrefill {
                geminiKey = appViewModel.settings.geminiAPIKey
                selectedCharacter = appViewModel.settings.selectedCharacter
                didPrefill = true
            }
        }
    }

    @ViewBuilder
    private func setupCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(24)
            .background(Color.black.opacity(0.45))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 20)
    }

    private func validateAndContinue() {
        guard !geminiKey.isEmpty else { return }
        isValidating = true
        errorMessage = nil

        Task {
            let isValid = await appViewModel.validateGeminiKey(geminiKey)
            await MainActor.run {
                if isValid {
                    appViewModel.completeSetup(geminiKey: geminiKey, selectedCharacter: selectedCharacter)
                } else {
                    errorMessage = "Invalid API key"
                }
                isValidating = false
            }
        }
    }
}

struct SetupProgressDots: View {
    let step: SetupStep

    var body: some View {
        HStack(spacing: 8) {
            ForEach(SetupStep.allCases, id: \.rawValue) { item in
                Circle()
                    .fill(item == step ? Color.white : Color.white.opacity(0.4))
                    .frame(width: item == step ? 10 : 8, height: item == step ? 10 : 8)
            }
        }
    }
}

struct CharacterPicker: View {
    @Binding var selectedCharacter: BabciaCharacter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(BabciaCharacter.allCases) { character in
                    CharacterCard(character: character, isSelected: character == selectedCharacter)
                        .onTapGesture {
                            selectedCharacter = character
                        }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct CharacterCard: View {
    let character: BabciaCharacter
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 10) {
            Image(character.portraitAssetName)
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 160)
                .clipped()
                .cornerRadius(12)

            VStack(spacing: 4) {
                Text(character.displayName)
                    .font(.babciaHeadline)
                    .foregroundColor(.white)

                Text(character.tagline)
                    .font(.babciaCaption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(12)
        .background(Color.white.opacity(isSelected ? 0.2 : 0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(isSelected ? 0.6 : 0.2), lineWidth: 1)
        )
    }
}

// MARK: - Home View
enum MainTab: String, CaseIterable, Identifiable {
    case home
    case spaces
    case capture
    case gallery
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .spaces: return "Spaces"
        case .capture: return "Capture"
        case .gallery: return "Gallery"
        case .settings: return "Settings"
        }
    }

    var icon: BabciaIcon {
        switch self {
        case .home: return .home
        case .spaces: return .spaces
        case .capture: return .capture
        case .gallery: return .gallery
        case .settings: return .settings
        }
    }
}

struct HomeView: View {
    @State private var selectedTab: MainTab = .home

    var body: some View {
        ZStack {
            switch selectedTab {
            case .home:
                HomeTab()
            case .spaces:
                RoomsTab()
            case .capture:
                CaptureTab()
            case .gallery:
                GalleryTab()
            case .settings:
                SettingsTab()
            }
        }
        .safeAreaInset(edge: .bottom) {
            BabciaTabBar(selectedTab: $selectedTab)
        }
    }
}

struct BabciaTabBar: View {
    @Binding var selectedTab: MainTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(MainTab.allCases) { tab in
                BabciaTabItem(tab: tab, isSelected: tab == selectedTab)
                    .onTapGesture {
                        selectedTab = tab
                    }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .babciaCardSurface(style: .strong, cornerRadius: BabciaCorner.tabBar, shadow: true)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

struct BabciaTabItem: View {
    let tab: MainTab
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: tab.icon.systemName)
                .font(.system(size: 16, weight: .semibold))
            Text(tab.title)
                .font(.babciaCaption)
        }
        .foregroundColor(isSelected ? .primary : .secondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.white.opacity(0.2) : Color.clear)
        )
    }
}

// MARK: - Home Tab
struct HomeTab: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    private var verificationRooms: [Room] {
        appViewModel.rooms
            .filter { $0.pendingTaskCount > 0 }
            .sorted { $0.pendingTaskCount > $1.pendingTaskCount }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
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
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .padding(.bottom, BabciaSpacing.tabBarInset)
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
        HStack(spacing: 16) {
            Image(character.headshotAssetName)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color(hex: character.accentHex), lineWidth: 3)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(displayName)
                    .font(.babciaTitle2)

                Text(character.displayName)
                    .font(.babciaCallout)
                    .foregroundColor(.secondary)

                Text("Level \(level)")
                    .font(.babciaCaption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: character.accentHex).opacity(0.15))
                    .cornerRadius(12)
            }

            Spacer()
        }
        .padding(BabciaSpacing.cardPadding)
        .babciaCardSurface()
    }
}

struct StatsGrid: View {
    let totalXP: Int
    let level: Int
    let currentStreak: Int
    let bestStreak: Int

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 15) {
            StatCard(
                title: "Total XP",
                value: "\(totalXP)",
                icon: BabciaIcon.xp,
                color: .purple
            )

            StatCard(
                title: "Level",
                value: "\(level)",
                icon: BabciaIcon.level,
                color: .yellow
            )

            StatCard(
                title: "Current Streak",
                value: "\(currentStreak)d",
                icon: BabciaIcon.streak,
                color: .orange
            )

            StatCard(
                title: "Best Streak",
                value: "\(bestStreak)d",
                icon: BabciaIcon.streak,
                color: .blue
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: BabciaIcon
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon.systemName)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.babciaHeadline)

                Text(title)
                    .font(.babciaCaption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(BabciaSpacing.cardPadding)
        .babciaCardSurface(style: .subtle)
    }
}

struct RecentActivityCard: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    private var entries: [HistoryEntry] {
        HistoryEntry.build(from: appViewModel.rooms)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.babciaHeadline)
                Spacer()
                NavigationLink {
                    HistoryView(rooms: appViewModel.rooms)
                } label: {
                    Text("View all")
                        .font(.babciaCaption)
                        .foregroundColor(.secondary)
                }
            }

            if entries.isEmpty {
                Text("No history yet. Scan a room to get started.")
                    .font(.babciaCaption)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(entries.prefix(3)) { entry in
                        NavigationLink(value: entry.roomID) {
                            HistoryRow(entry: entry, useSurface: false)
                        }
                    }
                }
            }
        }
        .padding(BabciaSpacing.cardPadding)
        .babciaCardSurface()
    }
}

struct VerificationQueueCard: View {
    let rooms: [Room]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Needs Verification")
                .font(.babciaHeadline)

            if rooms.isEmpty {
                Text("All rooms are verified. Nice work.")
                    .font(.babciaCaption)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(rooms.prefix(4)) { room in
                        NavigationLink(value: room.id) {
                            VerificationQueueRow(room: room)
                        }
                    }
                }
            }
        }
        .padding(BabciaSpacing.cardPadding)
        .babciaCardSurface()
    }
}

struct VerificationQueueRow: View {
    let room: Room

    var body: some View {
        HStack(spacing: 12) {
            Image(room.character.headshotAssetName)
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(room.name)
                    .font(.babciaBody)
                Text("\(room.pendingTaskCount) tasks pending")
                    .font(.babciaCaption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("Verify")
                .font(.babciaCaption)
                .foregroundColor(.secondary)
        }
    }
}

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

    private var entries: [HistoryEntry] {
        HistoryEntry.build(from: rooms)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if entries.isEmpty {
                    Text("No history yet.")
                        .font(.babciaCaption)
                        .foregroundColor(.secondary)
                        .padding(.top, 12)
                } else {
                    ForEach(entries) { entry in
                        NavigationLink(value: entry.roomID) {
                            HistoryRow(entry: entry)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, BabciaSpacing.tabBarInset)
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
        let content = HStack(spacing: 12) {
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
                                .padding(6)
                        }
                    }
                } else {
                    Image(entry.fallbackAssetName)
                        .resizable()
                        .scaledToFit()
                        .padding(6)
                }
            }
            .frame(width: 50, height: 60)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(BabciaCorner.image)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.babciaBody)
                Text(entry.subtitle)
                    .font(.babciaCaption)
                    .foregroundColor(.secondary)
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.babciaCaption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }

        if useSurface {
            content
                .padding(BabciaSpacing.cardPadding)
                .babciaCardSurface()
        } else {
            content
                .padding(.vertical, 6)
        }
    }
}

struct AppModeCard: View {
    let character: BabciaCharacter

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("App Mode")
                .font(.babciaHeadline)

            HStack(spacing: 12) {
                Image(character.headshotAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color(hex: character.accentHex), lineWidth: 2)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(character.displayName) • \(character.verificationModeName)")
                        .font(.babciaBody)
                    Text(character.verificationModeDescription)
                        .font(.babciaCaption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(BabciaSpacing.cardPadding)
        .babciaCardSurface()
    }
}

struct RecentTasksCard: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    private var taskItems: [(Room, CleaningTask)] {
        let items = appViewModel.rooms.flatMap { room in
            room.tasks.filter { $0.verificationState != .verified }.map { (room, $0) }
        }
        return Array(items.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today’s Tasks")
                .font(.babciaHeadline)

            if taskItems.isEmpty {
                Text("Scan a room to get your first task list.")
                    .font(.babciaCaption)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(taskItems, id: \.1.id) { room, task in
                        NavigationLink(value: room.id) {
                            RecentTaskRow(room: room, task: task)
                        }
                    }
                }
            }
        }
        .padding(BabciaSpacing.cardPadding)
        .babciaCardSurface()
    }
}

struct RecentTaskRow: View {
    let room: Room
    let task: CleaningTask

    var body: some View {
        HStack(spacing: 12) {
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
                                .padding(6)
                        }
                    }
                } else {
                    Image(room.character.headshotAssetName)
                        .resizable()
                        .scaledToFit()
                        .padding(6)
                }
            }
            .frame(width: 40, height: 40)
            .background(Color(.secondarySystemBackground))
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(room.name)
                    .font(.babciaCaption)
                    .foregroundColor(.secondary)
                Text(task.title)
                    .font(.babciaBody)
            }

            Spacer()

            Text("+\(task.xpReward)")
                .font(.babciaCaption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Rooms Tab
struct RoomsTab: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var showingCreateRoom = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ProgressCard(totalXP: appViewModel.totalXP, level: appViewModel.level)

                    DreamGallerySection(rooms: appViewModel.rooms)

                    RoomsListCard(rooms: appViewModel.rooms)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .padding(.bottom, BabciaSpacing.tabBarInset)
            }
            .navigationTitle("Spaces")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateRoom = true
                    } label: {
                        Image(systemName: BabciaIcon.add.systemName)
                    }
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

// MARK: - Capture Tab
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
            ScrollView {
                VStack(spacing: 20) {
                    if let room = selectedRoom {
                        RoomPreviewCard(room: room)

                        Button {
                            showingScanOptions = true
                        } label: {
                            HStack {
                                Image(systemName: BabciaIcon.capture.systemName)
                                Text("Scan Now")
                                    .font(.babciaHeadline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .tint(.black)
                        .babciaGlassButton()
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
                .padding()
                .padding(.bottom, BabciaSpacing.tabBarInset)
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
        VStack(alignment: .leading, spacing: 12) {
            Text(room.name)
                .font(.babciaHeadline)

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
                                .padding(24)
                        }
                    }
                } else {
                    Image(room.character.headshotAssetName)
                        .resizable()
                        .scaledToFit()
                        .padding(24)
                }
            }
            .frame(height: 180)
            .background(Color(.secondarySystemBackground))
            .clipped()
            .cornerRadius(BabciaCorner.image)
            .overlay(
                RoundedRectangle(cornerRadius: BabciaCorner.image)
                    .stroke(accent.opacity(0.4), lineWidth: 1)
            )

            Text("Character: \(room.character.displayName)")
                .font(.babciaCaption)
                .foregroundColor(.secondary)
        }
        .padding(BabciaSpacing.cardPadding)
        .babciaCardSurface()
    }
}

struct RoomPickerCard: View {
    let rooms: [Room]
    @Binding var selectedRoomID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Room")
                .font(.babciaHeadline)

            Picker("Room", selection: $selectedRoomID) {
                ForEach(rooms) { room in
                    Text(room.name).tag(Optional(room.id))
                }
            }
            .pickerStyle(.menu)
        }
        .padding(BabciaSpacing.cardPadding)
        .babciaCardSurface()
    }
}

struct EmptyStateCard: View {
    let title: String
    let message: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.babciaHeadline)
            Text(message)
                .font(.babciaCaption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            PrimaryButton(title: "Create Room") {
                action()
            }
            .frame(maxWidth: 200)
        }
        .padding(BabciaSpacing.cardPadding)
        .babciaCardSurface()
    }
}

// MARK: - Gallery Tab
struct GalleryTab: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var selectedItem: GalleryItem?
    @State private var selectedSection: GallerySectionType?

    private var dreamItems: [GalleryItem] {
        var items: [GalleryItem] = []

        for room in appViewModel.rooms {
            if let url = room.dreamVisionURL {
                items.append(GalleryItem(
                    imageURL: url,
                    title: room.name,
                    subtitle: "Dream",
                    date: room.lastScanDate ?? Date.distantPast
                ))
            }
            for history in room.scanHistory {
                if let url = history.dreamVisionURL {
                    items.append(GalleryItem(
                        imageURL: url,
                        title: room.name,
                        subtitle: "Dream",
                        date: history.date
                    ))
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
                    items.append(GalleryItem(
                        imageURL: url,
                        title: room.name,
                        subtitle: capture.source.displayName,
                        date: capture.date
                    ))
                }
            }
        }

        return items.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
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
                .padding()
                .padding(.bottom, BabciaSpacing.tabBarInset)
            }
            .navigationTitle("Gallery")
            .sheet(item: $selectedItem) { item in
                GalleryDetailView(item: item)
            }
            .sheet(item: $selectedSection) { section in
                GalleryGridView(
                    title: section.title,
                    items: section == .dreams ? dreamItems : captureItems,
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.babciaHeadline)
                Spacer()
                Button("View all") {
                    onViewAll()
                }
                .font(.babciaCaption)
                .foregroundColor(.secondary)
            }

            if items.isEmpty {
                Text(emptyMessage)
                    .font(.babciaCaption)
                    .foregroundColor(.secondary)
            } else {
                GalleryStackCarousel(items: items, onSelect: onSelect)
            }
        }
        .padding(BabciaSpacing.cardPadding)
        .babciaCardSurface()
    }
}

struct GalleryStackCarousel: View {
    let items: [GalleryItem]
    let onSelect: (GalleryItem) -> Void
    @State private var currentIndex = 0
    @GestureState private var dragOffset: CGFloat = 0

    private var cardWidth: CGFloat {
        min(UIScreen.main.bounds.width * 0.72, 280)
    }

    private var cardHeight: CGFloat {
        cardWidth * 1.25
    }

    var body: some View {
        ZStack {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let position = index - currentIndex
                if abs(position) <= 2 {
                    GalleryStackCard(item: item)
                        .frame(width: cardWidth, height: cardHeight)
                        .scaleEffect(position == 0 ? 1.0 : 0.94)
                        .offset(
                            x: CGFloat(position) * 22 + dragOffset * 0.4,
                            y: CGFloat(abs(position)) * 12
                        )
                        .zIndex(Double(10 - abs(position)))
                        .allowsHitTesting(position == 0)
                        .onTapGesture {
                            if position == 0 {
                                onSelect(item)
                            }
                        }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: cardHeight + 16)
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
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: currentIndex)
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
            .cornerRadius(BabciaCorner.image)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.babciaHeadline)
                    .foregroundColor(.white)
                Text(item.subtitle)
                    .font(.babciaCaption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(12)
            .background(Color.black.opacity(0.45))
            .cornerRadius(12)
            .padding(12)
        }
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
    }
}

struct GalleryGridView: View {
    let title: String
    let items: [GalleryItem]
    let onSelect: (GalleryItem) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(items) { item in
                        GalleryTile(item: item)
                            .onTapGesture {
                                onSelect(item)
                            }
                    }
                }
            }
            .padding()
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
            .frame(height: 140)
            .clipped()
            .cornerRadius(BabciaCorner.image)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.babciaCaption)
                    .foregroundColor(.white)
                Text(item.subtitle)
                    .font(.babciaCaption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(8)
            .background(Color.black.opacity(0.4))
            .cornerRadius(BabciaCorner.card)
            .padding(8)
        }
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 4)
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
                .padding()

                VStack(spacing: 4) {
                    Text(item.title)
                        .font(.babciaHeadline)
                        .foregroundColor(.white)
                    Text(item.subtitle)
                        .font(.babciaCaption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 20)
            }
        }
    }
}

struct ProgressCard: View {
    let totalXP: Int
    let level: Int

    private var progress: Double {
        let baseXP = max(0, (level - 1) * 100)
        let currentXP = max(0, totalXP - baseXP)
        return min(1.0, Double(currentXP) / 100.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Progress")
                .font(.babciaHeadline)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("XP to Next Level")
                        .font(.babciaCaption)
                    Spacer()
                    Text("\(totalXP) / \(level * 100)")
                        .font(.babciaCaption)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 10)

                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 10)
                    }
                }
                .frame(height: 10)
            }
        }
        .padding(BabciaSpacing.cardPadding)
        .babciaCardSurface()
    }
}

struct DreamGallerySection: View {
    let rooms: [Room]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dream Gallery")
                .font(.babciaHeadline)

            if rooms.isEmpty {
                Text("No rooms yet. Add one to begin.")
                    .font(.babciaCaption)
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(rooms) { room in
                            DreamThumbnail(room: room)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(BabciaSpacing.cardPadding)
        .babciaCardSurface()
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
                            .padding(12)
                    }
                }
            } else {
                Image(room.character.headshotAssetName)
                    .resizable()
                    .scaledToFit()
                    .padding(12)
            }
        }
        .frame(width: 100, height: 140)
        .background(Color(.secondarySystemBackground))
        .clipped()
        .cornerRadius(BabciaCorner.image)
        .overlay(
            RoundedRectangle(cornerRadius: BabciaCorner.image)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

struct RoomsListCard: View {
    let rooms: [Room]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rooms")
                .font(.babciaHeadline)

            if rooms.isEmpty {
                Text("No rooms yet. Tap + to add one.")
                    .font(.babciaCaption)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(rooms) { room in
                        NavigationLink(value: room.id) {
                            RoomRow(room: room)
                        }
                    }
                }
            }
        }
        .padding(BabciaSpacing.cardPadding)
        .babciaCardSurface()
    }
}

struct RoomRow: View {
    let room: Room

    var body: some View {
        let accent = Color(hex: room.character.accentHex)
        HStack(spacing: 12) {
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
                                .padding(6)
                        }
                    }
                } else {
                    Image(room.character.headshotAssetName)
                        .resizable()
                        .scaledToFit()
                        .padding(6)
                }
            }
            .frame(width: 50, height: 60)
            .background(Color(.secondarySystemBackground))
            .clipped()
            .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(room.name)
                    .font(.babciaHeadline)

                Text("\(room.pendingTaskCount) pending")
                    .font(.babciaCaption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(room.streak)d")
                .font(.babciaCaption)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(
            LinearGradient(
                colors: [accent.opacity(0.18), Color(.secondarySystemBackground)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(BabciaCorner.card)
        .overlay(
            RoundedRectangle(cornerRadius: BabciaCorner.card)
                .stroke(accent.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Room Detail
enum RoomImageAction {
    case scan
    case verify
}

struct ManualToggleIntent: Identifiable {
    let id = UUID()
    let taskID: UUID
    let markComplete: Bool
}

struct RoomDetailView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    let roomID: UUID

    @State private var showingCameraMenu = false
    @State private var showingSourceMenu = false
    @State private var showingManualOverrideConfirm = false
    @State private var showingImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var imagePickerAction: RoomImageAction = .scan
    @State private var pendingManualToggle: ManualToggleIntent?
    @State private var headerBlendColor: Color = Color(.systemGroupedBackground)

    private var room: Room? {
        appViewModel.rooms.first { $0.id == roomID }
    }

    var body: some View {
        Group {
            if let room {
                ScrollView {
                    VStack(spacing: 16) {
                        RoomHeaderFullBleed(room: room, blendColor: $headerBlendColor)
                            .padding(.horizontal, -16)
                            .ignoresSafeArea(edges: .top)

                        VStack(alignment: .leading, spacing: 16) {
                            RoomModeSummary(room: room, modeCharacter: appViewModel.settings.selectedCharacter)

                            if let advice = room.babciaAdvice, !advice.isEmpty {
                                AdviceCard(message: advice)
                            }

                            if room.tasks.isEmpty {
                                EmptyTasksCard()
                            } else {
                                VerificationSummaryCard(room: room)

                                TaskList(room: room) { task, markComplete in
                                    if markComplete {
                                        pendingManualToggle = ManualToggleIntent(taskID: task.id, markComplete: true)
                                    } else {
                                        appViewModel.setManualTask(roomID: room.id, taskID: task.id, isCompleted: false)
                                    }
                                }

                                if let lastVerified = room.lastVerifiedAt {
                                    Text("Last verified: \(lastVerified.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.babciaCaption)
                                        .foregroundColor(.secondary)
                                }

                            if room.manualOverrideAvailable {
                                ManualOverrideCard(
                                    isTrusted: appViewModel.settings.selectedCharacter == .wellnessX,
                                    onOverride: { showingManualOverrideConfirm = true }
                                )
                            }
                            }

                            AutoScanCard(room: room)

                            RoomStatsBar(room: room)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, BabciaSpacing.tabBarInset)
                }
                .background(
                    LinearGradient(
                        colors: [headerBlendColor, Color(.systemGroupedBackground)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingCameraMenu = true
                        } label: {
                            Image(systemName: BabciaIcon.camera.systemName)
                        }
                    }
                }
                .confirmationDialog("Room Camera", isPresented: $showingCameraMenu) {
                    Button("Verify Room") {
                        imagePickerAction = .verify
                        showingSourceMenu = true
                    }
                    Button("Change Baseline") {
                        imagePickerAction = .scan
                        showingSourceMenu = true
                    }
                }
                .confirmationDialog("Select Source", isPresented: $showingSourceMenu) {
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
                    if room.imageSource == .homeAssistant {
                        Button("Home Assistant Snapshot") {
                            if imagePickerAction == .scan {
                                appViewModel.scanHomeAssistant(roomID: room.id)
                            } else {
                                appViewModel.verifyHomeAssistant(roomID: room.id)
                            }
                        }
                    }
                }
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker(sourceType: imagePickerSource) { image in
                        let source: CaptureSource = imagePickerSource == .camera ? .camera : .manual
                        switch imagePickerAction {
                        case .scan:
                            appViewModel.scanRoom(roomID: room.id, image: image, captureSource: source)
                        case .verify:
                            appViewModel.verifyRoom(roomID: room.id, image: image, captureSource: source)
                        }
                    }
                }
                .alert(item: $pendingManualToggle) { intent in
                    let messageText = appViewModel.settings.selectedCharacter == .wellnessX
                        ? "Trusted mode grants XP immediately for manual checks."
                        : "Manual checks do not grant XP until Babcia verifies."
                    return Alert(
                        title: Text("Mark as done?"),
                        message: Text(messageText),
                        primaryButton: .default(Text("Mark")) {
                            appViewModel.setManualTask(roomID: room.id, taskID: intent.taskID, isCompleted: intent.markComplete)
                        },
                        secondaryButton: .cancel()
                    )
                }
                .alert("Manual override", isPresented: $showingManualOverrideConfirm) {
                    Button("Cancel", role: .cancel) {}
                    Button("Override", role: .destructive) {
                        appViewModel.manualOverride(roomID: room.id)
                    }
                } message: {
                    let messageText = appViewModel.settings.selectedCharacter == .wellnessX
                        ? "Trusted mode grants XP immediately for manual completions."
                        : "Babcia prefers a real scan. Manual override logs self-declared completion and grants no XP."
                    Text(messageText)
                }
            } else {
                Text("Room not found")
                    .font(.babciaHeadline)
            }
        }
    }
}

struct RoomHeaderFullBleed: View {
    let room: Room
    @Binding var blendColor: Color
    @Environment(\.colorScheme) private var colorScheme
    @State private var headerImage: UIImage?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let headerImage {
                Image(uiImage: headerImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(room.character.portraitAssetName)
                    .resizable()
                    .scaledToFill()
            }

            LinearGradient(
                colors: [Color.clear, blendColor],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(room.name)
                    .font(.babciaTitle)
                    .foregroundColor(.white)
                Text(room.character.displayName)
                    .font(.babciaCaption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(BabciaSpacing.lg)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .clipped()
        .task(id: room.dreamVisionURL) {
            await loadHeaderImage()
        }
    }

    private func loadHeaderImage() async {
        if let url = room.dreamVisionURL {
            do {
                let data: Data
                if url.isFileURL {
                    data = try Data(contentsOf: url)
                } else {
                    let (remoteData, _) = try await URLSession.shared.data(from: url)
                    data = remoteData
                }
                if let image = UIImage(data: data) {
                    headerImage = image
                    updateBlendColor(from: image)
                    return
                }
            } catch {
                // fallback below
            }
        }

        if let image = UIImage(named: room.character.portraitAssetName) {
            headerImage = image
            updateBlendColor(from: image)
        } else {
            blendColor = Color(hex: room.character.accentHex).opacity(0.2)
        }
    }

    private func updateBlendColor(from image: UIImage) {
        guard let sampled = image.sampledBottomColor() else {
            blendColor = Color(hex: room.character.accentHex).opacity(0.2)
            return
        }
        blendColor = adjustedBlendColor(from: sampled)
    }

    private func adjustedBlendColor(from color: UIColor) -> Color {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        if color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            let adjustedBrightness: CGFloat = colorScheme == .dark
                ? max(0.12, brightness * 0.6)
                : min(0.95, brightness * 1.1)
            let adjusted = UIColor(
                hue: hue,
                saturation: max(0.2, saturation * 0.9),
                brightness: adjustedBrightness,
                alpha: 1
            )
            return Color(adjusted)
        }

        return Color(color)
    }
}

struct RoomModeSummary: View {
    let room: Room
    let modeCharacter: BabciaCharacter

    var body: some View {
        let accent = Color(hex: room.character.accentHex)
        HStack(spacing: 12) {
            Image(room.character.headshotAssetName)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(accent, lineWidth: 2)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Mode: \(modeCharacter.verificationModeName)")
                    .font(.babciaHeadline)
                Text(modeCharacter.verificationModeDescription)
                    .font(.babciaCaption)
                    .foregroundColor(.secondary)
                Text("Room Babcia: \(room.character.displayName)")
                    .font(.babciaCaption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(BabciaSpacing.cardPadding)
        .babciaCardSurface()
    }
}

struct VerificationSummaryCard: View {
    let room: Room

    private var verifiedCount: Int {
        room.tasks.filter { $0.verificationState == .verified }.count
    }

    private var manualCount: Int {
        room.tasks.filter { $0.verificationState == .manual }.count
    }

    private var pendingCount: Int {
        room.pendingTaskCount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Verification")
                .font(.babciaHeadline)

            Text("Use the top camera button to verify or update the room baseline.")
                .font(.babciaCaption)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                VerificationPill(title: "Verified", value: "\(verifiedCount)")
                VerificationPill(title: "Manual", value: "\(manualCount)")
                VerificationPill(title: "Pending", value: "\(pendingCount)")
            }
        }
        .padding(BabciaSpacing.cardPadding)
        .babciaCardSurface()
    }
}

struct VerificationPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.babciaHeadline)
            Text(title)
                .font(.babciaCaption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .babciaCardSurface(style: .subtle, cornerRadius: 12, shadow: false)
    }
}

struct AdviceCard: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.babciaBody)
            .foregroundColor(.primary)
            .padding(BabciaSpacing.cardPadding)
            .babciaCardSurface()
    }
}

struct EmptyTasksCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No tasks yet")
                .font(.babciaHeadline)

            Text("Use the top camera button to scan this room and generate tasks.")
                .font(.babciaCaption)
                .foregroundColor(.secondary)
        }
        .padding(BabciaSpacing.cardPadding)
        .babciaCardSurface()
    }
}

struct TaskList: View {
    let room: Room
    let onToggle: (CleaningTask, Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tasks")
                .font(.babciaHeadline)

            ForEach(room.tasks) { task in
                TaskRow(
                    task: task,
                    onToggle: { onToggle(task, $0) }
                )
            }
        }
        .padding(BabciaSpacing.cardPadding)
        .babciaCardSurface()
    }
}

struct TaskRow: View {
    let task: CleaningTask
    let onToggle: (Bool) -> Void

    private var isLocked: Bool {
        task.verificationState == .verified
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                guard !isLocked else { return }
                onToggle(!task.isCompleted)
            }) {
                Image(systemName: task.isCompleted ? BabciaIcon.taskComplete.systemName : BabciaIcon.taskPending.systemName)
                    .foregroundColor(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(isLocked)

            Text(task.title)
                .font(.babciaBody)
                .foregroundColor(.primary)
                .strikethrough(task.isCompleted, color: .secondary)

            Spacer()

            let override = (task.verificationNote ?? "").localizedCaseInsensitiveContains("trusted") ? "Trusted" : nil
            TaskStatusChip(state: task.resolvedVerificationState, labelOverride: override)

            Text("+\(task.xpReward)")
                .font(.babciaCaption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }
}

struct TaskStatusChip: View {
    let state: TaskVerificationState
    let labelOverride: String?

    init(state: TaskVerificationState, labelOverride: String? = nil) {
        self.state = state
        self.labelOverride = labelOverride
    }

    private var label: String {
        if let labelOverride { return labelOverride }
        switch state {
        case .verified:
            return "Verified"
        case .manual:
            return "Manual"
        case .pending:
            return "Pending"
        }
    }

    private var tint: Color {
        switch state {
        case .verified:
            return .green
        case .manual:
            return .orange
        case .pending:
            return .secondary
        }
    }

    var body: some View {
        Text(label)
            .font(.babciaCaption)
            .foregroundColor(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .babciaCardSurface(style: .subtle, cornerRadius: 8, shadow: false)
    }
}

struct ManualOverrideCard: View {
    let isTrusted: Bool
    let onOverride: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Babcia is unsure")
                .font(.babciaHeadline)

            Text(isTrusted
                 ? "Trusted mode allows manual completion with XP."
                 : "Try a clearer scan using the top camera button, or manually override if you must. This is logged as self-declared.")
                .font(.babciaCaption)
                .foregroundColor(.secondary)

            Button(action: onOverride) {
                Text("Manual override")
                    .font(.babciaCaption)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
            .babciaGlassButton()
        }
        .padding(BabciaSpacing.cardPadding)
        .babciaCardSurface()
    }
}

struct AutoScanCard: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    let room: Room

    private var schedule: ScanSchedule {
        room.scanSchedule ?? ScanSchedule(cadence: .daily, enabled: false)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Auto Scan")
                .font(.babciaHeadline)

            Toggle("Enable auto scan", isOn: Binding(
                get: { schedule.enabled },
                set: { appViewModel.updateRoomSchedule(roomID: room.id, enabled: $0, cadence: schedule.cadence) }
            ))
            .toggleStyle(SwitchToggleStyle(tint: .green))

            Picker("Cadence", selection: Binding(
                get: { schedule.cadence },
                set: { appViewModel.updateRoomSchedule(roomID: room.id, enabled: schedule.enabled, cadence: $0) }
            )) {
                ForEach(ScanCadence.allCases, id: \.self) { cadence in
                    Text(cadence.displayName).tag(cadence)
                }
            }
            .pickerStyle(.segmented)

            if let nextRun = schedule.nextRun {
                Text("Next scan: \(nextRun.formatted(date: .abbreviated, time: .shortened))")
                    .font(.babciaCaption)
                    .foregroundColor(.secondary)
            } else {
                Text("Next scan will be scheduled after enabling.")
                    .font(.babciaCaption)
                    .foregroundColor(.secondary)
            }

            Text(scheduleNote)
                .font(.babciaCaption)
                .foregroundColor(.secondary)
        }
        .padding(BabciaSpacing.cardPadding)
        .babciaCardSurface()
    }

    private var scheduleNote: String {
        if room.imageSource == .homeAssistant {
            return "Home Assistant rooms can auto-scan in the background."
        }
        return "Manual rooms receive reminders to scan."
    }
}

struct RoomStatsBar: View {
    let room: Room

    var body: some View {
        HStack(spacing: 16) {
            StatPill(title: "XP", value: "\(room.totalXP)")
            StatPill(title: "Streak", value: "\(room.streak)d")
            StatPill(title: "Done", value: "\(room.completedTaskCount)")
        }
    }
}

struct StatPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.babciaHeadline)
                .foregroundColor(.primary)
            Text(title)
                .font(.babciaCaption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .babciaCardSurface(style: .subtle, cornerRadius: 12, shadow: false)
    }
}

struct RoomBackground: View {
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
                        CharacterBackground(character: room.character)
                    }
                }
            } else {
                CharacterBackground(character: room.character)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Create Room Sheet
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
            Form {
                Section(header: Text("Room")) {
                    TextField("Room name", text: $name)
                        .font(.babciaBody)
                }

                Section(header: Text("Character")) {
                    Picker("Character", selection: $character) {
                        ForEach(BabciaCharacter.allCases) { character in
                            Text(character.displayName).tag(character)
                        }
                    }
                }

                Section(header: Text("Source")) {
                    Picker("Source", selection: $imageSource) {
                        Text("iPhone Camera").tag(RoomImageSource.iphone)
                        Text("Photo Library").tag(RoomImageSource.manual)
                        Text("Home Assistant").tag(RoomImageSource.homeAssistant)
                    }

                    if imageSource == .homeAssistant {
                        if appViewModel.settings.homeAssistantURL.isEmpty || appViewModel.settings.homeAssistantToken.isEmpty {
                            Text("Add your Home Assistant URL and token in Settings.")
                                .font(.babciaCaption)
                                .foregroundColor(.secondary)
                        } else {
                            Picker("Camera", selection: $cameraIdentifier) {
                                ForEach(haCameras) { camera in
                                    Text(camera.name).tag(camera.entityId)
                                }
                            }
                            .font(.babciaBody)

                            Button(isLoadingCameras ? "Loading Cameras..." : "Refresh Cameras") {
                                loadHomeAssistantCameras(force: true)
                            }
                            .disabled(isLoadingCameras)

                            if let cameraError {
                                Text(cameraError)
                                    .font(.babciaCaption)
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
                                        .font(.babciaCaption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(height: 140)
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .clipped()
                        }
                    }
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

// MARK: - Settings Tab
struct SettingsTab: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var showingSettingsDetail = false
    @State private var showingResetAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section("Setup") {
                    Button {
                        showingSettingsDetail = true
                    } label: {
                        SettingsRow(
                            icon: .info,
                            title: "Connections",
                            detail: connectionsStatus
                        )
                    }

                    Button {
                        showingResetAlert = true
                    } label: {
                        SettingsRow(
                            icon: .warning,
                            title: "Reset Setup",
                            detail: nil,
                            tint: .red
                        )
                    }
                }

                Section("Appearance") {
                    Picker("Theme", selection: Binding(
                        get: { appViewModel.settings.theme },
                        set: { appViewModel.updateTheme($0) }
                    )) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }

                    Picker("Babcia Mode", selection: Binding(
                        get: { appViewModel.settings.selectedCharacter },
                        set: { appViewModel.updateSelectedCharacter($0) }
                    )) {
                        ForEach(BabciaCharacter.allCases) { character in
                            Text(character.displayName).tag(character)
                        }
                    }

                    Text("Babcia Mode controls how strict verification feels.")
                        .font(.babciaCaption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingSettingsDetail) {
                SettingsDetailView()
            }
            .alert("Reset Setup", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    appViewModel.resetSetup()
                }
            } message: {
                Text("This will clear API keys and setup status.")
            }
        }
    }

    private var connectionsStatus: String {
        let hasGemini = !appViewModel.settings.geminiAPIKey.isEmpty
        let hasHA = !appViewModel.settings.homeAssistantURL.isEmpty && !appViewModel.settings.homeAssistantToken.isEmpty

        switch (hasGemini, hasHA) {
        case (true, true):
            return "Gemini + Home Assistant"
        case (true, false):
            return "Gemini only"
        case (false, true):
            return "Home Assistant only"
        default:
            return "Not configured"
        }
    }
}

struct SettingsRow: View {
    let icon: BabciaIcon
    let title: String
    let detail: String?
    var tint: Color = .blue

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon.systemName)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(tint)
                .cornerRadius(7)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.babciaBody)

                if let detail {
                    Text(detail)
                        .font(.babciaCaption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
            Image(systemName: BabciaIcon.chevronRight.systemName)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct SettingsDetailView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var geminiKey = ""
    @State private var homeAssistantURL = ""
    @State private var homeAssistantToken = ""
    @State private var defaultCameraEntityId = ""
    @State private var geminiTestResult: String?
    @State private var haTestResult: String?
    @State private var isTestingGemini = false
    @State private var isTestingHA = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Gemini")) {
                    SecureField("Gemini API Key", text: $geminiKey)
                        .font(.babciaBody)

                    Button(isTestingGemini ? "Testing..." : "Test Gemini") {
                        testGemini()
                    }
                    .disabled(isTestingGemini || geminiKey.isEmpty)

                    if let geminiTestResult {
                        Text(geminiTestResult)
                            .font(.babciaCaption)
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Home Assistant")) {
                    TextField("Base URL", text: $homeAssistantURL)
                        .font(.babciaBody)
                        .textInputAutocapitalization(.never)

                    SecureField("Access Token", text: $homeAssistantToken)
                        .font(.babciaBody)
                        .textInputAutocapitalization(.never)

                    TextField("Default Camera Entity ID", text: $defaultCameraEntityId)
                        .font(.babciaBody)
                        .textInputAutocapitalization(.never)

                    Button(isTestingHA ? "Testing..." : "Test Home Assistant") {
                        testHomeAssistant()
                    }
                    .disabled(isTestingHA || homeAssistantURL.isEmpty || homeAssistantToken.isEmpty)

                    if let haTestResult {
                        Text(haTestResult)
                            .font(.babciaCaption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Connections")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                }
            }
            .onAppear {
                geminiKey = appViewModel.settings.geminiAPIKey
                homeAssistantURL = appViewModel.settings.homeAssistantURL
                homeAssistantToken = appViewModel.settings.homeAssistantToken
                defaultCameraEntityId = appViewModel.settings.defaultCameraEntityId
            }
        }
    }

    private func save() {
        appViewModel.updateSettings(
            geminiKey: geminiKey,
            homeAssistantURL: homeAssistantURL,
            homeAssistantToken: homeAssistantToken,
            defaultCameraEntityId: defaultCameraEntityId
        )
    }

    private func testGemini() {
        isTestingGemini = true
        geminiTestResult = nil

        Task {
            let valid = await appViewModel.validateGeminiKey(geminiKey)
            await MainActor.run {
                geminiTestResult = valid ? "Gemini key is valid" : "Gemini key is invalid"
                isTestingGemini = false
            }
        }
    }

    private func testHomeAssistant() {
        isTestingHA = true
        haTestResult = nil

        Task {
            let ok = await appViewModel.testHomeAssistantConnection(
                baseURL: homeAssistantURL.trimmingCharacters(in: .whitespacesAndNewlines),
                token: homeAssistantToken.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            await MainActor.run {
                haTestResult = ok ? "Home Assistant connected" : "Home Assistant failed"
                isTestingHA = false
            }
        }
    }
}

// MARK: - Backgrounds
struct CharacterBackground: View {
    let character: BabciaCharacter
    @State private var assetName = ""

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if !assetName.isEmpty {
                    Image(assetName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    Color(.systemBackground)
                }
            }
            .onAppear {
                if assetName.isEmpty {
                    assetName = character.fullBodyAssetNames.randomElement() ?? character.assetName(for: .fullBodyHappy)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImagePicked: (UIImage) -> Void

        init(onImagePicked: @escaping (UIImage) -> Void) {
            self.onImagePicked = onImagePicked
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
