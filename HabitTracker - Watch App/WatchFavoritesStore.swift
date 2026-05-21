import Foundation
import Combine

final class WatchFavoritesStore: ObservableObject {
    static let shared = WatchFavoritesStore()

    @Published private(set) var favorites: Set<String> = []

    private let key = "watch_favorites_ids"

    private init() {
        load()
    }

    func isFavorite(id: String) -> Bool {
        favorites.contains(id)
    }

    func toggle(id: String) {
        if favorites.contains(id) {
            favorites.remove(id)
        } else {
            favorites.insert(id)
        }
        save()
    }

    private func load() {
        let arr = UserDefaults.standard.stringArray(forKey: key) ?? []
        favorites = Set(arr)
    }

    private func save() {
        UserDefaults.standard.set(Array(favorites), forKey: key)
    }
}
