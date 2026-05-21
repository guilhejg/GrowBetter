import Foundation
import SwiftData

@Model
final class HTHabit {
    var name: String
    var detailText: String
    var iconName: String
    var colorHex: String

    var createdAt: Date

    init(name: String,
         detailText: String,
         iconName: String,
         colorHex: String,
         createdAt: Date = .now) {
        self.name = name
        self.detailText = detailText
        self.iconName = iconName
        self.colorHex = colorHex
        self.createdAt = createdAt
    }
}

@Model
final class HTHabitLog {
    @Relationship var habit: HTHabit
    var date: Date

    init(habit: HTHabit, date: Date) {
        self.habit = habit
        self.date = date
    }
}
