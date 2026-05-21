import SwiftUI

struct FitHeatmap: View {
    let color: Color
    let completedDays: Set<Date>
    let weeks: Int
    let endDate: Date
    let alignToWeek: Bool
    let mostRecentFirst: Bool

    private let cell: CGFloat = 8
    private let spacing: CGFloat = 4

    var body: some View {
        GeometryReader { geo in
            let availableWidth = geo.size.width

            let totalColumns = CGFloat(max(weeks, 1))
            let heatmapWidth = totalColumns * cell + (totalColumns - 1) * spacing

            let scale = min(1, availableWidth / max(heatmapWidth, 1))

            HTHeatmapView(
                color: color,
                completedDays: completedDays,
                weeks: weeks,
                mostRecentFirst: mostRecentFirst,
                endDate: endDate,
                alignToWeek: alignToWeek
            )
            .scaleEffect(scale, anchor: .topLeading)
            .frame(
                width: availableWidth,
                height: (cell * 7 + spacing * 6) * scale,
                alignment: .topLeading
            )
        }
        .frame(height: cell * 7 + spacing * 6)
    }
}
