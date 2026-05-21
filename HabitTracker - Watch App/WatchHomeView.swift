import SwiftUI

struct WatchHomeView: View {
    @StateObject private var bridge = WatchBridge.shared
    @StateObject private var favs = WatchFavoritesStore.shared

    @State private var showFavoritesOnly = false

    private var filteredHabits: [WatchHabit] {
        if showFavoritesOnly {
            return bridge.habits.filter { favs.isFavorite(id: $0.id) }
        } else {
            return bridge.habits
        }
    }

    var body: some View {
        VStack(spacing: 8) {

            // Top filter (substitui segmented)
            HStack(spacing: 8) {
                Button {
                    showFavoritesOnly = false
                } label: {
                    Text("Todos")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(showFavoritesOnly ? Color.white.opacity(0.10) : Color.white.opacity(0.22))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    showFavoritesOnly = true
                } label: {
                    Text("Fav")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(showFavoritesOnly ? Color.white.opacity(0.22) : Color.white.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            if filteredHabits.isEmpty {
                VStack(spacing: 6) {
                    Text(showFavoritesOnly ? "Sem favoritos" : "Sem hábitos")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Abra o iPhone para sincronizar.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    Button("Sincronizar") {
                        bridge.requestSync()
                    }
                    .font(.system(size: 12, weight: .semibold))
                }
                .padding(.top, 6)
            } else {
                List {
                    ForEach(filteredHabits) { h in
                        WatchHabitRow(
                            habit: h,
                            isFavorite: favs.isFavorite(id: h.id),
                            onToggleDone: { bridge.toggleHabit(id: h.id) },
                            onToggleFavorite: { favs.toggle(id: h.id) }
                        )
                    }
                }
                .listStyle(.carousel)
            }
        }
        .padding(.horizontal, 6)
        .onAppear {
            bridge.activateIfNeeded()
            bridge.requestSync()
        }
    }
}
