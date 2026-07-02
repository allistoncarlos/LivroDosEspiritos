import SwiftUI
import UserNotifications

@main
struct LivroDosEspiritosWatchApp: App {
    @State private var store = BookDataStore()
    @State private var notificationHandler = WatchNotificationHandler()

    var body: some Scene {
        WindowGroup {
            QuestionReaderView()
                .environment(store)
                .environment(notificationHandler)
                .task {
                    notificationHandler.configure()
                    let center = UNUserNotificationCenter.current()
                    let settings = await center.notificationSettings()
                    if settings.authorizationStatus == .notDetermined {
                        _ = try? await center.requestAuthorization(options: [.alert, .sound])
                    }
                }
        }
    }
}
