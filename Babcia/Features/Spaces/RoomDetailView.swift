import SwiftUI
import Core
import Presentation
import UIKit

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

    private var room: Room? {
        appViewModel.rooms.first { $0.id == roomID }
    }

    var body: some View {
        Group {
            if let room {
                roomView(room)
            } else {
                Text("Room not found")
                    .babciaTextStyle(.title1)
            }
        }
    }

    @ViewBuilder
    private func roomView(_ room: Room) -> some View {
        ScrollView {
            roomContent(room)
        }
        .safeAreaInset(edge: .bottom) {
            bottomActions
        }
        .babciaScreen()
        .navigationTitle("Room")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCameraMenu = true
                } label: {
                    Image(systemName: "camera")
                }
                .accessibilityLabel("Room camera options")
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
    }

    private func roomContent(_ room: Room) -> some View {
        BabciaVStack(spacing: .medium) {
            headerSection(room)
            titleSection(room)
            StatusRow(room: room)
            RoomModeSummaryCard(
                room: room,
                modeCharacter: appViewModel.settings.selectedCharacter
            )
            adviceSection(room)
            tasksSection(room)
            AutoScanCard(room: room)
                .babciaSectionStyle(title: "Auto Scan")
            RoomStatsRow(room: room)
                .babciaSectionStyle(title: "Room Stats")
        }
        .babciaPadding()
    }

    private func headerSection(_ room: Room) -> some View {
        BabciaCoverFlow(height: 250, data: headerImages(for: room), id: \.id) { image in
            RoomHeaderCard(image: image)
        }
    }

    private func titleSection(_ room: Room) -> some View {
        BabciaVStack(spacing: .zero) {
            Text(room.name)
                .babciaTextStyle(.title2)
            Text(room.character.displayName)
                .babciaTextStyle(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func adviceSection(_ room: Room) -> some View {
        if let advice = room.babciaAdvice, !advice.isEmpty {
            AdviceCard(message: advice)
                .babciaSectionStyle(title: "Advice")
        }
    }

    @ViewBuilder
    private func tasksSection(_ room: Room) -> some View {
        if room.tasks.isEmpty {
            EmptyTasksCard()
                .babciaSectionStyle(title: "Tasks")
        } else {
            VerificationSummaryCard(room: room)
                .babciaSectionStyle(title: "Verification")

            TaskListCard(room: room) { task, markComplete in
                if markComplete {
                    pendingManualToggle = ManualToggleIntent(taskID: task.id, markComplete: true)
                } else {
                    appViewModel.setManualTask(roomID: room.id, taskID: task.id, isCompleted: false)
                }
            }
            .babciaSectionStyle(title: "Tasks")

            if let lastVerified = room.lastVerifiedAt {
                Text("Last verified: \(lastVerified.formatted(date: .abbreviated, time: .shortened))")
                    .babciaTextStyle(.caption1)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if room.manualOverrideAvailable {
                ManualOverrideCard(
                    isTrusted: appViewModel.settings.selectedCharacter == .wellnessX,
                    onOverride: { showingManualOverrideConfirm = true }
                )
                .babciaSectionStyle(title: "Manual Override")
            }
        }
    }

    private var bottomActions: some View {
        BabciaBottomContainer {
            BabciaButton(title: "Verify room", leftIcon: "checkmark.shield", style: .secondary) {
                imagePickerAction = .verify
                showingSourceMenu = true
            }
            BabciaButton(title: "Scan room", leftIcon: "camera") {
                imagePickerAction = .scan
                showingSourceMenu = true
            }
        }
    }

    private func headerImages(for room: Room) -> [RoomHeaderImage] {
        if let url = room.dreamVisionURL {
            return [RoomHeaderImage(url: url)]
        }
        return [RoomHeaderImage(assetName: room.character.portraitAssetName)]
    }
}

struct RoomHeaderImage: Identifiable, Hashable {
    let id: String
    let url: URL?
    let assetName: String?

    init(url: URL) {
        self.id = url.absoluteString
        self.url = url
        self.assetName = nil
    }

    init(assetName: String) {
        self.id = assetName
        self.url = nil
        self.assetName = assetName
    }
}

struct RoomHeaderCard: View {
    let image: RoomHeaderImage

    var body: some View {
        ZStack {
            if let url = image.url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Color.gray.opacity(0.2)
                    }
                }
            } else if let assetName = image.assetName {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.2)
            }
        }
        .frame(maxWidth: .infinity)
        .clipped()
        .babciaCornerRadius()
    }
}

struct StatusRow: View {
    let room: Room

    var body: some View {
        BabciaHStack(spacing: .regular) {
            StatusPill(text: "Verified \(room.tasks.filter { $0.verificationState == .verified }.count)", color: .green)
            StatusPill(text: "Manual \(room.tasks.filter { $0.verificationState == .manual }.count)", color: .orange)
            StatusPill(text: "Pending \(room.pendingTaskCount)", color: .gray)
        }
    }
}

struct StatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .babciaTextStyle(.caption1, color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .babciaCornerRadius()
    }
}

struct RoomModeSummaryCard: View {
    let room: Room
    let modeCharacter: BabciaCharacter

    var body: some View {
        BabciaHStack(spacing: .regular) {
            Image(room.character.headshotAssetName)
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color(hex: room.character.accentHex), lineWidth: 2)
                )

