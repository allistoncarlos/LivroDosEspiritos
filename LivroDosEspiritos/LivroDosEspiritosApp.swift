import SwiftUI

@main
struct LivroDosEspiritosApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store = BookDataStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(store)
                .task {
                    await setupDailyNotifications()
                }
                .onOpenURL { url in
                    guard PendingQuestionNavigation.storeIfValid(url: url) else { return }
                    NotificationCenter.default.post(name: .openPendingQuestion, object: nil)
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
