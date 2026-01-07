//
//  DIContainer.swift
//  DI
//
//  Created by Prank on 18/9/25.
//

import Foundation
import Core
import Domain
import DataLayer
import Presentation

public final class DIContainer: Sendable {
    public static let shared = DIContainer()

    private init() {}

    // MARK: - Repositories

    private nonisolated(unsafe) var _roomsRepository: RoomsRepositoryProtocol?
    public var roomsRepository: RoomsRepositoryProtocol {
        if _roomsRepository == nil {
            _roomsRepository = RoomsRepository()
        }
        return _roomsRepository!
    }

    private nonisolated(unsafe) var _settingsRepository: SettingsRepositoryProtocol?
    public var settingsRepository: SettingsRepositoryProtocol {
        if _settingsRepository == nil {
            _settingsRepository = SettingsRepository()
        }
        return _settingsRepository!
    }

    private nonisolated(unsafe) var _scanRepository: ScanRepositoryProtocol?
    public var scanRepository: ScanRepositoryProtocol {
        if _scanRepository == nil {
            _scanRepository = ScanRepository()
        }
        return _scanRepository!
    }

    private nonisolated(unsafe) var _memoryRepository: MemoryRepositoryProtocol?
    public var memoryRepository: MemoryRepositoryProtocol {
        if _memoryRepository == nil {
            _memoryRepository = MemoryRepository()
        }
        return _memoryRepository!
    }

    private nonisolated(unsafe) var _scanScheduler: ScanSchedulerProtocol?
    public var scanScheduler: ScanSchedulerProtocol {
        if _scanScheduler == nil {
            _scanScheduler = AutoScanScheduler()
        }
        return _scanScheduler!
    }

    // MARK: - Use Cases

    public var loadRoomsUseCase: LoadRoomsUseCase {
        LoadRoomsUseCase(repository: roomsRepository)
    }

    public var saveRoomsUseCase: SaveRoomsUseCase {
        SaveRoomsUseCase(repository: roomsRepository)
    }

    public var loadSettingsUseCase: LoadSettingsUseCase {
        LoadSettingsUseCase(repository: settingsRepository)
    }

    public var saveSettingsUseCase: SaveSettingsUseCase {
        SaveSettingsUseCase(repository: settingsRepository)
    }

    public var scanRoomUseCase: ScanRoomUseCase {
        ScanRoomUseCase(repository: scanRepository)
    }

    public var verifyRoomUseCase: VerifyRoomUseCase {
        VerifyRoomUseCase(repository: scanRepository)
    }

    public var testGeminiKeyUseCase: TestGeminiKeyUseCase {
        TestGeminiKeyUseCase(repository: scanRepository)
    }

    public var testHomeAssistantConnectionUseCase: TestHomeAssistantConnectionUseCase {
        TestHomeAssistantConnectionUseCase(repository: scanRepository)
    }

    public var fetchHASnapshotUseCase: FetchHASnapshotUseCase {
        FetchHASnapshotUseCase(repository: scanRepository)
    }

    public var fetchHACamerasUseCase: FetchHACamerasUseCase {
        FetchHACamerasUseCase(repository: scanRepository)
    }

    // MARK: - ViewModels

    @MainActor
    public func makeAppViewModel() -> AppViewModel {
        AppViewModel(
            loadRoomsUseCase: loadRoomsUseCase,
            saveRoomsUseCase: saveRoomsUseCase,
            loadSettingsUseCase: loadSettingsUseCase,
            saveSettingsUseCase: saveSettingsUseCase,
            scanRoomUseCase: scanRoomUseCase,
            verifyRoomUseCase: verifyRoomUseCase,
            testGeminiKeyUseCase: testGeminiKeyUseCase,
            testHomeAssistantConnectionUseCase: testHomeAssistantConnectionUseCase,
            fetchHACamerasUseCase: fetchHACamerasUseCase,
            fetchHASnapshotUseCase: fetchHASnapshotUseCase,
            scanScheduler: scanScheduler
        )
    }
}
