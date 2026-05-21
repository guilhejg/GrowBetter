import SwiftUI

struct HTHeatmapView: View {
    let color: Color
    let completedDays: Set<Date>
    let weeks: Int
    let mostRecentFirst: Bool

    /// ✅ Novo: ancora a grade em uma data específica (Stats usa 31/12 do ano)
    var endDate: Date = .now

    /// ✅ Novo: alinha a grade por semana (Stats precisa disso)
    var alignToWeek: Bool = false

    private let cell: CGFloat = 8
    private let spacing: CGFloat = 4

    var body: some View {
        let columns = makeColumns()

        return HStack(alignment: .top, spacing: spacing) {
            ForEach(Array(columns.enumerated()), id: \.offset) { _, col in
                VStack(spacing: spacing) {
                    ForEach(col, id: \.self) { day in
                        let done = completedDays.contains(day)

                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(done ? color.opacity(0.75) : Color.white.opacity(0.12))
                            .frame(width: cell, height: cell)
                    }
                }
            }
        }
        .padding(.top, 2)
    }

    private func makeColumns() -> [[Date]] {
        let w = max(weeks, 1)
        let totalDays = w * 7
        let cal = Calendar.current

        let end = cal.startOfDay(for: endDate)

        // ✅ START: ou “puro” (packed) ou alinhado por semana (calendar)
        let start: Date = {
            if alignToWeek {
                // Alinha o END no começo da semana e volta totalDays-1
                let alignedEnd = startOfWeek(for: end, cal: cal)
                return cal.date(byAdding: .day, value: -(totalDays - 1), to: alignedEnd) ?? alignedEnd
            } else {
                return cal.date(byAdding: .day, value: -(totalDays - 1), to: end) ?? end
            }
        }()

        // lista de dias (oldest -> newest)
        var allDays: [Date] = (0..<totalDays).map { i in
            let d = cal.date(byAdding: .day, value: i, to: start) ?? start
            return cal.startOfDay(for: d)
        }

        // ✅ FIX DO HOME:
        // Se mostRecentFirst, inverter os dias ANTES de quebrar em colunas
        // Isso faz “hoje” cair no topo esquerdo.
        if mostRecentFirst && !alignToWeek {
            allDays.reverse()
        }

        // monta colunas
        var cols: [[Date]] = []
        cols.reserveCapacity(w)

        for weekIndex in 0..<w {
            let base = weekIndex * 7
            let col = (0..<7).map { offset in
                allDays[base + offset]
            }
            cols.append(col)
        }

        // ✅ Para o modo calendar (alignToWeek), o mostRecentFirst deve inverter colunas
        if alignToWeek && mostRecentFirst {
            return cols.reversed()
        }

        return cols
    }

    private func startOfWeek(for date: Date, cal: Calendar) -> Date {
        // start of week (depende da locale do usuário, o que é ok)
        if let interval = cal.dateInterval(of: .weekOfYear, for: date) {
            return interval.start
        }
        return cal.startOfDay(for: date)
    }
}
