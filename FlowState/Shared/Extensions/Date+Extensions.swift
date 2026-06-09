import Foundation

extension Date {
    /// Key for today (YYYY-MM-DD) — used for daily reset logic
    static var todayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    /// Start of today
    static var startOfToday: Date {
        Calendar.current.startOfDay(for: Date())
    }

    /// Whether this date falls on the same calendar day as another
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    /// Whether this date is strictly yesterday relative to today
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// Short weekday label (e.g., "Mon")
    var shortWeekday: String {
        let f = DateFormatter()
        f.dateFormat = "E"
        return f.string(from: self)
    }

    /// Short date label (e.g., "Jun 7")
    var shortDate: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: self)
    }

    /// Returns how many full days difference between self and another date
    func daysDifference(from other: Date) -> Int {
        let calendar = Calendar.current
        let selfDay = calendar.startOfDay(for: self)
        let otherDay = calendar.startOfDay(for: other)
        return calendar.dateComponents([.day], from: otherDay, to: selfDay).day ?? 0
    }
}
