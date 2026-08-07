import UserNotifications
import WatchKit

final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    @MainActor
    func applicationDidFinishLaunching() {
        WatchNotificationHandler.shared.configure()
    }
}
