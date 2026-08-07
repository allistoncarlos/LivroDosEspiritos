import Foundation

enum WatchPendingQuestionNavigation {
    private static let key = "watch.pendingNotificationQuestionNumber"

    static func store(questionNumber: Int) {
        UserDefaults.standard.set(questionNumber, forKey: key)
    }

    static func peek() -> Int? {
        let stored = UserDefaults.standard.object(forKey: key) as? Int
        guard let stored, stored > 0 else { return nil }
        return stored
    }

    static func consume() -> Int? {
        guard let stored = peek() else { return nil }
        UserDefaults.standard.removeObject(forKey: key)
        return stored
    }

    static func questionNumber(from userInfo: [AnyHashable: Any]) -> Int? {
        if let urlString = userInfo["deepLink"] as? String,
           let url = URL(string: urlString),
           let number = questionNumber(from: url) {
            return number
        }

        let key = WatchNotificationHandler.questionNumberKey
        if let number = userInfo[key] as? Int {
            return number
        }
        if let number = userInfo[key] as? NSNumber {
            return number.intValue
        }
        if let string = userInfo[key] as? String, let number = Int(string) {
            return number
        }
        return nil
    }

    static func questionNumber(from url: URL) -> Int? {
        guard url.scheme?.lowercased() == "livrodosespiritos" else { return nil }

        let components = url.pathComponents.filter { $0 != "/" }
        guard let index = components.firstIndex(of: "pergunta"),
              components.indices.contains(index + 1),
              let number = Int(components[index + 1]),
              number > 0 else {
            return nil
        }

        return number
    }
}
