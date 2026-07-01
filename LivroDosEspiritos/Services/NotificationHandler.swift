import Foundation
import Observation
import UserNotifications

@Observable
final class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    var pendingQuestionNumber: Int?

    func configure() {
        UNUserNotificationCenter.current().delegate = self
    }

    func clearPendingNavigation() {
        pendingQuestionNumber = nil
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        DailyQuestionNotificationService.registerDelivery(from: notification)
        return [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let notification = response.notification
        DailyQuestionNotificationService.registerDelivery(from: notification)

        let userInfo = notification.request.content.userInfo
        guard let number = userInfo[DailyQuestionNotificationService.questionNumberKey] as? Int else {
            return
        }

        await MainActor.run {
            pendingQuestionNumber = number
        }
    }
}
