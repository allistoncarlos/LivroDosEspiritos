import Foundation
import Observation
import UserNotifications

@Observable
final class WatchNotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    static let questionNumberKey = "questionNumber"

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

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let number = questionNumber(from: userInfo) else { return }

        await MainActor.run {
            pendingQuestionNumber = number
        }
    }

    private func questionNumber(from userInfo: [AnyHashable: Any]) -> Int? {
        if let number = userInfo[Self.questionNumberKey] as? Int {
            return number
        }
        if let number = userInfo[Self.questionNumberKey] as? NSNumber {
            return number.intValue
        }
        return nil
    }
}
