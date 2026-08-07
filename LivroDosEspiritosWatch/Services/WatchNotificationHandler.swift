import Foundation
import Observation
import UserNotifications

@Observable
@MainActor
final class WatchNotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = WatchNotificationHandler()
    static let questionNumberKey = "questionNumber"

    var pendingQuestionNumber: Int?

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        pendingQuestionNumber = WatchPendingQuestionNavigation.peek()
    }

    func configure() {
        UNUserNotificationCenter.current().delegate = self
        if pendingQuestionNumber == nil {
            pendingQuestionNumber = WatchPendingQuestionNavigation.peek()
        }
    }

    func clearPendingNavigation() {
        pendingQuestionNumber = nil
        _ = WatchPendingQuestionNavigation.consume()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        guard let number = WatchPendingQuestionNavigation.questionNumber(from: userInfo) else {
            completionHandler()
            return
        }

        WatchPendingQuestionNavigation.store(questionNumber: number)

        Task { @MainActor in
            self.pendingQuestionNumber = number
            completionHandler()
        }
    }
}
