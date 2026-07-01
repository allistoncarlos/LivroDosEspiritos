import SwiftUI

@main
struct LivroDosEspiritosApp: App {
    @State private var store = BookDataStore()
    @State private var notificationHandler = NotificationHandler()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(store)
                .environment(notificationHandler)
                .task {
                    notificationHandler.configure()
                    await setupDailyNotifications()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    Task { await setupDailyNotifications() }
                }
        }
    }

    private func setupDailyNotifications() async {
        guard store.book != nil else { return }

        let status = await DailyQuestionNotificationService.authorizationStatus()
        if status == .notDetermined {
            let granted = await DailyQuestionNotificationService.requestAuthorization()
            guard granted else { return }
        } else if status == .denied {
            return
        }

        await DailyQuestionNotificationService.syncDeliveredNotifications()
        await DailyQuestionNotificationService.refreshSchedule(dataStore: store)
    }
}
