import SwiftUI

@main
struct LivroDosEspiritosApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store = BookDataStore()
    @State private var notificationSetupTask: Task<Void, Never>?
    @State private var lastNotificationSetup: Date?
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(store)
                .task {
                    await store.load()
                    startNotificationSetup()
                }
                .onOpenURL { url in
                    guard PendingQuestionNavigation.storeIfValid(url: url) else { return }
                    NotificationCenter.default.post(name: .openPendingQuestion, object: nil)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    startNotificationSetup()
                }
        }
    }

    private func startNotificationSetup() {
        guard notificationSetupTask == nil else { return }

        // Notification state does not need to be rebuilt on every foreground event.
        // A daily refresh is enough and prevents overlapping UNUserNotificationCenter
        // work while the UI is becoming active.
        if let lastNotificationSetup,
           Date.now.timeIntervalSince(lastNotificationSetup) < 24 * 60 * 60 {
            return
        }

        notificationSetupTask = Task {
            await setupDailyNotifications()
            await MainActor.run {
                lastNotificationSetup = .now
                notificationSetupTask = nil
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
