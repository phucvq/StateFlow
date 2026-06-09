import Foundation
import SwiftUI

// MARK: - Milestone

enum FocusMilestone: String, CaseIterable {
    case streak7 = "streak_7"
    case streak30 = "streak_30"
    case hours100 = "hours_100"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .streak7:  return L10n.milestone7DaysTitle
        case .streak30: return L10n.milestone30DaysTitle
        case .hours100: return L10n.milestone100HoursTitle
        }
    }

    var subtitle: String {
        switch self {
        case .streak7:  return L10n.milestone7DaysSubtitle
        case .streak30: return L10n.milestone30DaysSubtitle
        case .hours100: return L10n.milestone100HoursSubtitle
        }
    }

    var icon: String {
        switch self {
        case .streak7:  return "flame.fill"
        case .streak30: return "star.fill"
        case .hours100: return "trophy.fill"
        }
    }
}

// MARK: - Time Block
// Stores per-level session counts so the chart can render a stacked
// distribution. This is more informative than a single averaged color
// when a time block contains sessions at mixed energy levels.

struct EnergyTimeBlock: Identifiable {
    let id = UUID()
    let label: String
    let startHour: Int
    let endHour: Int
    let lowCount: Int
    let mediumCount: Int
    let highCount: Int

    var sessionCount: Int { lowCount + mediumCount + highCount }
    var hasData: Bool { sessionCount > 0 }

    /// The dominant energy level (statistical mode) for insight copy.
    var dominantLevel: EnergyLevel? {
        guard hasData else { return nil }
        let pairs: [(EnergyLevel, Int)] = [(.low, lowCount), (.medium, mediumCount), (.high, highCount)]
        return pairs.max(by: { $0.1 < $1.1 })?.0
    }
}

// MARK: - AnalyticsViewModel

/// Accepts pre-fetched sessions via recompute(sessions:isPremium:).
/// No ModelContext dependency — the view owns @Query and passes results here.
@Observable
final class AnalyticsViewModel {

    struct DayStats: Identifiable {
        let id = UUID()
        let date: Date
        let totalMinutes: Int
        let completedSessions: Int

        var dayLabel: String {
            let fmt = DateFormatter()
            fmt.dateFormat = "E"
            return fmt.string(from: date)
        }
    }

    // MARK: - Published State
    var weeklyStats: [DayStats] = []
    var totalFocusToday: Int = 0
    var totalFocusWeek: Int = 0
    var previousWeekMinutes: Int = 0
    var weekChangePercent: Int? = nil
    var longestStreak: Int = 0
    var currentStreak: Int = 0
    var insightText: String = ""
    var bestHour: Int? = nil
    var favoriteMode: SessionMode = .standard
    var energyTimeBlocks: [EnergyTimeBlock] = []
    var newMilestone: FocusMilestone? = nil
    var totalFocusHoursAllTime: Double = 0
    var totalSessionsAllTime: Int = 0

    // MARK: - Recompute from live sessions
    func recompute(allSessions: [SessionRecord], isPremium: Bool) {
        let calendar = Calendar.current
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)

        // --- Today (available to all) ---
        let todaySessions = allSessions.filter {
            $0.startedAt >= todayStart && $0.status == .completed
        }
        totalFocusToday = Int(todaySessions.reduce(0) { $0 + $1.actualWorkDuration } / 60)

        currentStreak = UserPreferences.shared.streakCurrentDays
        longestStreak = max(UserPreferences.shared.streakLongestDays, currentStreak)

        guard isPremium else {
            // Reset premium-only fields
            weeklyStats = []
            totalFocusWeek = 0
            energyTimeBlocks = []
            insightText = totalFocusToday > 0
                ? String(format: L10n.insightWeekTotal, totalFocusToday)
                : ""
            return
        }

        // --- This week (7 days) ---
        let weekStart = calendar.date(byAdding: .day, value: -6, to: todayStart)!
        let weekSessions = allSessions.filter { $0.startedAt >= weekStart }
        buildWeeklyStats(from: weekSessions, todayStart: todayStart, calendar: calendar)
        totalFocusWeek = weeklyStats.reduce(0) { $0 + $1.totalMinutes }

        // --- Previous week for comparison ---
        let prevWeekEnd = weekStart
        let prevWeekStart = calendar.date(byAdding: .day, value: -7, to: prevWeekEnd)!
        let prevWeekCompleted = allSessions.filter {
            $0.startedAt >= prevWeekStart && $0.startedAt < prevWeekEnd && $0.status == .completed
        }
        previousWeekMinutes = Int(prevWeekCompleted.reduce(0) { $0 + $1.actualWorkDuration } / 60)
        if previousWeekMinutes > 0 {
            let change = Double(totalFocusWeek - previousWeekMinutes) / Double(previousWeekMinutes) * 100
            weekChangePercent = Int(change.rounded())
        } else {
            weekChangePercent = nil
        }

