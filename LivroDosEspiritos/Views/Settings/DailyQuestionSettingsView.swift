import SwiftUI
import UserNotifications

struct DailyQuestionSettingsView: View {
    @Environment(BookDataStore.self) private var store
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var pendingCount = 0
    @State private var notifiedCount = 0
    @State private var remainingCount = 1019
    @State private var notificationTime = NotificationSchedulePreferences.scheduledTime

    private let rotationStore = DailyQuestionRotationStore.shared

    var body: some View {
        List {
            Section {
                Label {
                    Text("Todos os dias às \(NotificationSchedulePreferences.formattedTime) você recebe uma pergunta aleatória do livro.")
                } icon: {
                    Image(systemName: "bell.badge")
                        .foregroundStyle(.orange)
                }
            }

            Section("Horário") {
                DatePicker(
                    "Receber às",
                    selection: $notificationTime,
                    displayedComponents: .hourAndMinute
                )
                .onChange(of: notificationTime) { _, newValue in
                    NotificationSchedulePreferences.scheduledTime = newValue
                    Task { await applyScheduleChange() }
                }
            }

            Section("Ciclo de perguntas") {
                LabeledContent("Já notificadas no ciclo") {
                    Text("\(notifiedCount) de 1019")
                }
                LabeledContent("Restantes antes de repetir") {
                    Text("\(remainingCount)")
                }
            }

            Section("Notificações") {
                LabeledContent("Permissão") {
                    Text(statusLabel)
                        .foregroundStyle(statusColor)
                }
                LabeledContent("Agendadas (futuras)") {
                    Text("\(pendingCount)")
                }

                if authorizationStatus == .denied {
                    Button("Abrir Ajustes do sistema") {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        UIApplication.shared.open(url)
                    }
                } else if authorizationStatus == .notDetermined {
                    Button("Ativar notificações") {
                        Task { await requestAndSchedule() }
                    }
                } else {
                    Button("Atualizar agendamento") {
                        Task { await refresh() }
                    }
                }
            }
        }
        .navigationTitle("Notificações")
        .task { await reloadStatus() }
    }

    private var statusLabel: String {
        switch authorizationStatus {
        case .authorized: "Ativada"
        case .provisional: "Provisória"
        case .denied: "Negada"
        case .notDetermined: "Não definida"
        case .ephemeral: "Temporária"
        @unknown default: "Desconhecida"
        }
    }

    private var statusColor: Color {
        switch authorizationStatus {
        case .authorized, .provisional: .green
        case .denied: .red
        default: .secondary
        }
    }

    private func reloadStatus() async {
        await DailyQuestionNotificationService.syncDeliveredNotifications()

        authorizationStatus = await DailyQuestionNotificationService.authorizationStatus()
        notifiedCount = rotationStore.notifiedInCurrentCycle
        remainingCount = rotationStore.remainingCount
        notificationTime = NotificationSchedulePreferences.scheduledTime

        let pending = await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                let count = requests.filter { $0.identifier.hasPrefix(DailyQuestionNotificationService.notificationPrefix) }.count
                continuation.resume(returning: count)
            }
        }
        pendingCount = pending
    }

    private func requestAndSchedule() async {
        let granted = await DailyQuestionNotificationService.requestAuthorization()
        if granted {
            await DailyQuestionNotificationService.refreshSchedule(dataStore: store)
        }
        await reloadStatus()
    }

    private func refresh() async {
        await DailyQuestionNotificationService.refreshSchedule(dataStore: store)
        await reloadStatus()
    }

    private func applyScheduleChange() async {
        let status = await DailyQuestionNotificationService.authorizationStatus()
        guard status == .authorized || status == .provisional else {
            await reloadStatus()
            return
        }

        await DailyQuestionNotificationService.rescheduleAfterPreferenceChange(dataStore: store)
        await reloadStatus()
    }
}
