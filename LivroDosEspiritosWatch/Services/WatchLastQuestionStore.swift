import Foundation

enum WatchLastQuestionStore {
    private static let key = "watch.lastQuestionNumber"
    private static let minimum = 1
    private static let maximum = 1019

    static var lastQuestionNumber: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: key)
            guard stored >= minimum, stored <= maximum else {
                return minimum
            }
            return stored
        }
        set {
            let clamped = min(max(newValue, minimum), maximum)
            UserDefaults.standard.set(clamped, forKey: key)
        }
    }
}
