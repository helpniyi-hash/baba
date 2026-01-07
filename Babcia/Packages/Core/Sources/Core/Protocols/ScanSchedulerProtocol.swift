import Foundation

public protocol ScanSchedulerProtocol: Sendable {
    func register(backgroundHandler: @escaping @Sendable () async -> Bool)
    func scheduleBackgroundRefresh(at date: Date) throws
    func cancelBackgroundRefresh()

    func requestNotificationAuthorization() async -> Bool
    func scheduleNotification(id: String, title: String, body: String, at date: Date) async throws
    func cancelAllNotifications() async
}
