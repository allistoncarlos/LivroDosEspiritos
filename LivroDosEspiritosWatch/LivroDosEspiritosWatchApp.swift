import SwiftUI
import UserNotifications

@main
struct LivroDosEspiritosWatchApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) private var appDelegate
    @State private var store = BookDataStore()

    var body: some Scene {
        WindowGroup {
            QuestionReaderView()
                .environment(store)
                .environment(WatchNotificationHandler.shared)
                .task {
                    WatchNotificationHandler.shared.configure()
                    let center = UNUserNotificationCenter.current()
                    let settings = await center.notificationSettings()
                    if settings.authorizationStatus == .notDetermined {
                        _ = try? await center.requestAuthorization(options: [.alert, .sound])
                    }
                }
        }
    }
}
