import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

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
        let userInfo = notification.request.content.userInfo

        DailyQuestionNotificationService.registerDelivery(from: notification)

        if let urlString = userInfo["deepLink"] as? String,
           let url = URL(string: urlString),
           PendingQuestionNavigation.storeIfValid(url: url) {
            return
        }

        if let number = PendingQuestionNavigation.questionNumber(from: userInfo) {
            PendingQuestionNavigation.store(questionNumber: number)
        }
    }
}
