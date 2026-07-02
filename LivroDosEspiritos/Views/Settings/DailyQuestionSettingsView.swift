import SwiftUI
import UserNotifications

@Observable
final class NotificationTimeDraft {
    var pickerTime: Date
    private(set) var formattedPreview: String

    init() {
        let saved = NotificationSchedulePreferences.scheduledTime
        pickerTime = saved
        formattedPreview = NotificationSchedulePreferences.formattedTime(from: saved)
    }

    func setPickerTime(_ date: Date) {
        pickerTime = date
        formattedPreview = NotificationSchedulePreferences.formattedTime(from: date)
    }

    func reloadFromSaved() {
        setPickerTime(NotificationSchedulePreferences.scheduledTime)
    }
}

struct DailyQuestionSettingsView: View {
    @Environment(BookDataStore.self) private var store
    @State private var timeDraft = NotificationTimeDraft()
    @State private var authorizationStatus: UNAuthorizationStatus?
    @State private var pendingCount: Int?
    @State private var notifiedCount = DailyQuestionRotationStore.shared.notifiedInCurrentCycle
    @State private var remainingCount = DailyQuestionRotationStore.shared.remainingCount
    @State private var toastMessage: String?
    @State private var toastDismissTask: Task<Void, Never>?

    private let rotationStore = DailyQuestionRotationStore.shared

    var body: some View {
        List {
            Section {
                NotificationTimeDescription(draft: timeDraft)
            }

            Section("Horário") {
                NotificationTimePicker(draft: timeDraft)
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
                    if let authorizationStatus {
                        Text(statusLabel(for: authorizationStatus))
                            .foregroundStyle(statusColor(for: authorizationStatus))
                    } else {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                LabeledContent("Agendadas (futuras)") {
                    if let pendingCount {
                        Text("\(pendingCount)")
                    } else {
                        Text("—")
                            .foregroundStyle(.secondary)
                    }
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
                } else if authorizationStatus != nil {
                    Button("Atualizar agendamento") {
                        Task { await saveAndRefreshSchedule() }
                    }
                }
            }
        }
        .navigationTitle("Notificações")
        .overlay(alignment: .bottom) {
            if let toastMessage {
                Text(toastMessage)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.regularMaterial, in: Capsule())
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: toastMessage)
        .task(priority: .background) {
            authorizationStatus = await DailyQuestionNotificationService.authorizationStatus()
        }
        .task(priority: .background) {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            await reloadHeavyStatus()
        }
    }

    private func statusLabel(for status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized: "Ativada"
        case .provisional: "Provisória"
        case .denied: "Negada"
        case .notDetermined: "Não definida"
        case .ephemeral: "Temporária"
        @unknown default: "Desconhecida"
        }
    }

    private func statusColor(for status: UNAuthorizationStatus) -> Color {
        switch status {
        case .authorized, .provisional: .green
        case .denied: .red
        default: .secondary
        }
    }

    private func reloadHeavyStatus() async {
        await DailyQuestionNotificationService.syncDeliveredNotifications()

        let pending = await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                let count = requests.filter {
                    $0.identifier.hasPrefix(DailyQuestionNotificationService.notificationPrefix)
                }.count
                continuation.resume(returning: count)
            }
        }

        await MainActor.run {
            pendingCount = pending
            notifiedCount = rotationStore.notifiedInCurrentCycle
            remainingCount = rotationStore.remainingCount
        }
    }

    private func requestAndSchedule() async {
        let granted = await DailyQuestionNotificationService.requestAuthorization()
        await MainActor.run {
            authorizationStatus = granted ? .authorized : .denied
        }
        guard granted else { return }

        await saveAndRefreshSchedule()
    }

    private func saveAndRefreshSchedule() async {
        NotificationSchedulePreferences.scheduledTime = timeDraft.pickerTime
        await DailyQuestionNotificationService.rescheduleAfterPreferenceChange(dataStore: store)
        await reloadHeavyStatus()
        showToast("Agendamento atualizado")
    }

    private func showToast(_ message: String) {
        toastMessage = message
        toastDismissTask?.cancel()
        toastDismissTask = Task {
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if toastMessage == message {
                    toastMessage = nil
                }
            }
        }
    }
}

private struct NotificationTimeDescription: View {
    @Bindable var draft: NotificationTimeDraft

    var body: some View {
        Label {
            Text("Todos os dias às \(draft.formattedPreview) você recebe uma pergunta aleatória do livro.")
        } icon: {
            Image(systemName: "bell.badge")
                .foregroundStyle(.orange)
        }
    }
}

private struct NotificationTimePicker: View {
    let draft: NotificationTimeDraft
    @State private var pickerTime: Date

    init(draft: NotificationTimeDraft) {
        self.draft = draft
        _pickerTime = State(initialValue: draft.pickerTime)
    }

    var body: some View {
        DatePicker(
            "Receber às",
            selection: $pickerTime,
            displayedComponents: .hourAndMinute
        )
        .transaction { transaction in
            transaction.animation = nil
        }
        .onChange(of: pickerTime) { _, newValue in
            draft.setPickerTime(newValue)
        }
        .onChange(of: draft.pickerTime) { _, newValue in
            guard pickerTime != newValue else { return }
            pickerTime = newValue
        }
    }
}
