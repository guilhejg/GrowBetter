import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    // MARK: - Data
    @Query(sort: \HTHabit.createdAt, order: .forward)
    private var habits: [HTHabit]

    @Query(sort: \HTHabitLog.date, order: .forward)
    private var allLogs: [HTHabitLog]

    // MARK: - Selection
    /// nil = Geral
    @State private var selectedHabitID: PersistentIdentifier? = nil
    @State private var selectedYear: Int = Calendar.current.component(.year, from: .now)

    // MARK: - Geral (persistente)
    @AppStorage("stats.general.title") private var generalTitle: String = "Geral"
    @AppStorage("stats.general.detail") private var generalDetail: String = "Resumo de todos os hábitos"

    @State private var showingEditGeneral = false
    @State private var tempGeneralTitle = ""
    @State private var tempGeneralDetail = ""

    // MARK: - Palette
    private let bg = Color.black
    private let card = Color.white.opacity(0.10)
    private let stroke = Color.white.opacity(0.06)
    private let primaryText = Color.white
    private let secondaryText = Color.white.opacity(0.70)
    private let tertiaryText = Color.white.opacity(0.30)

    /// Cinza do "Geral"
    private let geralAccent = Color.white.opacity(0.55)

    var body: some View {
        let habit = resolvedSelectedHabit()

        // Accent: hábito selecionado ou cinza do geral
        let accent: Color = (habit != nil) ? Color(hex: habit!.colorHex) : geralAccent

        // Logs: se Geral, usa todos; se hábito, filtra por ele
        let logs: [HTHabitLog] = {
            if let habit {
                return StatsEngine.logsForHabit(habit, allLogs: allLogs)
            } else {
                return allLogs
            }
        }()

        // Recortes por ano
        let yearLogs = StatsEngine.logsInYear(selectedYear, from: logs)
        let completedDays = StatsEngine.completedDaysSet(from: yearLogs)

        // Métricas
        let completionsCount = yearLogs.count
        let streak = StatsEngine.currentStreak(from: logs)
        let bestDay = StatsEngine.bestDayOfWeek(inYear: selectedYear, logs: logs)
        let perMonth = StatsEngine.completionsPerMonth(inYear: selectedYear, logs: logs)

        ZStack {
            bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    Color.clear.frame(height: 10)

                    habitSelectorRow(accent: accent)

                    habitHeaderCard(habit: habit, accent: accent)

                    yearSelectorRow

                    heatmapCard(completedDays: completedDays)

                    statsCardsRow(
                        completions: completionsCount,
                        streak: streak,
                        bestDay: bestDay
                    )

                    completionsPerMonthCard(accentForCharts: accent, data: perMonth)

                    Spacer(minLength: 28)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert("Editar Geral", isPresented: $showingEditGeneral) {
            TextField("Título", text: $tempGeneralTitle)
            TextField("Descrição", text: $tempGeneralDetail)

            Button("Salvar") {
                let t = tempGeneralTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                let d = tempGeneralDetail.trimmingCharacters(in: .whitespacesAndNewlines)

                generalTitle = t.isEmpty ? "Geral" : t
                generalDetail = d
            }

            Button("Cancelar", role: .cancel) {}
        }
    }

    // MARK: - Habit Selector (Geral + bolinhas)

    private func habitSelectorRow(accent: Color) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {

                // ✅ Botão Geral
                Button {
                    selectedHabitID = nil
                } label: {
                    let isSelected = (selectedHabitID == nil)

                    HStack(spacing: 8) {
                        Circle()
                            .fill(isSelected ? Color.black.opacity(0.65) : Color.white.opacity(0.35))
                            .frame(width: 10, height: 10)

                        Text("Geral")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(isSelected ? 0.95 : 0.85))
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .background(
                        Capsule().fill(isSelected ? geralAccent.opacity(0.35) : Color.white.opacity(0.10)) // COR DO BOTÃO GERAL 🙏
                    )
                }
                .buttonStyle(.plain)

                // ✅ Bolinhas dos hábitos
                ForEach(habits, id: \.persistentModelID) { h in
                    let isSelected = h.persistentModelID == selectedHabitID
                    let hAccent = Color(hex: h.colorHex)

                    Button {
                        selectedHabitID = h.persistentModelID
                    } label: {
                        ZStack {
                            Circle()
                                .fill(isSelected ? hAccent.opacity(0.95) : Color.white.opacity(0.10))
                                .frame(width: 44, height: 44)

                            Image(systemName: h.iconName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(isSelected ? Color.black.opacity(0.85) : Color.white.opacity(0.80))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Header Card

    private func habitHeaderCard(habit: HTHabit?, accent: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.20))
                Image(systemName: habit?.iconName ?? "chart.bar.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.95))
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(habit?.name ?? generalTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(primaryText)
                    .lineLimit(1)

                Text(
                    habit != nil
                    ? ((habit!.detailText.isEmpty == false) ? habit!.detailText : " ")
                    : (generalDetail.isEmpty ? " " : generalDetail)
                )
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.80))
                .lineLimit(1)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(accent.opacity(0.22))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(accent.opacity(0.22), lineWidth: 1)
        )
        .onTapGesture {
            guard habit == nil else { return }
            tempGeneralTitle = generalTitle
            tempGeneralDetail = generalDetail
            showingEditGeneral = true
        }
    }

    // MARK: - Year Selector

    private var yearSelectorRow: some View {
        HStack(spacing: 10) {
            Button { selectedYear -= 1 } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(primaryText.opacity(0.85))
                    .frame(width: 44, height: 44)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.10)))
            }
            .buttonStyle(.plain)

            Spacer()

            Text(String(selectedYear))
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(primaryText.opacity(0.9))

            Spacer()

            Button { selectedYear += 1 } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(primaryText.opacity(0.85))
                    .frame(width: 44, height: 44)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.10)))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 2)
    }

    // MARK: - Heatmap Card

    private func heatmapCard(completedDays: Set<Date>) -> some View {
        let cal = Calendar.current
        let endOfYear = cal.date(from: DateComponents(year: selectedYear, month: 12, day: 31)) ?? .now

        return VStack(alignment: .leading, spacing: 10) {
            monthLabelRow

            // ✅ precisa existir UM FitHeatmap no projeto (arquivo FitHeatmap.swift)
            FitHeatmap(
                color: Color.white.opacity(0.75),
                completedDays: completedDays,
                weeks: 52,
                endDate: endOfYear,
                alignToWeek: true,
                mostRecentFirst: false
            )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var monthLabelRow: some View {
        let months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        return HStack {
            ForEach(months, id: \.self) { m in
                Text(m)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(tertiaryText)
                Spacer()
            }
        }
        .padding(.horizontal, 2)
    }

    // MARK: - Stats Cards

    private func statsCardsRow(completions: Int, streak: Int, bestDay: String) -> some View {
        HStack(spacing: 12) {
            statCard(title: "Completions", value: "\(completions)", icon: "number")
            statCard(title: "Streak", value: "\(streak)", icon: "flame.fill")
            statCard(title: "Best Day", value: bestDay, icon: "calendar")
        }
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.10))
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.75))
                }
                .frame(width: 34, height: 34)
            }

            Text(value)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(secondaryText)

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .frame(height: 130)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(stroke, lineWidth: 1)
        )
    }

    // MARK: - Completions / Month

    private func completionsPerMonthCard(accentForCharts: Color, data: [MonthPoint]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Completions / Month")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(primaryText)

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.10))
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(accentForCharts.opacity(0.95))
                }
                .frame(width: 34, height: 34)
            }

            Chart(data) { p in
                LineMark(
                    x: .value("Month", p.monthIndex),
                    y: .value("Count", p.count)
                )
                .foregroundStyle(accentForCharts)

                AreaMark(
                    x: .value("Month", p.monthIndex),
                    y: .value("Count", p.count)
                )
                .foregroundStyle(accentForCharts)
                .opacity(0.25)
            }
            .chartXScale(domain: 0.5...12.5)
            .chartXAxis {
                AxisMarks(values: Array(1...12)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(collisionResolution: .disabled) {
                        if let i = value.as(Int.self) {
                            Text(StatsEngine.monthAbbrev(i))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(tertiaryText)
                                .fixedSize()
                        }
                    }
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 160)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(stroke, lineWidth: 1)
        )
    }

    // MARK: - Selection

    private func resolvedSelectedHabit() -> HTHabit? {
        guard let id = selectedHabitID else { return nil }
        return habits.first(where: { $0.persistentModelID == id })
    }
}
