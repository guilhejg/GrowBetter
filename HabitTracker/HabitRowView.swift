import SwiftUI
import SwiftData
import UIKit

// ✅ Resolve: "Notification.Name has no member 'agaBloomPulse'"
extension Notification.Name {
    static let agaBloomPulse = Notification.Name("agaBloomPulse")
}

struct HabitRowView: View {
    @Environment(\.modelContext) private var context

    let habit: HTHabit
    let logs: [HTHabitLog]

    // ✅ Feedback minimalista
    @State private var bounce: Bool = false
    @State private var ring: Bool = false
    @State private var ringScale: CGFloat = 1.0
    @State private var ringOpacity: Double = 0.0

    var body: some View {
        let accent = Color(hex: habit.colorHex)

        // ✅ Dias concluídos (local, por dia)
        let completedDays = Set(logs.map { Calendar.current.startOfDay(for: $0.date) })
        let today = Calendar.current.startOfDay(for: .now)
        let isCompletedToday = completedDays.contains(today)

        VStack(spacing: 10) {
            HStack(spacing: 12) {
                iconBox(accent: accent)

                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(habit.detailText.isEmpty ? " " : habit.detailText)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.70))
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    toggleToday(isCompletedToday: isCompletedToday, accent: accent)
                } label: {
                    completionBox(accent: accent, isCompletedToday: isCompletedToday)
                        .scaleEffect(bounce ? 1.08 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.55), value: bounce)
                        .overlay {
                            if ring {
                                Circle()
                                    .stroke(accent.opacity(0.90), lineWidth: 2)
                                    .scaleEffect(ringScale)
                                    .opacity(ringOpacity)
                                    .allowsHitTesting(false)
                            }
                        }
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
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Actions (✅ apaga APENAS o log do dia atual)

    private func toggleToday(isCompletedToday: Bool, accent: Color) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        if let existing = logs.first(where: { cal.isDate($0.date, inSameDayAs: today) }) {
            // ✅ desmarca
            context.delete(existing)
            try? context.save()
            return
        }

        // ✅ marca
        context.insert(HTHabitLog(habit: habit, date: today))
        try? context.save()

        // ✅ feedback do botão
        triggerFeedback(accent: accent)

        // ✅ avisa o Jardim (AgaBloom reage)
        NotificationCenter.default.post(name: .agaBloomPulse, object: nil)
    }

    // MARK: - Minimal feedback (pulse + ring + haptic)

    private func triggerFeedback(accent: Color) {
        // ✅ bounce
        bounce = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            bounce = false
        }

        // ✅ ring
        ring = true
        ringScale = 0.85
        ringOpacity = 0.90

        withAnimation(.easeOut(duration: 0.35)) {
            ringScale = 1.90
            ringOpacity = 0.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            ring = false
            ringScale = 1.0
            ringOpacity = 0.0
        }

        // ✅ haptic (medium)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    // MARK: - UI

    private func iconBox(accent: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.10))
            Image(systemName: habit.iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.95))
        }
        .frame(width: 44, height: 44)
    }

    private func completionBox(accent: Color, isCompletedToday: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isCompletedToday ? accent : Color.white.opacity(0.12))
            Image(systemName: "checkmark")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(isCompletedToday ? .black.opacity(0.85) : .white.opacity(0.75))
        }
        .frame(width: 44, height: 44)
    }
}
