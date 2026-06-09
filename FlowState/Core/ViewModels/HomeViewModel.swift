import Foundation
import SwiftData

@Observable
final class HomeViewModel {

    var streakDays: Int = UserPreferences.shared.streakCurrentDays
    var todayFocusMinutes: Int = 0
    var showStreakResetMessage: Bool = false

    func loadTodayStats(from context: ModelContext) {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())

        let descriptor = FetchDescriptor<SessionRecord>(
            predicate: #Predicate {
                $0.startedAt >= todayStart && $0.statusRaw == "completed"
            }
        )

        if let sessions = try? context.fetch(descriptor) {
            todayFocusMinutes = Int(sessions.reduce(0) { $0 + $1.actualWorkDuration } / 60)
        }

        streakDays = UserPreferences.shared.streakCurrentDays
        checkStreakReset()
    }

    private func checkStreakReset() {
        guard let lastDate = UserPreferences.shared.lastFocusDate else { return }
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: Date()))!
        let lastDay = calendar.startOfDay(for: lastDate)

        if lastDay < yesterday && streakDays > 0 {
            showStreakResetMessage = true
            UserPreferences.shared.streakCurrentDays = 0
            streakDays = 0
        }
    }
}
