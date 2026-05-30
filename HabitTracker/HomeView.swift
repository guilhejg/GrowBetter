import SwiftUI
import SwiftData

struct HomeView: View {

    @Binding var selectedTab: HTTab

    @Query(sort: \HTHabit.createdAt, order: .forward)
    private var habits: [HTHabit]

    @Query(sort: \HTHabitLog.date, order: .forward)
    private var allLogs: [HTHabitLog]

    @Environment(\.modelContext) private var context

    @AppStorage("appearance.uiScale") private var uiScale: Double = 0.85
    @AppStorage(HTAccountSession.displayNameKey) private var displayName = ""

    @State private var showingCreate = false
    @State private var selectedHabit: HTHabit?

    private var scale: CGFloat {
        CGFloat(min(max(uiScale, 0.75), 1.0))
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    private var greetingName: String {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "jardineiro" : trimmedName
    }

    var body: some View {
        ZStack {
            homeBackground

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: scaled(16)) {
                    header
                    gardenCard
                    habitsHeader

                    if habits.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 10) {
                            ForEach(habits, id: \.persistentModelID) { habit in
                                HabitRowContainer(habit: habit) {
                                    selectedHabit = habit
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, scaled(16))
                .padding(.top, scaled(14))
                .padding(.bottom, scaled(18))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingCreate) {
            HTHabitEditorView(mode: .create)
        }
        .sheet(
            isPresented: Binding(
                get: { selectedHabit != nil },
                set: { if !$0 { selectedHabit = nil } }
            )
        ) {
            if let habit = selectedHabit {
                HTHabitEditorView(mode: .edit(habit))
            }
        }
        .onAppear {
            HTWatchBridge.shared.activateIfNeeded()
            HTWatchBridge.shared.pushHabitsToWatch(habits: habits)
        }
        .onChange(of: habits) { _, newValue in
            HTWatchBridge.shared.pushHabitsToWatch(habits: newValue)
        }
        .onReceive(NotificationCenter.default.publisher(for: .htWatchHabitsRequested)) { _ in
            HTWatchBridge.shared.pushHabitsToWatch(habits: habits)
        }
        .onReceive(NotificationCenter.default.publisher(for: .htWatchToggleRequested)) { notif in
            guard let id = notif.object as? String else { return }

            HTWatchBridge.shared.handleToggleFromWatch(habitIDURI: id, modelContext: context)

            DispatchQueue.main.async {
                HTWatchBridge.shared.pushHabitsToWatch(habits: habits)
            }
        }
    }

    // MARK: - Layout

    private var homeBackground: some View {
        HTAppBackground()
    }

    private var header: some View {
        HStack(alignment: .top, spacing: scaled(14)) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Bom dia, \(greetingName)! 🌱")
                    .font(.system(size: scaled(30), weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text("Seu jardim cresce com suas escolhas.")
                    .font(.system(size: scaled(16), weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.62))
                    .lineLimit(2)
            }

            Spacer()

            Button {
                selectedTab = .settings
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: scaled(20), weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: scaled(52), height: scaled(52))
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                        )

                    Circle()
                        .fill(Color(red: 0.39, green: 0.88, blue: 0.28))
                        .frame(width: scaled(13), height: scaled(13))
                        .padding(scaled(12))
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.top, scaled(6))
    }

    private var gardenCard: some View {
        let completed = allLogs.count
        let target = max(habits.count * 30, 100)
        let progress = min(Double(completed) / Double(target), 1)
        let level = max(1, completed / 20 + 1)

        return ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.05, green: 0.15, blue: 0.10),
                            Color(red: 0.02, green: 0.07, blue: 0.07),
                            Color.black.opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Meu Jardim")
                        .font(.system(size: scaled(28), weight: .bold))
                        .foregroundStyle(.white)

                    Text("Nível \(level) • Em crescimento")
                        .font(.system(size: scaled(16), weight: .semibold))
                        .foregroundStyle(Color(red: 0.39, green: 0.88, blue: 0.28))

                    VStack(alignment: .leading, spacing: 8) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.10))

                                Capsule()
                                    .fill(Color(red: 0.39, green: 0.88, blue: 0.28))
                                    .frame(width: geo.size.width * progress)
                            }
                        }
                        .frame(width: scaled(150), height: scaled(8))

                        Text("\(completed) / \(target) XP")
                            .font(.system(size: scaled(16), weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.top, scaled(22))
                .padding(.horizontal, scaled(18))

                Spacer()

                gardenStatsBar
                    .padding(scaled(12))
            }
        }
        .frame(height: scaled(244))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color.green.opacity(0.12), radius: 18, x: 0, y: 10)
    }

    private var gardenStatsBar: some View {
        HStack(spacing: 0) {
            gardenStat(
                icon: "leaf.fill",
                value: "\(max(allLogs.count, habits.count))",
                title: "Plantas",
                color: Color(red: 0.39, green: 0.88, blue: 0.28)
            )
            gardenStat(
                icon: "drop.fill",
                value: "\(habits.count * 12)",
                title: "Água",
                color: Color(red: 0.22, green: 0.65, blue: 1.0)
            )
            gardenStat(
                icon: "sun.max.fill",
                value: "\(max(1, habits.count * 3))",
                title: "Luz",
                color: .yellow
            )
            gardenStat(
                icon: "diamond.fill",
                value: "\(max(0, habits.count / 2))",
                title: "Decorações",
                color: .green
            )
        }
        .padding(.vertical, scaled(10))
        .padding(.horizontal, scaled(10))
        .background(Color.black.opacity(0.68))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func gardenStat(icon: String, value: String, title: String, color: Color) -> some View {
        HStack(spacing: scaled(8)) {
            Image(systemName: icon)
                .font(.system(size: scaled(20), weight: .bold))
                .foregroundStyle(color)
                .frame(width: scaled(24))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: scaled(17), weight: .bold))
                    .foregroundStyle(.white)

                Text(title)
                    .font(.system(size: scaled(10), weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var habitsHeader: some View {
        HStack(alignment: .center) {
            Text("Hábitos de hoje")
                .font(.system(size: scaled(25), weight: .bold))
                .foregroundStyle(.white)

            Spacer()

            Button {
                showingCreate = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: scaled(22), weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: scaled(42), height: scaled(42))
                        .background(Circle().fill(Color(red: 0.35, green: 0.84, blue: 0.25)))

                    Text("Adicionar hábito")
                        .font(.system(size: scaled(15), weight: .semibold))
                        .foregroundStyle(Color(red: 0.39, green: 0.88, blue: 0.28))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "leaf")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.green.opacity(0.85))

            Text("Nenhum hábito ainda")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)

            Text("Toque em adicionar para plantar o primeiro.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.62))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Habit Row Container

private struct HabitRowContainer: View {

    let habit: HTHabit
    let onEdit: () -> Void

    @Query private var logs: [HTHabitLog]

    init(habit: HTHabit, onEdit: @escaping () -> Void) {
        self.habit = habit
        self.onEdit = onEdit

        let hid = habit.persistentModelID

        _logs = Query(filter: #Predicate<HTHabitLog> { log in
            log.habit.persistentModelID == hid
        })
    }

    var body: some View {
        HomeHabitCard(
            habit: habit,
            logs: logs,
            onEdit: onEdit
        )
    }
}

private struct HomeHabitCard: View {
    @Environment(\.modelContext) private var context
    @AppStorage("appearance.uiScale") private var uiScale: Double = 0.85

    let habit: HTHabit
    let logs: [HTHabitLog]
    let onEdit: () -> Void

    @State private var bounce = false

    private var scale: CGFloat {
        CGFloat(min(max(uiScale, 0.75), 1.0))
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    private var accent: Color { Color(hex: habit.colorHex) }

    private var completedToday: Bool {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return logs.contains { cal.isDate($0.date, inSameDayAs: today) }
    }

    private var streak: Int {
        StatsEngine.currentStreak(from: logs)
    }

    private var completedDays: Set<Date> {
        Set(logs.map { Calendar.current.startOfDay(for: $0.date) })
    }

    var body: some View {
        VStack(spacing: scaled(10)) {
            HStack(spacing: scaled(12)) {
                iconTile

                VStack(alignment: .leading, spacing: scaled(4)) {
                    Text(habit.name)
                        .font(.system(size: scaled(17), weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(habit.detailText.isEmpty ? "Descrição do hábito" : habit.detailText)
                        .font(.system(size: scaled(13), weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.70))
                        .lineLimit(1)
                }

                Spacer(minLength: scaled(10))

                Text("🔥 \(max(streak, 0)) dias")
                    .font(.system(size: scaled(14), weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.38, blue: 0.18))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Button {
                    toggleToday()
                } label: {
                    completionTile
                }
                .buttonStyle(.plain)
            }

            HTHeatmapView(
                color: accent,
                completedDays: completedDays,
                weeks: HTConstants.heatmapWeeks,
                mostRecentFirst: true
            )
        }
        .padding(scaled(12))
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture(perform: onEdit)
    }

    private var iconTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.10))

            Image(systemName: habit.iconName)
                .font(.system(size: scaled(18), weight: .semibold))
                .foregroundStyle(.white.opacity(0.95))
        }
        .frame(width: scaled(44), height: scaled(44))
    }

    private var completionTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(completedToday ? accent : Color.white.opacity(0.12))

            Image(systemName: "checkmark")
                .font(.system(size: scaled(18), weight: .bold))
                .foregroundStyle(completedToday ? .black.opacity(0.85) : .white.opacity(0.75))
        }
        .frame(width: scaled(44), height: scaled(44))
        .scaleEffect(bounce ? 1.08 : 1.0)
        .animation(.spring(response: 0.24, dampingFraction: 0.58), value: bounce)
    }

    private func toggleToday() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        if let existing = logs.first(where: { cal.isDate($0.date, inSameDayAs: today) }) {
            context.delete(existing)
            try? context.save()
            return
        }

        context.insert(HTHabitLog(habit: habit, date: today))
        try? context.save()

        bounce = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            bounce = false
        }

        NotificationCenter.default.post(name: .agaBloomPulse, object: nil)
    }
}
