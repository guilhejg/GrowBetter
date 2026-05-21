import SwiftUI
import SwiftData

@main
struct HabitTrackerApp: App {

    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false
    @AppStorage("didScheduleNotifications") private var didScheduleNotifications: Bool = false

    init() {
        // ✅ 1ª aplicação (antes de montar a UI)
        HTAppearance.configureTabBarTransparent()
    }

    var body: some Scene {
        WindowGroup {
            if hasSeenWelcome {
                RootTabView()
                    .onAppear {
                        scheduleNotificationsIfNeeded()
                        HTWatchBridge.shared.activateIfNeeded()
                    }
            } else {
                WelcomeView(
                    onContinue: {
                        hasSeenWelcome = true
                        scheduleNotificationsIfNeeded()
                        HTWatchBridge.shared.activateIfNeeded()
                    },
                    onApple: {
                        hasSeenWelcome = true
                        scheduleNotificationsIfNeeded()
                        HTWatchBridge.shared.activateIfNeeded()
                    },
                    onGoogle: {
                        hasSeenWelcome = true
                        scheduleNotificationsIfNeeded()
                        HTWatchBridge.shared.activateIfNeeded()
                    }
                )
            }
        }
        .modelContainer(for: [HTHabit.self, HTHabitLog.self])
    }

    private func scheduleNotificationsIfNeeded() {
        guard didScheduleNotifications == false else { return }

        HTNotifications.requestPermissionIfNeeded()
        HTNotifications.scheduleDailyReminders(times: [
            (hour: 6, minute: 0),
            (hour: 12, minute: 0),
            (hour: 18, minute: 0),
            (hour: 0, minute: 1)
        ])

        didScheduleNotifications = true
    }
}
