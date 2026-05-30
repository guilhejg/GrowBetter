import SwiftUI
import SwiftData

enum HTPreviewData {
    @MainActor
    static func container() -> ModelContainer {
        let schema = Schema([
            HTHabit.self,
            HTHabitLog.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext

        let habits = [
            HTHabit(name: "Academia", detailText: "30 min de treino", iconName: "dumbbell.fill", colorHex: "#38D95C"),
            HTHabit(name: "Leitura", detailText: "20 min de leitura", iconName: "book.fill", colorHex: "#8B5CF6"),
            HTHabit(name: "Água", detailText: "2 litros", iconName: "drop.fill", colorHex: "#38BDF8"),
            HTHabit(name: "Meditação", detailText: "10 min de pausa", iconName: "leaf.fill", colorHex: "#F97316")
        ]

        habits.forEach { context.insert($0) }

        let calendar = Calendar.current
        for (index, habit) in habits.enumerated() {
            for offset in 0..<(7 - index) {
                if let date = calendar.date(byAdding: .day, value: -offset, to: .now) {
                    context.insert(HTHabitLog(habit: habit, date: calendar.startOfDay(for: date)))
                }
            }
        }

        try? context.save()
        return container
    }
}

#Preview("App Completo") {
    RootTabView()
        .modelContainer(HTPreviewData.container())
}

#Preview("Hoje") {
    RootTabView(initialTab: .habits)
        .modelContainer(HTPreviewData.container())
}

#Preview("Jardim") {
    RootTabView(initialTab: .jardim)
        .modelContainer(HTPreviewData.container())
}

#Preview("Estatísticas") {
    RootTabView(initialTab: .stats)
        .modelContainer(HTPreviewData.container())
}

#Preview("Ajustes") {
    RootTabView(initialTab: .settings)
        .modelContainer(HTPreviewData.container())
}
