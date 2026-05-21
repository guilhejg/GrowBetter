import Foundation

struct WatchHabit: Identifiable, Hashable {
    let id: String          // persistentModelID uri string vindo do iPhone
    var name: String
    var subtitle: String
    var icon: String
    var colorHex: String
}
