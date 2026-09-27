import UserNotifications
import WatchKit

final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    @MainActor
    func applicationDidFinishLaunching() {
        _ = AnalyticsService.amplitude
        WatchNotificationHandler.shared.configure()
    }
}
