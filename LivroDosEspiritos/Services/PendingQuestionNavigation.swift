import Foundation

enum PendingQuestionNavigation {
    private static let key = "pendingNotificationQuestionNumber"

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
        let key = DailyQuestionNotificationService.questionNumberKey
        if let number = userInfo[key] as? Int { return number }
        if let number = userInfo[key] as? NSNumber { return number.intValue }
        return nil
    }

    @discardableResult
    static func storeIfValid(url: URL) -> Bool {
        guard url.scheme?.lowercased() == "livrodosespiritos" else { return false }

        let components = url.pathComponents.filter { $0 != "/" }
        guard let index = components.firstIndex(of: "pergunta"),
              components.indices.contains(index + 1),
              let number = Int(components[index + 1]) else {
            return false
        }

        store(questionNumber: number)
        return true
    }
}

extension Notification.Name {
    static let openPendingQuestion = Notification.Name("openPendingQuestion")
}

enum QuestionDeepLinkURL {
    static func question(_ number: Int) -> URL {
        URL(string: "livrodosespiritos://pergunta/\(number)")!
    }
}
