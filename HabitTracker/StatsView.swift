import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \HTHabit.createdAt, order: .forward)
    private var habits: [HTHabit]

    @Query(sort: \HTHabitLog.date, order: .forward)
    private var allLogs: [HTHabitLog]

    @AppStorage("appearance.uiScale") private var uiScale: Double = 0.85

    private let accent = Color(red: 0.39, green: 0.88, blue: 0.28)
    private let cardFill = Color.white.opacity(0.065)
    private let stroke = Color.white.opacity(0.08)

    private var scale: CGFloat {
        CGFloat(min(max(uiScale, 0.75), 1.0))
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    var body: some View {
        ZStack {
            background

            ScrollView(showsIndicators: false) {
                VStack(spacing: scaled(14)) {
                    header
                    summaryCard
                    weekProgressCard

                    HStack(spacing: scaled(12)) {
                        weeklyBarCard
                        categoryCard
                    }

                    topHabitsCard
                    encouragementCard
                }
                .padding(.horizontal, scaled(16))
                .padding(.top, scaled(18))
                .padding(.bottom, scaled(28))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
    }

    private var background: some View {
        ZStack {
            Color(red: 0.01, green: 0.03, blue: 0.035)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.green.opacity(0.10),
                    Color.clear,
                    Color.blue.opacity(0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: scaled(6)) {
                Text("Estatísticas")
                    .font(.system(size: scaled(34), weight: .bold))
                    .foregroundStyle(.white)

                Text("Acompanhe seu progresso e veja seu jardim florescer.")
                    .font(.system(size: scaled(16), weight: .medium))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "calendar")
                .font(.system(size: scaled(21), weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: scaled(52), height: scaled(52))
                .background(Circle().fill(Color.white.opacity(0.06)))
                .overlay(Circle().strokeBorder(stroke, lineWidth: 1))
        }
    }

    private var summaryCard: some View {
        HStack(spacing: scaled(14)) {
            VStack(alignment: .leading, spacing: scaled(12)) {
                Text("Sequência atual")
                    .font(.system(size: scaled(14), weight: .semibold))
                    .foregroundStyle(.white.opacity(0.68))

                HStack(alignment: .firstTextBaseline, spacing: scaled(8)) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: scaled(30), weight: .bold))
                        .foregroundStyle(Color(red: 1.0, green: 0.46, blue: 0.14))

                    Text("\(currentStreak)")
                        .font(.system(size: scaled(40), weight: .bold))
                        .foregroundStyle(accent)

                    Text("dias")
                        .font(.system(size: scaled(17), weight: .bold))
                        .foregroundStyle(.white)
                }

                Text("Melhor sequência: \(bestStreak) dias")
                    .font(.system(size: scaled(14), weight: .medium))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1, height: scaled(86))

            VStack(alignment: .leading, spacing: scaled(12)) {
                Text("Total de hábitos concluídos")
                    .font(.system(size: scaled(14), weight: .semibold))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(1)

                HStack(spacing: scaled(9)) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: scaled(30), weight: .bold))
                        .foregroundStyle(accent)

                    Text("\(allLogs.count)")
                        .font(.system(size: scaled(40), weight: .bold))
                        .foregroundStyle(accent)
                }

                Text("Este mês: \(logsThisMonth)")
                    .font(.system(size: scaled(14), weight: .medium))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            decorativeGarden
        }
        .padding(scaled(18))
        .frame(minHeight: scaled(148))
        .background(summaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(cardStroke(22))
    }

    private var decorativeGarden: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.16))
                .frame(width: scaled(82), height: scaled(82))
                .blur(radius: 1)

            VStack(spacing: -scaled(5)) {
                Image(systemName: "tree.fill")
                    .font(.system(size: scaled(44), weight: .bold))
                    .foregroundStyle(accent)

                Capsule()
                    .fill(Color(red: 0.19, green: 0.28, blue: 0.14))
                    .frame(width: scaled(88), height: scaled(18))
            }
        }
        .frame(width: scaled(108))
    }

    private var weekProgressCard: some View {
        VStack(alignment: .leading, spacing: scaled(18)) {
            HStack {
                Text("Seu progresso esta semana")
                    .font(.system(size: scaled(18), weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                legendDot(color: accent, text: "Concluído")
                legendDot(color: Color.white.opacity(0.14), text: "Pendente")
            }

            HStack(spacing: 0) {
                ForEach(weekItems) { item in
                    VStack(spacing: scaled(10)) {
                        Text(item.shortLabel)
                            .font(.system(size: scaled(13), weight: .semibold))
                            .foregroundStyle(.white.opacity(0.62))

                        dayStatusCircle(item)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(scaled(18))
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(cardStroke(22))
    }

    private var weeklyBarCard: some View {
        VStack(alignment: .leading, spacing: scaled(10)) {
            Text("Hábitos concluídos")
                .font(.system(size: scaled(18), weight: .bold))
                .foregroundStyle(.white)

            Text("Últimos 7 dias")
                .font(.system(size: scaled(14), weight: .medium))
                .foregroundStyle(.white.opacity(0.62))

            BarChartView(values: weekItems.map(\.count), labels: weekItems.map(\.shortLabel), scale: scale, accent: accent)
                .frame(height: scaled(178))
        }
        .padding(scaled(16))
        .frame(maxWidth: .infinity)
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(cardStroke(22))
    }

    private var categoryCard: some View {
        let categories = categoryItems

        return VStack(alignment: .leading, spacing: scaled(10)) {
            Text("Distribuição de hábitos")
                .font(.system(size: scaled(18), weight: .bold))
                .foregroundStyle(.white)

            Text("Por categoria")
                .font(.system(size: scaled(14), weight: .medium))
                .foregroundStyle(.white.opacity(0.62))

            HStack(spacing: scaled(14)) {
                DonutChartView(items: categories, total: categoryTotal, scale: scale)
                    .frame(width: scaled(112), height: scaled(112))

                VStack(spacing: scaled(12)) {
                    ForEach(categories) { item in
                        HStack(spacing: scaled(8)) {
                            Circle()
                                .fill(item.color)
                                .frame(width: scaled(10), height: scaled(10))

                            Text(item.title)
                                .font(.system(size: scaled(12), weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.74)

                            Spacer()

                            Text("\(item.value)")
                                .font(.system(size: scaled(12), weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .padding(.top, scaled(6))
        }
        .padding(scaled(16))
        .frame(maxWidth: .infinity)
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(cardStroke(22))
    }

    private var topHabitsCard: some View {
        VStack(alignment: .leading, spacing: scaled(8)) {
            Text("Hábitos mais concluídos")
                .font(.system(size: scaled(19), weight: .bold))
                .foregroundStyle(.white)

            Text("Últimos 7 dias")
                .font(.system(size: scaled(14), weight: .medium))
                .foregroundStyle(.white.opacity(0.62))

            VStack(spacing: 0) {
                ForEach(Array(topHabitItems.enumerated()), id: \.element.id) { index, item in
                    topHabitRow(item)

                    if index < topHabitItems.count - 1 {
                        Rectangle()
                            .fill(Color.white.opacity(0.07))
                            .frame(height: 1)
                            .padding(.leading, scaled(58))
                    }
                }
            }
            .padding(.top, scaled(6))
        }
        .padding(scaled(16))
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(cardStroke(22))
    }

    private var encouragementCard: some View {
        HStack(spacing: scaled(16)) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(accent.opacity(0.13))
                    .frame(width: scaled(78), height: scaled(78))

                Image(systemName: "leaf.fill")
                    .font(.system(size: scaled(36), weight: .bold))
                    .foregroundStyle(accent)
            }

            VStack(alignment: .leading, spacing: scaled(6)) {
                Text("Continue assim!")
                    .font(.system(size: scaled(18), weight: .bold))
                    .foregroundStyle(.white)

                Text("Você está indo muito bem. Pequenas ações todos os dias geram grandes transformações.")
                    .font(.system(size: scaled(14), weight: .medium))
                    .foregroundStyle(.white.opacity(0.64))
                    .lineLimit(3)
            }

            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: scaled(23), weight: .semibold))
                .foregroundStyle(accent.opacity(0.75))
        }
        .padding(scaled(16))
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(cardStroke(22))
    }

    private func topHabitRow(_ item: TopHabitItem) -> some View {
        HStack(spacing: scaled(14)) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(item.color.opacity(0.22))
                    .frame(width: scaled(44), height: scaled(44))

                Image(systemName: item.icon)
                    .font(.system(size: scaled(20), weight: .bold))
                    .foregroundStyle(item.color)
            }

            Text(item.title)
                .font(.system(size: scaled(16), weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))

                    Capsule()
                        .fill(accent)
                        .frame(width: geo.size.width * item.progress)
                }
            }
            .frame(height: scaled(6))

            Text("\(item.completed)/7")
                .font(.system(size: scaled(19), weight: .bold))
                .foregroundStyle(accent)
                .frame(width: scaled(42), alignment: .trailing)

            Image(systemName: "chevron.right")
                .font(.system(size: scaled(14), weight: .bold))
                .foregroundStyle(.white.opacity(0.42))
        }
        .padding(.vertical, scaled(11))
    }

    private func legendDot(color: Color, text: String) -> some View {
        HStack(spacing: scaled(6)) {
            Circle()
                .fill(color)
                .frame(width: scaled(10), height: scaled(10))

            Text(text)
                .font(.system(size: scaled(12), weight: .medium))
                .foregroundStyle(.white.opacity(0.66))
        }
    }

    private func dayStatusCircle(_ item: WeekItem) -> some View {
        ZStack {
            if item.date > startOfToday {
                Circle()
                    .strokeBorder(Color.white.opacity(0.28), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .frame(width: scaled(42), height: scaled(42))
            } else {
                Circle()
                    .fill(item.count > 0 ? accent : Color.white.opacity(0.12))
                    .frame(width: scaled(42), height: scaled(42))
            }

            if item.count > 0 {
                Image(systemName: "checkmark")
                    .font(.system(size: scaled(20), weight: .bold))
                    .foregroundStyle(.white)
            } else if item.date <= startOfToday {
                Image(systemName: "minus")
                    .font(.system(size: scaled(16), weight: .bold))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
    }

    private var summaryBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.16, blue: 0.10),
                    Color.white.opacity(0.05),
                    Color.black.opacity(0.34)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    Color.clear,
                    accent.opacity(0.08)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    private func cardStroke(_ radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .strokeBorder(stroke, lineWidth: 1)
    }
}

// MARK: - Calculations

private extension StatsView {
    var calendar: Calendar { Calendar.current }

    var startOfToday: Date {
        calendar.startOfDay(for: .now)
    }

    var completedDays: Set<Date> {
        Set(allLogs.map { calendar.startOfDay(for: $0.date) })
    }

    var weekItems: [WeekItem] {
        let start = calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday

        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: start) ?? start
            let day = calendar.startOfDay(for: date)
            let count = allLogs.filter { calendar.isDate($0.date, inSameDayAs: day) }.count
            return WeekItem(date: day, shortLabel: shortWeekday(for: day), count: count)
        }
    }

    var currentStreak: Int {
        var streak = 0
        var cursor = startOfToday

        while completedDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }

        return streak
    }

    var bestStreak: Int {
        let days = completedDays.sorted()
        guard !days.isEmpty else { return 0 }

        var best = 1
        var current = 1

        for index in 1..<days.count {
            let previous = days[index - 1]
            let expected = calendar.date(byAdding: .day, value: 1, to: previous).map { calendar.startOfDay(for: $0) }

            if expected == days[index] {
                current += 1
            } else {
                best = max(best, current)
                current = 1
            }
        }

        return max(best, current)
    }

    var logsThisMonth: Int {
        guard let month = calendar.dateInterval(of: .month, for: .now) else { return 0 }
        return allLogs.filter { month.contains($0.date) }.count
    }

    var categoryItems: [CategoryItem] {
        let colors: [Color] = [
            Color(red: 0.24, green: 0.78, blue: 0.22),
            Color(red: 0.24, green: 0.58, blue: 1.0),
            Color(red: 0.62, green: 0.35, blue: 0.78),
            Color(red: 1.0, green: 0.57, blue: 0.08)
        ]

        let titles = ["Saúde", "Produtividade", "Mente", "Outros"]
        var counts = [0, 0, 0, 0]

        for habit in habits {
            counts[categoryIndex(for: habit)] += 1
        }

        return titles.enumerated().map { index, title in
            CategoryItem(id: title, title: title, value: counts[index], color: colors[index])
        }
    }

    var categoryTotal: Int {
        max(categoryItems.map(\.value).reduce(0, +), 1)
    }

    var topHabitItems: [TopHabitItem] {
        let start = calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday
        let interval = DateInterval(start: start, end: calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? .now)

        let items = habits.map { habit in
            let id = habit.persistentModelID
            let count = allLogs.filter {
                $0.habit.persistentModelID == id && interval.contains($0.date)
            }.count
            let completed = min(count, 7)

            return TopHabitItem(
                id: String(describing: id),
                title: habit.name,
                icon: habit.iconName,
                color: Color(hex: habit.colorHex),
                completed: completed
            )
        }
        .sorted { lhs, rhs in
            if lhs.completed == rhs.completed { return lhs.title < rhs.title }
            return lhs.completed > rhs.completed
        }

        if items.isEmpty {
            return [
                TopHabitItem(id: "empty-1", title: "Crie um hábito", icon: "leaf.fill", color: accent, completed: 0)
            ]
        }

        return Array(items.prefix(4))
    }

    func categoryIndex(for habit: HTHabit) -> Int {
        let text = "\(habit.name) \(habit.detailText) \(habit.iconName)".lowercased()

        if text.contains("walk") || text.contains("dumbbell") || text.contains("drop") || text.contains("agua") || text.contains("água") || text.contains("saúde") || text.contains("academia") {
            return 0
        }

        if text.contains("book") || text.contains("timer") || text.contains("produt") || text.contains("ler") || text.contains("estud") {
            return 1
        }

        if text.contains("brain") || text.contains("music") || text.contains("mente") || text.contains("meditar") || text.contains("medita") {
            return 2
        }

        return 3
    }

    func shortWeekday(for date: Date) -> String {
        switch calendar.component(.weekday, from: date) {
        case 1: return "Dom"
        case 2: return "Seg"
        case 3: return "Ter"
        case 4: return "Qua"
        case 5: return "Qui"
        case 6: return "Sex"
        case 7: return "Sáb"
        default: return ""
        }
    }
}

private struct WeekItem: Identifiable {
    var id: Date { date }
    let date: Date
    let shortLabel: String
    let count: Int
}

private struct CategoryItem: Identifiable {
    let id: String
    let title: String
    let value: Int
    let color: Color
}

private struct TopHabitItem: Identifiable {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let completed: Int

    var progress: CGFloat {
        CGFloat(min(max(Double(completed) / 7.0, 0), 1))
    }
}

private struct BarChartView: View {
    let values: [Int]
    let labels: [String]
    let scale: CGFloat
    let accent: Color

    private var maxValue: Int {
        max(values.max() ?? 1, 1)
    }

    var body: some View {
        GeometryReader { geo in
            let chartHeight = geo.size.height - 28 * scale
            let barWidth = max((geo.size.width / CGFloat(max(values.count, 1))) * 0.52, 8)

            HStack(alignment: .bottom, spacing: 0) {
                ForEach(values.indices, id: \.self) { index in
                    VStack(spacing: 8 * scale) {
                        ZStack(alignment: .bottom) {
                            Rectangle()
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 1, height: chartHeight)

                            RoundedRectangle(cornerRadius: 4 * scale, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [accent, accent.opacity(0.72)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(
                                    width: barWidth,
                                    height: max(CGFloat(values[index]) / CGFloat(maxValue) * chartHeight, values[index] == 0 ? 0 : 8)
                                )
                        }

                        Text(labels[index])
                            .font(.system(size: 10 * scale, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.white.opacity(0.10))
                    .frame(height: 1)
                    .padding(.bottom, 24 * scale)
            }
        }
    }
}

private struct DonutChartView: View {
    let items: [CategoryItem]
    let total: Int
    let scale: CGFloat

    var body: some View {
        ZStack {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                Circle()
                    .trim(from: startTrim(for: index), to: endTrim(for: index))
                    .stroke(item.value == 0 ? Color.clear : item.color, style: StrokeStyle(lineWidth: 24 * scale, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }

            Circle()
                .fill(Color.black.opacity(0.26))
                .frame(width: 58 * scale, height: 58 * scale)

            VStack(spacing: 0) {
                Text("\(max(total, 0))")
                    .font(.system(size: 22 * scale, weight: .bold))
                    .foregroundStyle(.white)

                Text("hábitos")
                    .font(.system(size: 10 * scale, weight: .bold))
                    .foregroundStyle(.white.opacity(0.82))
            }
        }
    }

    private func startTrim(for index: Int) -> CGFloat {
        guard total > 0 else { return 0 }
        let previous = items.prefix(index).map(\.value).reduce(0, +)
        return CGFloat(previous) / CGFloat(total)
    }

    private func endTrim(for index: Int) -> CGFloat {
        guard total > 0 else { return 0 }
        let through = items.prefix(index + 1).map(\.value).reduce(0, +)
        return CGFloat(through) / CGFloat(total)
    }
}
