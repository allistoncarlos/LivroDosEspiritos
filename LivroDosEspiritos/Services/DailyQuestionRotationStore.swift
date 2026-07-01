import Foundation

/// Controla a rotação das 1019 perguntas sem repetição até esgotar o ciclo.
/// O contador só avança quando a notificação é de fato entregue, não ao agendar.
final class DailyQuestionRotationStore {
    static let shared = DailyQuestionRotationStore()

    private let defaults: UserDefaults
    private let notifiedKey = "dailyQuestion.notified"
    private let assignmentsKey = "dailyQuestion.assignments"
    private let storageVersionKey = "dailyQuestion.storageVersion"
    private let totalQuestions = 1019
    private let currentStorageVersion = 2

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        migrateIfNeeded()
    }

    var remainingCount: Int {
        totalQuestions - notifiedInCurrentCycle
    }

    var notifiedInCurrentCycle: Int {
        loadNotified().count
    }

    /// Pergunta atribuída a um dia específico (yyyy-MM-dd), se já existir.
    func assignedQuestion(for date: Date, calendar: Calendar = .current) -> Int? {
        assignments()[dateKey(for: date, calendar: calendar)]
    }

    /// Escolhe pergunta para agendar em um dia, sem consumir o ciclo.
    func questionForScheduling(on date: Date, calendar: Calendar = .current) -> Int {
        let key = dateKey(for: date, calendar: calendar)
        var map = assignments()

        if let existing = map[key] {
            return existing
        }

        let scheduled = Set(map.values)
        let pool = availablePoolForScheduling(excluding: scheduled)
        let picked = pool.randomElement() ?? Int.random(in: 1...totalQuestions)

        map[key] = picked
        saveAssignments(map)
        return picked
    }

    /// Registra que a pergunta foi de fato entregue ao usuário.
    func markAsNotified(_ questionNumber: Int) {
        var notified = loadNotified()
        guard !notified.contains(questionNumber) else { return }

        if notified.count >= totalQuestions {
            notified = []
        }

        notified.append(questionNumber)
        saveNotified(notified)
    }

    func clearAssignmentsBeforeToday(calendar: Calendar = .current) {
        let todayKey = dateKey(for: Date(), calendar: calendar)
        var map = assignments()
        map = map.filter { $0.key >= todayKey }
        saveAssignments(map)
    }

    // MARK: - Private

    private func migrateIfNeeded() {
        let version = defaults.integer(forKey: storageVersionKey)
        guard version < currentStorageVersion else { return }

        // Versão anterior decrementava o pool ao agendar — resetar contagem.
        defaults.removeObject(forKey: "dailyQuestion.remaining")
        if defaults.array(forKey: notifiedKey) == nil {
            defaults.set([Int](), forKey: notifiedKey)
        }

        defaults.set(currentStorageVersion, forKey: storageVersionKey)
    }

    private func availablePoolForScheduling(excluding scheduled: Set<Int>) -> [Int] {
        let notified = Set(loadNotified())
        var pool = (1...totalQuestions).filter { !notified.contains($0) }

        if pool.isEmpty {
            pool = Array(1...totalQuestions)
        }

        pool = pool.filter { !scheduled.contains($0) }

        if pool.isEmpty {
            pool = (1...totalQuestions).filter { !scheduled.contains($0) }
        }

        return pool
    }

    private func loadNotified() -> [Int] {
        defaults.array(forKey: notifiedKey) as? [Int] ?? []
    }

    private func saveNotified(_ values: [Int]) {
        defaults.set(values, forKey: notifiedKey)
    }

    private func assignments() -> [String: Int] {
        defaults.dictionary(forKey: assignmentsKey) as? [String: Int] ?? [:]
    }

    private func saveAssignments(_ map: [String: Int]) {
        defaults.set(map, forKey: assignmentsKey)
    }

    private func dateKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}
