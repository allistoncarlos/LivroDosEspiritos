import Foundation

enum NotificationSchedulePreferences {
    private static let hourKey = "dailyQuestion.notificationHour"
    private static let minuteKey = "dailyQuestion.notificationMinute"
    private static let defaultHour = 19
    private static let defaultMinute = 30

    static var hour: Int {
        get {
            let stored = UserDefaults.standard.object(forKey: hourKey) as? Int
            return stored ?? defaultHour
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hourKey)
        }
    }

    static var minute: Int {
        get {
            let stored = UserDefaults.standard.object(forKey: minuteKey) as? Int
            return stored ?? defaultMinute
        }
        set {
            UserDefaults.standard.set(newValue, forKey: minuteKey)
        }
    }

    static var scheduledTime: Date {
        get {
            calendarDate(from: hour, minute: minute)
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            hour = components.hour ?? defaultHour
            minute = components.minute ?? defaultMinute
        }
    }

    static var formattedTime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: scheduledTime)
    }

    private static func calendarDate(from hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.current.date(from: components) ?? .now
    }
}
