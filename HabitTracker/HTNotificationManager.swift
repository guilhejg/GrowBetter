import Foundation
import UserNotifications
import Combine
import SwiftUI
@MainActor
final class HTNotificationManager: ObservableObject {

    static let shared = HTNotificationManager()

    // Persistência simples
    private let enabledKey = "ht.notifications.enabled"
    private let timesKey = "ht.notifications.times" // ["06:00", "12:00", ...]

    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: enabledKey) }
    }

    /// Horários do dia (somente hora/minuto importam)
    @Published var times: [Date] {
        didSet { persistTimes() }
    }

    private init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: enabledKey)
        self.times = Self.loadTimes(from: UserDefaults.standard.array(forKey: timesKey) as? [String] ?? [])
            .sorted(by: { Self.hm($0) < Self.hm($1) })
    }

    // MARK: - Public API

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("requestAuthorization error:", error)
            return false
        }
    }

    func refreshAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    func applyScheduling() async {
        let center = UNUserNotificationCenter.current()

        // sempre limpa as antigas do app
        center.removePendingNotificationRequests(withIdentifiers: scheduledIdentifiers())

        guard isEnabled else { return }

        let status = await refreshAuthorizationStatus()
        guard status == .authorized || status == .provisional else { return }

        // agenda uma notificação por horário
        for (idx, t) in times.sorted(by: { Self.hm($0) < Self.hm($1) }).enumerated() {
            scheduleDailyReminder(at: t, index: idx)
        }
    }

    func addTime(_ date: Date) {
        times.append(date)
        times = normalizeSortAndUnique(times)
    }

    func updateTime(at index: Int, to newValue: Date) {
        guard times.indices.contains(index) else { return }
        times[index] = newValue
        times = normalizeSortAndUnique(times)
    }

    func removeTime(at offsets: IndexSet) {
        times.remove(atOffsets: offsets)
        times = normalizeSortAndUnique(times)
    }

    // MARK: - Scheduling

    private func scheduleDailyReminder(at date: Date, index: Int) {
        let center = UNUserNotificationCenter.current()

        var comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        comps.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "Lembrete de hábitos"
        content.body = "Marque seus hábitos de hoje no HabitTracker."
        content.sound = .default

        let id = "ht.daily.reminder.\(index)"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        center.add(request) { error in
            if let error { print("schedule error:", error) }
        }
    }

    private func scheduledIdentifiers() -> [String] {
        // gera ids estáveis com base em índices
        // (toda vez que aplicar, apagamos os anteriores)
        return (0..<max(times.count, 16)).map { "ht.daily.reminder.\($0)" }
    }

    // MARK: - Persistence helpers

    private func persistTimes() {
        let strings = times.map { Self.timeString($0) }
        UserDefaults.standard.set(strings, forKey: timesKey)
    }

    private static func loadTimes(from strings: [String]) -> [Date] {
        let cal = Calendar.current
        let now = Date()

        return strings.compactMap { s in
            let parts = s.split(separator: ":").map(String.init)
            guard parts.count == 2,
                  let h = Int(parts[0]),
                  let m = Int(parts[1]) else { return nil }

            return cal.date(bySettingHour: h, minute: m, second: 0, of: now)
        }
    }

    private func normalizeSortAndUnique(_ input: [Date]) -> [Date] {
        // normaliza por (hour, minute) e remove duplicados
        var seen = Set<String>()
        let sorted = input
            .map { Self.normalizeToToday($0) }
            .sorted(by: { Self.hm($0) < Self.hm($1) })

        var out: [Date] = []
        for d in sorted {
            let key = Self.timeString(d)
            if !seen.contains(key) {
                seen.insert(key)
                out.append(d)
            }
        }
        return out
    }

    private static func normalizeToToday(_ date: Date) -> Date {
        let cal = Calendar.current
        let hm = cal.dateComponents([.hour, .minute], from: date)
        return cal.date(bySettingHour: hm.hour ?? 0, minute: hm.minute ?? 0, second: 0, of: Date()) ?? date
    }

    private static func timeString(_ date: Date) -> String {
        let cal = Calendar.current
        let h = cal.component(.hour, from: date)
        let m = cal.component(.minute, from: date)
        return String(format: "%02d:%02d", h, m)
    }

    private static func hm(_ date: Date) -> Int {
        let cal = Calendar.current
        return cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date)
    }
}
