import Foundation
import UIKit
import Core
import Domain
import Common

@MainActor
public final class AppViewModel: ObservableObject {
    @Published public private(set) var rooms: [Room] = []
    @Published public private(set) var settings: AppSettings = AppSettings()
    @Published public var alertItem: AlertItem?
    @Published public var isLoading: Bool = false
    @Published public var mainBackgroundCharacter: BabciaCharacter = .classic

    private let loadRoomsUseCase: LoadRoomsUseCase
    private let saveRoomsUseCase: SaveRoomsUseCase
    private let loadSettingsUseCase: LoadSettingsUseCase
    private let saveSettingsUseCase: SaveSettingsUseCase
    private let scanRoomUseCase: ScanRoomUseCase
    private let verifyRoomUseCase: VerifyRoomUseCase
    private let testGeminiKeyUseCase: TestGeminiKeyUseCase
    private let testHomeAssistantConnectionUseCase: TestHomeAssistantConnectionUseCase
    private let fetchHACamerasUseCase: FetchHACamerasUseCase
    private let fetchHASnapshotUseCase: FetchHASnapshotUseCase
    private let scanScheduler: ScanSchedulerProtocol

    public init(
        loadRoomsUseCase: LoadRoomsUseCase,
        saveRoomsUseCase: SaveRoomsUseCase,
        loadSettingsUseCase: LoadSettingsUseCase,
        saveSettingsUseCase: SaveSettingsUseCase,
        scanRoomUseCase: ScanRoomUseCase,
        verifyRoomUseCase: VerifyRoomUseCase,
        testGeminiKeyUseCase: TestGeminiKeyUseCase,
        testHomeAssistantConnectionUseCase: TestHomeAssistantConnectionUseCase,
        fetchHACamerasUseCase: FetchHACamerasUseCase,
        fetchHASnapshotUseCase: FetchHASnapshotUseCase,
        scanScheduler: ScanSchedulerProtocol
    ) {
        self.loadRoomsUseCase = loadRoomsUseCase
        self.saveRoomsUseCase = saveRoomsUseCase
        self.loadSettingsUseCase = loadSettingsUseCase
        self.saveSettingsUseCase = saveSettingsUseCase
        self.scanRoomUseCase = scanRoomUseCase
        self.verifyRoomUseCase = verifyRoomUseCase
        self.testGeminiKeyUseCase = testGeminiKeyUseCase
        self.testHomeAssistantConnectionUseCase = testHomeAssistantConnectionUseCase
        self.fetchHACamerasUseCase = fetchHACamerasUseCase
        self.fetchHASnapshotUseCase = fetchHASnapshotUseCase
        self.scanScheduler = scanScheduler

        scanScheduler.register { [weak self] in
            guard let self else { return false }
            return await self.runAutoScans()
        }
    }

    public var totalXP: Int {
        rooms.reduce(0) { $0 + $1.totalXP }
    }

    public var level: Int {
        max(1, totalXP / 100 + 1)
    }

    public var bestStreak: Int {
        rooms.map { $0.streak }.max() ?? 0
    }

    public var currentStreak: Int {
        rooms.map { $0.streak }.max() ?? 0
    }

    public var xpToNextLevel: Int {
        let nextLevelXP = level * 100
        return max(0, nextLevelXP - totalXP)
    }

    public var hasCompletedSetup: Bool {
        settings.hasCompletedSetup
    }

    public func load() {
        Task {
            await loadData()
        }
    }

    public func refreshMainBackground() {
        mainBackgroundCharacter = BabciaCharacter.allCases.randomElement() ?? .classic
    }

    public func updateTheme(_ theme: AppTheme) {
        settings.theme = theme
        persistSettings()
    }

    public func validateGeminiKey(_ key: String) async -> Bool {
        guard !key.isEmpty else { return false }
        do {
            let isValid = try await testGeminiKeyUseCase.execute(key)
            return isValid
        } catch {
            showError(error.localizedDescription)
            return false
        }
    }

    public func updateSelectedCharacter(_ character: BabciaCharacter) {
        settings.selectedCharacter = character
        persistSettings()
    }

    public func completeSetup(geminiKey: String, selectedCharacter: BabciaCharacter) {
        settings.geminiAPIKey = geminiKey
        settings.selectedCharacter = selectedCharacter
        settings.hasCompletedSetup = true
        persistSettings()
    }

