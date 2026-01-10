import SwiftUI
import Presentation
import Common
import Core
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
    @Environment(\.colorScheme) private var colorScheme
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
                BabciaPageTemplate(heroImage: heroImage(for: room)) {
                    VStack(alignment: .leading, spacing: BabciaConstants.Spacing.sectionGap) {
                        // Room header with title
                        VStack(alignment: .leading, spacing: BabciaConstants.Spacing.xs) {
                            Text(room.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(room.character.displayName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Mode summary card
                        RoomModeSummaryCard(room: room, modeCharacter: appViewModel.settings.selectedCharacter)

                        if let advice = room.babciaAdvice, !advice.isEmpty {
                            AdviceGlassCard(message: advice)
                        }

                        if room.tasks.isEmpty {
                            EmptyTasksGlassCard()
                        } else {
                            VerificationSummaryGlassCard(room: room)

                            TaskListGlassCard(room: room) { task, markComplete in
                                if markComplete {
                                    pendingManualToggle = ManualToggleIntent(taskID: task.id, markComplete: true)
                                } else {
                                    appViewModel.setManualTask(roomID: room.id, taskID: task.id, isCompleted: false)
                                }
                            }

                            if let lastVerified = room.lastVerifiedAt {
                                Text("Last verified: \(lastVerified.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            if room.manualOverrideAvailable {
                                ManualOverrideGlassCard(
                                    isTrusted: appViewModel.settings.selectedCharacter == .wellnessX,
                                    onOverride: { showingManualOverrideConfirm = true }
                                )
                            }
                        }

                        AutoScanGlassCard(room: room)

                        RoomStatsBar(room: room)
                    }
                }
                .toolbarBackground(.hidden, for: .navigationBar)
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
            } else {
                Text("Room not found")
                    .font(.title)
            }
        }
    }
    
    private func heroImage(for room: Room) -> Image {
        // Note: BabciaPageTemplate requires an Image, not AsyncImage
        // Dream vision URLs will need a different implementation pattern in future
        // For now, always use character portrait for consistent template behavior
        return Image(room.character.portraitAssetName)
    }
}

// MARK: - Glass Card Components

struct RoomModeSummaryCard: View {
    let room: Room
    let modeCharacter: BabciaCharacter

    var body: some View {
        HStack(spacing: BabciaConstants.Spacing.md) {
            Image(room.character.headshotAssetName)
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color(hex: room.character.accentHex), lineWidth: 2)
                )

            VStack(alignment: .leading, spacing: BabciaConstants.Spacing.xxs) {
                Text("Mode: \(modeCharacter.verificationModeName)")
                    .font(.headline)
                Text(modeCharacter.verificationModeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Room Babcia: \(room.character.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(BabciaConstants.Spacing.cardPadding)
        .glassEffectFallback()
        .clipShape(RoundedRectangle(cornerRadius: BabciaConstants.Corner.card, style: .continuous))
    }
}

struct VerificationSummaryGlassCard: View {
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
        VStack(alignment: .leading, spacing: BabciaConstants.Spacing.sm) {
            Text("Verification")
                .font(.headline)

            Text("Use the top camera button to verify or update the room baseline.")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: BabciaConstants.Spacing.sm) {
                LiquidGlassBadge("Verified: \(verifiedCount)")
                    .tint(.green)
                LiquidGlassBadge("Manual: \(manualCount)")
                    .tint(.orange)
                LiquidGlassBadge("Pending: \(pendingCount)")
                    .tint(.secondary)
            }
        }
        .padding(BabciaConstants.Spacing.cardPadding)
        .glassEffectFallback()
        .clipShape(RoundedRectangle(cornerRadius: BabciaConstants.Corner.card, style: .continuous))
    }
}

struct AdviceGlassCard: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.body)
            .foregroundColor(.primary)
            .padding(BabciaConstants.Spacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffectFallback()
            .clipShape(RoundedRectangle(cornerRadius: BabciaConstants.Corner.card, style: .continuous))
    }
}

