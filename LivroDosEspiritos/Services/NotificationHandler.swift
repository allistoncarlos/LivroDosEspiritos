import Foundation
import Observation
import UserNotifications

@Observable
final class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    var pendingQuestionNumber: Int?

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

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
        guard let number = questionNumber(from: userInfo) else {
            return
        }

        await MainActor.run {
            pendingQuestionNumber = number
        }
    }

    private func questionNumber(from userInfo: [AnyHashable: Any]) -> Int? {
        let key = DailyQuestionNotificationService.questionNumberKey
        if let number = userInfo[key] as? Int {
            return number
        }
        if let number = userInfo[key] as? NSNumber {
            return number.intValue
        }
        return nil
    }
}