    public func updateSettings(
        geminiKey: String,
        homeAssistantURL: String,
        homeAssistantToken: String,
        defaultCameraEntityId: String
    ) {
        settings.geminiAPIKey = geminiKey
        settings.homeAssistantURL = homeAssistantURL
        settings.homeAssistantToken = homeAssistantToken
        settings.defaultCameraEntityId = defaultCameraEntityId
        persistSettings()
        rescheduleAutoScans()
    }

    public func resetSetup() {
        let theme = settings.theme
        settings = AppSettings(theme: theme)
        persistSettings()
        rescheduleAutoScans()
    }

    public func addRoom(
        name: String,
        character: BabciaCharacter,
        imageSource: RoomImageSource,
        cameraIdentifier: String?
    ) {
        let newRoom = Room(
            name: name,
            character: character,
            imageSource: imageSource,
            cameraIdentifier: cameraIdentifier
        )
        rooms.append(newRoom)
        persistRooms()
        rescheduleAutoScans()
    }

    public func deleteRoom(_ room: Room) {
        if let path = room.dreamVisionPath {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(path)
            try? FileManager.default.removeItem(at: url)
        }
        rooms.removeAll { $0.id == room.id }
        persistRooms()
        rescheduleAutoScans()
    }

    public func updateRoom(_ room: Room) {
        guard let index = rooms.firstIndex(where: { $0.id == room.id }) else { return }
        rooms[index] = room
        persistRooms()
        rescheduleAutoScans()
    }

    public func updateRoomSchedule(roomID: UUID, enabled: Bool, cadence: ScanCadence) {
        guard let index = rooms.firstIndex(where: { $0.id == roomID }) else { return }
        var schedule = rooms[index].scanSchedule ?? ScanSchedule(cadence: cadence, enabled: enabled)
        schedule.cadence = cadence
        schedule.enabled = enabled

        if enabled {
            if schedule.nextRun == nil {
                schedule.refreshNextRun()
            }
        } else {
            schedule.nextRun = nil
        }

        rooms[index].scanSchedule = schedule
        persistRooms()
        rescheduleAutoScans()
    }

