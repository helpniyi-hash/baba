import Foundation
import BackgroundTasks
import UserNotifications
import Core

extension BGAppRefreshTask: @unchecked Sendable {}

public final class AutoScanScheduler: ScanSchedulerProtocol {
    public static let taskIdentifier = "com.babcia.autoscan"

    public init() {}

    public func register(backgroundHandler: @escaping @Sendable () async -> Bool) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }

            refreshTask.expirationHandler = {
                refreshTask.setTaskCompleted(success: false)
            }

            Task {
                let success = await backgroundHandler()
                refreshTask.setTaskCompleted(success: success)
            }
        }
    }

    public func scheduleBackgroundRefresh(at date: Date) throws {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = date
        try BGTaskScheduler.shared.submit(request)
    }

    public func cancelBackgroundRefresh() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.taskIdentifier)
    }

    public func requestNotificationAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    public func scheduleNotification(id: String, title: String, body: String, at date: Date) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date),
            repeats: false
        )

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try await UNUserNotificationCenter.current().add(request)
    }

    public func cancelAllNotifications() async {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
