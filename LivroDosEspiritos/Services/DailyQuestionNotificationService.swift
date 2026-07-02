import Foundation
import UserNotifications

enum DailyQuestionNotificationService {
    static let notificationPrefix = "daily-question"
    static let daysToSchedule = 30
    static let questionNumberKey = "questionNumber"

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func refreshSchedule(dataStore: BookDataStore) async {
        await reschedule(dataStore: dataStore, replacingPending: false)
    }

    static func rescheduleAfterPreferenceChange(dataStore: BookDataStore) async {
        await reschedule(dataStore: dataStore, replacingPending: true)
    }

    private static func reschedule(dataStore: BookDataStore, replacingPending: Bool) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return
        }

        if replacingPending {
            await removeAllScheduled()
        }

        let store = DailyQuestionRotationStore.shared
        store.clearAssignmentsBeforeToday()

        await syncDeliveredNotifications()

        let calendar = Calendar.current
        let pending = await pendingDailyRequests(center: center)
        let pendingDateKeys = Set(pending.compactMap { dateKey(for: $0, calendar: calendar) })

        var fireDate = nextFireDate(from: .now, calendar: calendar)
        var scheduledCount = pending.count

        while scheduledCount < daysToSchedule {
            let key = dateKey(for: fireDate, calendar: calendar)
            if !pendingDateKeys.contains(key) {
                let questionNumber = store.questionForScheduling(on: fireDate, calendar: calendar)
                guard let question = dataStore.question(number: questionNumber) else {
                    fireDate = calendar.date(byAdding: .day, value: 1, to: fireDate) ?? fireDate
                    continue
                }

                let content = makeContent(for: question)
                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "\(notificationPrefix)-\(key)",
                    content: content,
                    trigger: trigger
                )

                try? await center.add(request)
                scheduledCount += 1
            }

            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: fireDate) else { break }
            fireDate = nextDay
        }
    }

    static func removeAllScheduled() async {
        let center = UNUserNotificationCenter.current()
        let pending = await pendingDailyRequests(center: center)
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier))
    }

    /// Sincroniza perguntas cujas notificações já foram entregues (app fechado ou em background).
    static func syncDeliveredNotifications() async {
        let center = UNUserNotificationCenter.current()
        let delivered = await withCheckedContinuation { continuation in
            center.getDeliveredNotifications { notifications in
                continuation.resume(returning: notifications)
            }
        }

        let store = DailyQuestionRotationStore.shared
        for notification in delivered where notification.request.identifier.hasPrefix(notificationPrefix) {
            guard let number = notification.request.content.userInfo[questionNumberKey] as? Int else { continue }
            store.markAsNotified(number)
        }
    }

    static func registerDelivery(from notification: UNNotification) {
        guard notification.request.identifier.hasPrefix(notificationPrefix) else {
            return
        }

        let userInfo = notification.request.content.userInfo
        let number: Int? = {
            if let value = userInfo[questionNumberKey] as? Int { return value }
            if let value = userInfo[questionNumberKey] as? NSNumber { return value.intValue }
            return nil
        }()

        guard let number else { return }
        DailyQuestionRotationStore.shared.markAsNotified(number)
    }

    // MARK: - Private

    private static func makeContent(for question: Question) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Pergunta do dia — \(question.number)"
        content.subtitle = question.chapterTitle
        content.body = truncated(question.question, limit: 180)
        content.sound = .default
        content.userInfo = [
            questionNumberKey: question.number,
            "deepLink": QuestionDeepLinkURL.question(question.number).absoluteString
        ]
        return content
    }

    private static func truncated(_ text: String, limit: Int) -> String {
        guard text.count > limit else { return text }
        return String(text.prefix(limit - 1)) + "…"
    }

    private static func nextFireDate(from date: Date, calendar: Calendar) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = NotificationSchedulePreferences.hour
        components.minute = NotificationSchedulePreferences.minute
        components.second = 0

        guard let candidate = calendar.date(from: components) else {
            return date
        }

        if candidate > date {
            return candidate
        }

        return calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
    }

    private static func pendingDailyRequests(center: UNUserNotificationCenter) async -> [UNNotificationRequest] {
        await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                let daily = requests.filter { $0.identifier.hasPrefix(notificationPrefix) }
                continuation.resume(returning: daily)
            }
        }
    }

    private static func dateKey(for request: UNNotificationRequest, calendar: Calendar) -> String? {
        guard let trigger = request.trigger as? UNCalendarNotificationTrigger,
              let date = trigger.nextTriggerDate() else {
            return nil
        }
        return dateKey(for: date, calendar: calendar)
    }

    private static func dateKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}