    public func scanRoom(roomID: UUID, image: UIImage, captureSource: CaptureSource = .scan) {
        guard let index = rooms.firstIndex(where: { $0.id == roomID }) else { return }
        let room = rooms[index]
        let apiKey = settings.geminiAPIKey

        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                let updatedRoom = try await scanRoomUseCase.execute(
                    room: room,
                    image: image,
                    apiKey: apiKey,
                    captureSource: captureSource
                )
                rooms[index] = updatedRoom
                persistRooms()
            } catch {
                showError(error.localizedDescription)
            }
        }
    }

    public func scanHomeAssistant(roomID: UUID) {
        guard let index = rooms.firstIndex(where: { $0.id == roomID }) else { return }
        let room = rooms[index]
        guard let entityId = room.cameraIdentifier else {
            showError("Missing Home Assistant camera identifier")
            return
        }

        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                let snapshot = try await fetchHASnapshotUseCase.execute(
                    baseURL: settings.homeAssistantURL,
                    token: settings.homeAssistantToken,
                    entityId: entityId
                )
                let updatedRoom = try await scanRoomUseCase.execute(
                    room: room,
                    image: snapshot,
                    apiKey: settings.geminiAPIKey,
                    captureSource: .homeAssistant
                )
                rooms[index] = updatedRoom
                persistRooms()
            } catch {
                showError(error.localizedDescription)
            }
        }
    }

    public func verifyRoom(roomID: UUID, image: UIImage, captureSource: CaptureSource = .verify) {
        guard let index = rooms.firstIndex(where: { $0.id == roomID }) else { return }
        let room = rooms[index]
        let apiKey = settings.geminiAPIKey
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                let outcome = try await verifyRoomUseCase.execute(
                    room: room,
                    afterImage: image,
                    apiKey: apiKey,
                    modeCharacter: settings.selectedCharacter,
                    captureSource: captureSource
                )
                rooms[index] = outcome.room
                persistRooms()

                if outcome.needsRescan {
                    let message = outcome.summary.isEmpty
                        ? "Babcia needs a clearer scan to verify everything. Try another photo."
                        : outcome.summary
                    showError(message, title: "Needs another scan")
                }
            } catch {
                showError(error.localizedDescription)
            }
        }
    }

    public func verifyHomeAssistant(roomID: UUID) {
        guard let index = rooms.firstIndex(where: { $0.id == roomID }) else { return }
        let room = rooms[index]
        guard let entityId = room.cameraIdentifier else {
            showError("Missing Home Assistant camera identifier")
            return
        }

        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                let snapshot = try await fetchHASnapshotUseCase.execute(
                    baseURL: settings.homeAssistantURL,
                    token: settings.homeAssistantToken,
                    entityId: entityId
                )
                let outcome = try await verifyRoomUseCase.execute(
                    room: room,
                    afterImage: snapshot,
                    apiKey: settings.geminiAPIKey,
                    modeCharacter: settings.selectedCharacter,
                    captureSource: .homeAssistant
                )
                rooms[index] = outcome.room
                persistRooms()

                if outcome.needsRescan {
                    let message = outcome.summary.isEmpty
                        ? "Babcia needs a clearer scan to verify everything. Try another photo."
                        : outcome.summary
                    showError(message, title: "Needs another scan")
                }
            } catch {
                showError(error.localizedDescription)
            }
        }
    }

    public func manualOverride(roomID: UUID) {
        guard let index = rooms.firstIndex(where: { $0.id == roomID }) else { return }
        var room = rooms[index]
        let isTrusted = settings.selectedCharacter == .wellnessX
        var gainedXP = 0
        var didGain = false

        for taskIndex in room.tasks.indices {
            if room.tasks[taskIndex].verificationState == .verified { continue }
            room.tasks[taskIndex].isCompleted = true
            room.tasks[taskIndex].completedAt = Date()
            if isTrusted {
                room.tasks[taskIndex].verificationState = .verified
                room.tasks[taskIndex].verificationConfidence = 1.0
                room.tasks[taskIndex].verificationNote = "Trusted manual"
                gainedXP += room.tasks[taskIndex].xpReward
                didGain = true
            } else {
                room.tasks[taskIndex].verificationState = .manual
                room.tasks[taskIndex].verificationNote = "Self-declared completion"
            }
        }

        if gainedXP > 0 {
            room.totalXP += gainedXP
        }
        if didGain {
            room.recordActivity()
            room.lastVerifiedAt = Date()
        }
        room.verificationAttempts = 0
        rooms[index] = room
        persistRooms()
    }

    public func setManualTask(roomID: UUID, taskID: UUID, isCompleted: Bool) {
        guard let roomIndex = rooms.firstIndex(where: { $0.id == roomID }) else { return }
        var room = rooms[roomIndex]
        guard let taskIndex = room.tasks.firstIndex(where: { $0.id == taskID }) else { return }

        if room.tasks[taskIndex].verificationState == .verified {
            return
        }

        if isCompleted {
            room.tasks[taskIndex].isCompleted = true
            room.tasks[taskIndex].completedAt = Date()
            if settings.selectedCharacter == .wellnessX {
                room.tasks[taskIndex].verificationState = .verified
                room.tasks[taskIndex].verificationConfidence = 1.0
                room.tasks[taskIndex].verificationNote = "Trusted manual"
                room.totalXP += room.tasks[taskIndex].xpReward
                room.recordActivity()
                room.lastVerifiedAt = Date()
            } else {
                room.tasks[taskIndex].verificationState = .manual
                room.tasks[taskIndex].verificationNote = "Manual check"
            }
        } else {
            room.tasks[taskIndex].isCompleted = false
            room.tasks[taskIndex].completedAt = nil
            room.tasks[taskIndex].verificationState = .pending
            room.tasks[taskIndex].verificationNote = nil
            room.tasks[taskIndex].verificationConfidence = nil
        }

        rooms[roomIndex] = room
        persistRooms()
    }

    public func testHomeAssistantConnection(baseURL: String, token: String) async -> Bool {
        guard !baseURL.isEmpty, !token.isEmpty else { return false }
        return await testHomeAssistantConnectionUseCase.execute(baseURL: baseURL, token: token)
    }

    public func testHomeAssistantConnection() async -> Bool {
        await testHomeAssistantConnection(baseURL: settings.homeAssistantURL, token: settings.homeAssistantToken)
    }

    public func fetchHomeAssistantCameras() async throws -> [HACamera] {
        try await fetchHACamerasUseCase.execute(
            baseURL: settings.homeAssistantURL,
            token: settings.homeAssistantToken
        )
    }

    public func fetchHomeAssistantSnapshot(entityId: String) async throws -> UIImage {
        try await fetchHASnapshotUseCase.execute(
            baseURL: settings.homeAssistantURL,
            token: settings.homeAssistantToken,
            entityId: entityId
        )
    }

    public func scheduleNotificationsAuthorization() async -> Bool {
        await scanScheduler.requestNotificationAuthorization()
    }

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let loadedSettings = try await loadSettingsUseCase.execute()
            let loadedRooms = try await loadRoomsUseCase.execute()
            settings = loadedSettings
            rooms = loadedRooms
            refreshMainBackground()
            normalizeSchedules()
            await rescheduleAutoScansInternal()
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func normalizeSchedules() {
        var changed = false
        let now = Date()

        for index in rooms.indices {
            guard var schedule = rooms[index].scanSchedule, schedule.enabled else { continue }
            if schedule.nextRun == nil {
                schedule.refreshNextRun(from: now)
                rooms[index].scanSchedule = schedule
                changed = true
            }
        }

        if changed {
            persistRooms()
        }
    }

    private func persistSettings() {
        Task {
            do {
                try await saveSettingsUseCase.execute(settings)
            } catch {
                showError(error.localizedDescription)
            }
        }
    }

    private func persistRooms() {
        Task {
            do {
                try await saveRoomsUseCase.execute(rooms)
            } catch {
                showError(error.localizedDescription)
            }
        }
    }

    private func showError(_ message: String, title: String = "Error") {
        alertItem = AlertItem(title: title, message: message, dismissButton: "OK")
    }

    private func canAutoScan(room: Room) -> Bool {
        room.imageSource == .homeAssistant
            && !settings.homeAssistantURL.isEmpty
            && !settings.homeAssistantToken.isEmpty
            && room.cameraIdentifier != nil
    }

    public func rescheduleAutoScans() {
        Task {
            await rescheduleAutoScansInternal()
        }
    }

    private func rescheduleAutoScansInternal() async {
        _ = await scanScheduler.requestNotificationAuthorization()
        await scanScheduler.cancelAllNotifications()
        scanScheduler.cancelBackgroundRefresh()

        let now = Date()
        var nextBackground: Date?

        for room in rooms {
            guard let schedule = room.scanSchedule, schedule.enabled else { continue }
            let nextRun = schedule.nextRun ?? now.addingTimeInterval(schedule.cadence.interval)

            if canAutoScan(room: room) {
                if nextBackground == nil || nextRun < nextBackground! {
                    nextBackground = nextRun
                }
            } else {
                let title = "Scan \(room.name)"
                let body = "Time for a fresh room scan."
                try? await scanScheduler.scheduleNotification(
                    id: room.id.uuidString,
                    title: title,
                    body: body,
                    at: nextRun
                )
            }
        }

        if let nextBackground {
            try? scanScheduler.scheduleBackgroundRefresh(at: nextBackground)
        }
    }

    public func runAutoScans() async -> Bool {
        guard !settings.geminiAPIKey.isEmpty else { return false }

        var updatedRooms = rooms
        let now = Date()
        var didScan = false

        for index in updatedRooms.indices {
            guard var schedule = updatedRooms[index].scanSchedule, schedule.enabled else { continue }
            if let nextRun = schedule.nextRun, nextRun > now { continue }
            if !canAutoScan(room: updatedRooms[index]) { continue }
            guard let entityId = updatedRooms[index].cameraIdentifier else { continue }

            do {
                let snapshot = try await fetchHASnapshotUseCase.execute(
                    baseURL: settings.homeAssistantURL,
                    token: settings.homeAssistantToken,
                    entityId: entityId
                )

                let updatedRoom = try await scanRoomUseCase.execute(
                    room: updatedRooms[index],
                    image: snapshot,
                    apiKey: settings.geminiAPIKey,
                    captureSource: .homeAssistant
                )

                schedule.markRan(at: now)
                var room = updatedRoom
                room.scanSchedule = schedule
                updatedRooms[index] = room
                didScan = true
            } catch {
                continue
            }
        }

        if didScan {
            rooms = updatedRooms
            persistRooms()
            await rescheduleAutoScansInternal()
        }

        return didScan
    }
}
