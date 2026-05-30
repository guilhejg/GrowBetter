import SwiftUI
import SwiftData

@main
struct HabitTrackerApp: App {

    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false
    @AppStorage("didScheduleNotifications") private var didScheduleNotifications: Bool = false
    private let modelContainer: ModelContainer

    init() {
        modelContainer = Self.makeModelContainer()
        HTAppearance.configureTabBarTransparent()
    }

    var body: some Scene {
        WindowGroup {
            if hasSeenWelcome {
                RootTabView()
                    .onAppear {
                        startRuntimeServices()
                    }
            } else {
                WelcomeView(
                    onContinue: {
                        hasSeenWelcome = true
                        startRuntimeServices()
                    },
                    onApple: {
                        hasSeenWelcome = true
                        startRuntimeServices()
                    },
                    onGoogle: {
                        hasSeenWelcome = true
                        startRuntimeServices()
                    }
                )
            }
        }
        .modelContainer(modelContainer)
    }

    private func startRuntimeServices() {
        #if DEBUG
        return
        #else
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            scheduleNotificationsIfNeeded()
            HTWatchBridge.shared.activateIfNeeded()
        }
        #endif
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

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([HTHabit.self, HTHabitLog.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            print("Persistent SwiftData container failed:", error)
        }

        let fallbackConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [fallbackConfiguration])
        } catch {
            fatalError("Unable to create fallback SwiftData container: \(error)")
        }
    }
}