        // --- Favorite mode ---
        let modeCounts = Dictionary(grouping: weekSessions) { $0.mode }.mapValues { $0.count }
        if let top = modeCounts.max(by: { $0.value < $1.value }) { favoriteMode = top.key }

        // --- Best hour ---
        let completedWeek = weekSessions.filter { $0.status == .completed }
        let hourCounts = Dictionary(grouping: completedWeek) {
            calendar.component(.hour, from: $0.startedAt)
        }.mapValues { $0.count }
        bestHour = hourCounts.max(by: { $0.value < $1.value })?.key

        // --- Energy time blocks (30 days) ---
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -29, to: todayStart)!
        let energySessions = allSessions.filter {
            $0.startedAt >= thirtyDaysAgo && $0.energyLevelRaw != nil
        }
        buildEnergyTimeBlocks(from: energySessions, calendar: calendar)

        // --- All-time stats ---
        let completedAllTime = allSessions.filter { $0.status == .completed }
        totalFocusHoursAllTime = completedAllTime.reduce(0) { $0 + $1.actualWorkDuration } / 3600
        totalSessionsAllTime = completedAllTime.count

        checkMilestones()
        generateInsight()

        // --- Sync widget data ---
        let lastCompleted = allSessions.filter { $0.status == .completed }.first
        WidgetDataWriter.write(WidgetSharedData(
            todayFocusMinutes: totalFocusToday,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            weekFocusMinutes: totalFocusWeek,
            lastSessionTaskName: lastCompleted?.taskName,
            lastSessionDate: lastCompleted?.endedAt,
            totalFocusHours: totalFocusHoursAllTime
        ))
    }

    // MARK: - Weekly Stats Builder
    private func buildWeeklyStats(from sessions: [SessionRecord], todayStart: Date, calendar: Calendar) {
        var dailyMap: [Date: [SessionRecord]] = [:]
        for i in 0...6 {
            let day = calendar.date(byAdding: .day, value: i - 6, to: todayStart)!
            dailyMap[day] = []
        }
        for session in sessions {
            let day = calendar.startOfDay(for: session.startedAt)
            if dailyMap[day] != nil { dailyMap[day]!.append(session) }
        }
        weeklyStats = dailyMap.sorted { $0.key < $1.key }.map { day, daySessions in
            DayStats(
                date: day,
                totalMinutes: Int(daySessions.filter { $0.status == .completed }
                    .reduce(0) { $0 + $1.actualWorkDuration } / 60),
                completedSessions: daySessions.filter { $0.status == .completed }.count
            )
        }
    }

    // MARK: - Energy Time Blocks
    private func buildEnergyTimeBlocks(from sessions: [SessionRecord], calendar: Calendar) {
        let blocks: [(label: String, start: Int, end: Int)] = [
            ("6–9AM",  6,  9),
            ("9–12PM", 9,  12),
            ("12–3PM", 12, 15),
            ("3–6PM",  15, 18),
            ("6–9PM",  18, 21),
            ("9PM+",   21, 24),
        ]
        energyTimeBlocks = blocks.map { block in
            let inBlock = sessions.filter {
                let h = calendar.component(.hour, from: $0.startedAt)
                return h >= block.start && h < block.end
            }
            let levels = inBlock.compactMap { $0.energyLevel }
            return EnergyTimeBlock(
                label: block.label,
                startHour: block.start,
                endHour: block.end,
                lowCount:    levels.filter { $0 == .low    }.count,
                mediumCount: levels.filter { $0 == .medium }.count,
                highCount:   levels.filter { $0 == .high   }.count
            )
        }
    }

    // MARK: - Milestones
    private func checkMilestones() {
        guard newMilestone == nil else { return }
        let shown = UserPreferences.shared.shownMilestones
        if currentStreak >= 30 && !shown.contains(FocusMilestone.streak30.id) {
            newMilestone = .streak30
        } else if currentStreak >= 7 && !shown.contains(FocusMilestone.streak7.id) {
            newMilestone = .streak7
        } else if totalFocusHoursAllTime >= 100 && !shown.contains(FocusMilestone.hours100.id) {
            newMilestone = .hours100
        }
    }

    func dismissMilestone() {
        if let m = newMilestone {
            UserPreferences.shared.markMilestoneShown(m.id)
            newMilestone = nil
        }
    }

    // MARK: - Insight
    private func generateInsight() {
        if let pct = weekChangePercent, abs(pct) >= 5 {
            let arrow = pct > 0 ? "↑" : "↓"
            insightText = String(format: L10n.insightWeekChange, arrow, abs(pct))
        } else if let hour = bestHour {
            let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
            let ampm = hour < 12 ? "AM" : "PM"
            insightText = String(format: L10n.insightBestHour, "\(displayHour) \(ampm)")
        } else if totalFocusWeek > 0 {
            insightText = String(format: L10n.insightWeekTotal, totalFocusWeek)
        } else {
            insightText = ""
        }
    }
}