            BabciaVStack(alignment: .leading, spacing: .zero) {
                Text("Mode: \(modeCharacter.verificationModeName)")
                    .babciaTextStyle(.headline)
                Text(modeCharacter.verificationModeDescription)
                    .babciaTextStyle(.caption1)
                    .foregroundColor(.secondary)
                Text("Room Babcia: \(room.character.displayName)")
                    .babciaTextStyle(.caption1)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .babciaCardStyle()
    }
}

struct VerificationSummaryCard: View {
    let room: Room

    var body: some View {
        BabciaVStack(alignment: .leading, spacing: .small) {
            Text("Use the camera to verify or update the room baseline.")
                .babciaTextStyle(.caption1)
                .foregroundColor(.secondary)

            BabciaHStack(spacing: .small) {
                StatusPill(text: "Verified \(room.tasks.filter { $0.verificationState == .verified }.count)", color: .green)
                StatusPill(text: "Manual \(room.tasks.filter { $0.verificationState == .manual }.count)", color: .orange)
                StatusPill(text: "Pending \(room.pendingTaskCount)", color: .gray)
            }
        }
        .babciaCardStyle()
    }
}

struct AdviceCard: View {
    let message: String

    var body: some View {
        Text(message)
            .babciaTextStyle(.body)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .babciaCardStyle()
    }
}

struct EmptyTasksCard: View {
    var body: some View {
        BabciaVStack(alignment: .leading, spacing: .small) {
            Text("No tasks yet")
                .babciaTextStyle(.headline)

            Text("Use the camera to scan this room and generate tasks.")
                .babciaTextStyle(.caption1)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .babciaCardStyle()
    }
}

struct TaskListCard: View {
    let room: Room
    let onToggle: (CleaningTask, Bool) -> Void

    var body: some View {
        BabciaVStack(spacing: .small) {
            ForEach(room.tasks) { task in
                TaskRow(task: task, onToggle: { onToggle(task, $0) })
            }
        }
    }
}

struct TaskRow: View {
    let task: CleaningTask
    let onToggle: (Bool) -> Void

    private var isLocked: Bool {
        task.verificationState == .verified
    }

    var body: some View {
        BabciaHStack(spacing: .medium) {
            Button(action: {
                guard !isLocked else { return }
                onToggle(!task.isCompleted)
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .disabled(isLocked)
            .accessibilityLabel(task.isCompleted ? "Mark task incomplete" : "Mark task complete")

            Text(task.title)
                .babciaTextStyle(.body)
                .foregroundColor(.primary)
                .strikethrough(task.isCompleted, color: .secondary)

            Spacer()

            let override = (task.verificationNote ?? "").localizedCaseInsensitiveContains("trusted") ? "Trusted" : nil
            TaskStatusBadge(state: task.resolvedVerificationState, labelOverride: override)

            Text("+\(task.xpReward)")
                .babciaTextStyle(.caption1)
                .foregroundColor(.secondary)
        }
        .babciaPadding(.regular)
        .babciaSecondaryBackground()
        .babciaCornerRadius()
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: task.isCompleted)
    }
}

struct TaskStatusBadge: View {
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

    private var badgeColor: Color {
        switch state {
        case .verified:
            return .green
        case .manual:
            return .orange
        case .pending:
            return .gray
        }
    }

    var body: some View {
        StatusPill(text: label, color: badgeColor)
    }
}

struct ManualOverrideCard: View {
    let isTrusted: Bool
    let onOverride: () -> Void

    var body: some View {
        BabciaVStack(alignment: .leading, spacing: .small) {
            Text("Babcia is unsure")
                .babciaTextStyle(.headline)

            Text(isTrusted
                 ? "Trusted mode allows manual completion with XP."
                 : "Try a clearer scan using the camera, or manually override if you must. This is logged as self-declared.")
                .babciaTextStyle(.caption1)
                .foregroundColor(.secondary)

            BabciaButton(title: "Manual override", style: .secondary) {
                onOverride()
            }
        }
        .babciaCardStyle()
    }
}

struct AutoScanCard: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    let room: Room

    private var schedule: ScanSchedule {
        room.scanSchedule ?? ScanSchedule(cadence: .daily, enabled: false)
    }

    var body: some View {
        BabciaVStack(alignment: .leading, spacing: .medium) {
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
                    .babciaTextStyle(.caption1)
                    .foregroundColor(.secondary)
            } else {
                Text("Next scan will be scheduled after enabling.")
                    .babciaTextStyle(.caption1)
                    .foregroundColor(.secondary)
            }

            Text(scheduleNote)
                .babciaTextStyle(.caption1)
                .foregroundColor(.secondary)
        }
        .babciaCardStyle()
    }

    private var scheduleNote: String {
        if room.imageSource == .homeAssistant {
            return "Home Assistant rooms can auto-scan in the background."
        }
        return "Manual rooms receive reminders to scan."
    }
}

struct RoomStatsRow: View {
    let room: Room

    var body: some View {
        BabciaHStack(spacing: .medium) {
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
        BabciaVStack(spacing: .zero) {
            Text(value)
                .babciaTextStyle(.headline)
                .foregroundColor(.primary)
            Text(title)
                .babciaTextStyle(.caption1)
                .foregroundColor(.secondary)
        }
        .babciaPadding(.vertical, .small)
        .frame(maxWidth: .infinity)
        .babciaSecondaryBackground()
        .babciaCornerRadius()
    }
}
