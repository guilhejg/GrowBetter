// StatsEngine.swift
import Foundation
import SwiftData

struct MonthPoint: Identifiable, Equatable {
    let id = UUID()
    let monthIndex: Int  // 1...12
    let count: Int
}

enum StatsEngine {

    // MARK: - Filtering

    static func logsForHabit(_ habit: HTHabit?, allLogs: [HTHabitLog]) -> [HTHabitLog] {
        // ✅ Geral = todos os logs
        guard let habit else { return allLogs }
        let hid = habit.persistentModelID
        return allLogs.filter { $0.habit.persistentModelID == hid }
    }

    static func logsInYear(_ year: Int, from logs: [HTHabitLog]) -> [HTHabitLog] {
        let cal = Calendar.current
        guard
            let start = cal.date(from: DateComponents(year: year, month: 1, day: 1)),
            let end = cal.date(from: DateComponents(year: year + 1, month: 1, day: 1))
        else { return logs }

        return logs.filter { $0.date >= start && $0.date < end }
    }

    static func completedDaysSet(from logs: [HTHabitLog]) -> Set<Date> {
        let cal = Calendar.current
        return Set(logs.map { cal.startOfDay(for: $0.date) })
    }

    // MARK: - Streak

    static func currentStreak(from logs: [HTHabitLog]) -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        let days = Set(logs.map { cal.startOfDay(for: $0.date) })
        guard !days.isEmpty else { return 0 }

        var streak = 0
        var cursor = today
        while days.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    // MARK: - Best day of week

    static func bestDayOfWeek(inYear year: Int, logs: [HTHabitLog]) -> String {
        let cal = Calendar.current
        let filtered = logsInYear(year, from: logs)

        var counts: [Int: Int] = [:]
        for log in filtered {
            let w = cal.component(.weekday, from: log.date) // 1..7
            counts[w, default: 0] += 1
        }
        guard let best = counts.max(by: { $0.value < $1.value })?.key else { return "-" }

        switch best {
        case 1: return "Dom"
        case 2: return "Seg"
        case 3: return "Ter"
        case 4: return "Qua"
        case 5: return "Qui"
        case 6: return "Sex"
        case 7: return "Sáb"
        default: return "-"
        }
    }

    // MARK: - Month chart

    static func completionsPerMonth(inYear year: Int, logs: [HTHabitLog]) -> [MonthPoint] {
        let cal = Calendar.current
        let filtered = logsInYear(year, from: logs)

        var counts = Array(repeating: 0, count: 12)
        for log in filtered {
            let m = cal.component(.month, from: log.date) // 1..12
            if (1...12).contains(m) { counts[m - 1] += 1 }
        }

        return (1...12).map { MonthPoint(monthIndex: $0, count: counts[$0 - 1]) }
    }

    static func monthAbbrev(_ i: Int) -> String {
        switch i {
        case 1: return "Jan"
        case 2: return "Fev"
        case 3: return "Mar"
        case 4: return "Abr"
        case 5: return "Mai"
        case 6: return "Jun"
        case 7: return "Jul"
        case 8: return "Ago"
        case 9: return "Set"
        case 10: return "Out"
        case 11: return "Nov"
        case 12: return "Dez"
        default: return ""
        }
    }
}
