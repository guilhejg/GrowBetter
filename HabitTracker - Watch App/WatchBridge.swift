import Foundation
import WatchConnectivity
import Combine

@MainActor
final class WatchBridge: NSObject, ObservableObject {
    static let shared = WatchBridge()

    @Published private(set) var habits: [WatchHabit] = []

    private override init() {
        super.init()
        activateIfNeeded()
    }

    private var session: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }

    func activateIfNeeded() {
        guard let session else { return }
        session.delegate = self
        session.activate()
    }

    func requestSync() {
        guard let session else { return }
        session.sendMessage(["type": "request_habits"], replyHandler: nil, errorHandler: nil)
    }

    func toggleHabit(id: String) {
        guard let session else { return }
        session.sendMessage(["type": "toggle", "id": id], replyHandler: nil, errorHandler: nil)
    }

    private func applyHabitsPayload(_ raw: [[String: Any]]) {
        let mapped: [WatchHabit] = raw.compactMap { dict in
            guard let id = dict["id"] as? String else { return nil }
            let name = dict["name"] as? String ?? "Hábito"
            let subtitle = dict["subtitle"] as? String ?? ""
            let icon = dict["icon"] as? String ?? "circle"
            let colorHex = dict["colorHex"] as? String ?? "#9CA3AF"
            return WatchHabit(id: id, name: name, subtitle: subtitle, icon: icon, colorHex: colorHex)
        }
        self.habits = mapped
    }
}

extension WatchBridge: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {}

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        guard let type = message["type"] as? String else { return }

        if type == "habits", let raw = message["habits"] as? [[String: Any]] {
            Task { @MainActor in
                self.applyHabitsPayload(raw)
            }
        }
    }
}