struct EmptyTasksGlassCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: BabciaConstants.Spacing.sm) {
            Text("No tasks yet")
                .font(.headline)

            Text("Use the top camera button to scan this room and generate tasks.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(BabciaConstants.Spacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffectFallback()
        .clipShape(RoundedRectangle(cornerRadius: BabciaConstants.Corner.card, style: .continuous))
    }
}

struct TaskListGlassCard: View {
    let room: Room
    let onToggle: (CleaningTask, Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: BabciaConstants.Spacing.sm) {
            Text("Tasks")
                .font(.headline)

            VStack(spacing: BabciaConstants.Spacing.xs) {
                ForEach(room.tasks) { task in
                    TaskRowGlass(
                        task: task,
                        onToggle: { onToggle(task, $0) }
                    )
                }
            }
        }
        .padding(BabciaConstants.Spacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffectFallback()
        .clipShape(RoundedRectangle(cornerRadius: BabciaConstants.Corner.card, style: .continuous))
    }
}

struct TaskRowGlass: View {
    let task: CleaningTask
    let onToggle: (Bool) -> Void

    private var isLocked: Bool {
        task.verificationState == .verified
    }

    var body: some View {
        HStack(spacing: BabciaConstants.Spacing.md) {
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
                .font(.body)
                .foregroundColor(.primary)
                .strikethrough(task.isCompleted, color: .secondary)

            Spacer()

            let override = (task.verificationNote ?? "").localizedCaseInsensitiveContains("trusted") ? "Trusted" : nil
            TaskStatusBadge(state: task.resolvedVerificationState, labelOverride: override)

            Text("+\(task.xpReward)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, BabciaConstants.Spacing.xxs)
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
            return .secondary
        }
    }

    var body: some View {
        LiquidGlassBadge(label)
            .tint(badgeColor)
    }
}

struct ManualOverrideGlassCard: View {
    let isTrusted: Bool
    let onOverride: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: BabciaConstants.Spacing.sm) {
            Text("Babcia is unsure")
                .font(.headline)

            Text(isTrusted
                 ? "Trusted mode allows manual completion with XP."
                 : "Try a clearer scan using the top camera button, or manually override if you must. This is logged as self-declared.")
                .font(.caption)
                .foregroundColor(.secondary)

            LiquidGlassButton("Manual override", action: onOverride)
                .accessibilityLabel("Manual override")
        }
        .padding(BabciaConstants.Spacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffectFallback()
        .clipShape(RoundedRectangle(cornerRadius: BabciaConstants.Corner.card, style: .continuous))
    }
}

struct AutoScanGlassCard: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    let room: Room

    private var schedule: ScanSchedule {
        room.scanSchedule ?? ScanSchedule(cadence: .daily, enabled: false)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BabciaConstants.Spacing.md) {
            Text("Auto Scan")
                .font(.headline)

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
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Next scan will be scheduled after enabling.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(scheduleNote)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(BabciaConstants.Spacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffectFallback()
        .clipShape(RoundedRectangle(cornerRadius: BabciaConstants.Corner.card, style: .continuous))
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
        HStack(spacing: BabciaConstants.Spacing.md) {
            StatPillGlass(title: "XP", value: "\(room.totalXP)")
            StatPillGlass(title: "Streak", value: "\(room.streak)d")
            StatPillGlass(title: "Done", value: "\(room.completedTaskCount)")
        }
    }
}

struct StatPillGlass: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: BabciaConstants.Spacing.xxs) {
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, BabciaConstants.Spacing.sm)
        .padding(.vertical, BabciaConstants.Spacing.xs)
        .frame(maxWidth: .infinity, minHeight: BabciaConstants.Size.minTouchTarget)
        .glassEffectFallback()
        .clipShape(RoundedRectangle(cornerRadius: BabciaConstants.Corner.badge, style: .continuous))
    }
}
