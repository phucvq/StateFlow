import Foundation

extension TimeInterval {
    /// Full timer string: "25:00"
    var timerString: String {
        let total = Int(self)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Short string: "25m" (EN) or "25 phút" (VI), locale-aware via LocalizationManager.
    var shortTimerString: String {
        let total = Int(self)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let bundle = LocalizationManager.shared.bundle
        let m = NSLocalizedString("unit.minute", bundle: bundle, comment: "")
        let h = NSLocalizedString("unit.hour", bundle: bundle, comment: "")
        if hours > 0 && minutes > 0 { return "\(hours)\(h) \(minutes)\(m)" }
        if hours > 0 { return "\(hours)\(h)" }
        return "\(minutes)\(m)"
    }

    /// Accessibility-friendly: "25 minutes remaining"
    var accessibilityString: String {
        let total = Int(self)
        let minutes = total / 60
        let seconds = total % 60
        if minutes > 0 && seconds > 0 {
            return "\(minutes) minutes \(seconds) seconds"
        } else if minutes > 0 {
            return "\(minutes) minutes"
        } else {
            return "\(seconds) seconds"
        }
    }

    /// Total minutes (rounded down)
    var totalMinutes: Int { Int(self) / 60 }
}
