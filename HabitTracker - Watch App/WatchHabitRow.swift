import SwiftUI

struct WatchHabitRow: View {
    let habit: WatchHabit
    let isFavorite: Bool
    let onToggleDone: () -> Void
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)

                if !habit.subtitle.isEmpty {
                    Text(habit.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundStyle(isFavorite ? .yellow : .secondary)
            }
            .buttonStyle(.plain)

            Button(action: onToggleDone) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .bold))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
