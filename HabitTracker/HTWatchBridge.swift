import Foundation
import SwiftData
import WatchConnectivity
import Combine

final class HTWatchBridge: NSObject, ObservableObject {

    static let shared = HTWatchBridge()

    // ✅ garante conformidade com ObservableObject mesmo sem @Published
    let objectWillChange = ObservableObjectPublisher()

    private override init() {
        super.init()
    }

    // ✅ SwiftData PersistentIdentifier não tem uriRepresentation.
    //    Usamos uma string estável dentro da mesma instalação do app.
    private func pidString(_ id: PersistentIdentifier) -> String {
        String(describing: id)
    }

    // MARK: - Session

    func activateIfNeeded() {
        #if DEBUG
        return
        #else
        guard WCSession.isSupported() else { return }

        let session = WCSession.default
        if session.delegate == nil {
            session.delegate = self
        }

        if session.activationState != .activated {
            session.activate()
        }
        #endif
    }

    // MARK: - Push habits to Watch

    func pushHabitsToWatch(habits: [HTHabit]) {
        #if DEBUG
        return
        #else
        guard WCSession.isSupported() else { return }

        let session = WCSession.default
        guard session.activationState == .activated else { return }

        let payload: [[String: Any]] = habits.map { h in
            [
                "id": pidString(h.persistentModelID), // ✅ fix
                "name": h.name,
                "icon": h.iconName,
                "colorHex": h.colorHex,
                "detail": h.detailText
            ]
        }

        let message: [String: Any] = [
            "type": "habits",
            "habits": payload
        ]

        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        } else {
            // fallback: mantém um estado “último conhecido” no watch
            try? session.updateApplicationContext(message)
        }
        #endif
    }

    // MARK: - Handle toggle from Watch (called by HomeView)

    func handleToggleFromWatch(habitIDURI: String, modelContext: ModelContext) {
        #if DEBUG
        return
        #else
        // ✅ match pela string gerada do PersistentIdentifier
        do {
            let habits = try modelContext.fetch(FetchDescriptor<HTHabit>())
            guard let habit = habits.first(where: { pidString($0.persistentModelID) == habitIDURI }) else {
                return
            }

            toggleToday(for: habit, modelContext: modelContext)
        } catch {
            print("HTWatchBridge handleToggleFromWatch fetch error:", error)
        }
        #endif
    }

    private func toggleToday(for habit: HTHabit, modelContext: ModelContext) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today) ?? today.addingTimeInterval(60 * 60 * 24)

        let hid = habit.persistentModelID

        let descriptor = FetchDescriptor<HTHabitLog>(
            predicate: #Predicate { log in
                log.habit.persistentModelID == hid &&
                log.date >= today &&
                log.date < tomorrow
            }
        )

        do {
            if let existing = try modelContext.fetch(descriptor).first {
                modelContext.delete(existing)
            } else {
                modelContext.insert(HTHabitLog(habit: habit, date: today))
            }
            try modelContext.save()
        } catch {
            print("HTWatchBridge toggleToday error:", error)
        }
    }
}

// MARK: - WCSessionDelegate

extension HTWatchBridge: WCSessionDelegate {

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if let error = error {
            print("WCSession activation error:", error)
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) { }
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    // Watch -> iPhone: toggle
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        guard let type = message["type"] as? String else { return }

        if type == "toggle",
           let id = message["id"] as? String {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .htWatchToggleRequested, object: id)
            }
        }
    }
}
