import Foundation
import SwiftUI

// MARK: - UserPreferences
// Stored in UserDefaults via @AppStorage in views
// This class provides a centralized access point for preferences
final class UserPreferences {

    static let shared = UserPreferences()
    private init() {}

    // MARK: - Keys
    enum Key: String {
        case defaultMode = "pref_default_mode"
        case energyCheckInEnabled = "pref_energy_checkin"
        case breakEnforcementLevel = "pref_break_enforcement"
        case hapticsEnabled = "pref_haptics"
        case selectedSoundscapeId = "pref_soundscape_id"
        case soundscapeVolume = "pref_soundscape_volume"
        case dailyFocusGoalMinutes = "pref_daily_goal"
        case streakCurrentDays = "pref_streak_days"
        case streakLongestDays = "pref_streak_longest"
        case lastFocusDate = "pref_last_focus_date"
        case appLanguage = "pref_app_language"
        case microCommitmentUsedToday = "micro_used_today"
        case microCommitmentLastResetDate = "micro_last_reset"
        case shownMilestones = "pref_shown_milestones"
    }

    // MARK: - Default Mode
    var defaultMode: SessionMode {
        get {
            let raw = UserDefaults.standard.string(forKey: Key.defaultMode.rawValue) ?? ""
            return SessionMode(rawValue: raw) ?? .standard
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Key.defaultMode.rawValue)
        }
    }

    // MARK: - Energy Check-in
    var energyCheckInEnabled: Bool {
        get { UserDefaults.standard.object(forKey: Key.energyCheckInEnabled.rawValue) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Key.energyCheckInEnabled.rawValue) }
    }

    // MARK: - Haptics
    var hapticsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: Key.hapticsEnabled.rawValue) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Key.hapticsEnabled.rawValue) }
    }

    // MARK: - Soundscape
    var selectedSoundscapeId: String {
        get { UserDefaults.standard.string(forKey: Key.selectedSoundscapeId.rawValue) ?? "none" }
        set { UserDefaults.standard.set(newValue, forKey: Key.selectedSoundscapeId.rawValue) }
    }

    var soundscapeVolume: Float {
        get { UserDefaults.standard.object(forKey: Key.soundscapeVolume.rawValue) as? Float ?? 0.6 }
        set { UserDefaults.standard.set(newValue, forKey: Key.soundscapeVolume.rawValue) }
    }

    // MARK: - Streak
    var streakCurrentDays: Int {
        get { UserDefaults.standard.integer(forKey: Key.streakCurrentDays.rawValue) }
        set { UserDefaults.standard.set(newValue, forKey: Key.streakCurrentDays.rawValue) }
    }

    var streakLongestDays: Int {
        get { UserDefaults.standard.integer(forKey: Key.streakLongestDays.rawValue) }
        set { UserDefaults.standard.set(newValue, forKey: Key.streakLongestDays.rawValue) }
    }

    var lastFocusDate: Date? {
        get { UserDefaults.standard.object(forKey: Key.lastFocusDate.rawValue) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: Key.lastFocusDate.rawValue) }
    }

    /// Milestone IDs already shown to user (to avoid repeat celebrations)
    var shownMilestones: Set<String> {
        get {
            let arr = UserDefaults.standard.stringArray(forKey: Key.shownMilestones.rawValue) ?? []
            return Set(arr)
        }
        set { UserDefaults.standard.set(Array(newValue), forKey: Key.shownMilestones.rawValue) }
    }

    func markMilestoneShown(_ id: String) {
        var current = shownMilestones
        current.insert(id)
        shownMilestones = current
    }

    // MARK: - Language
    var appLanguage: AppLanguage {
        get {
            let raw = UserDefaults.standard.string(forKey: Key.appLanguage.rawValue) ?? ""
            return AppLanguage(rawValue: raw) ?? .system
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: Key.appLanguage.rawValue) }
    }

    // MARK: - Micro-Commitment Daily Limit
    var microCommitmentUsedToday: Int {
        get {
            resetMicroCountIfNeeded()
            return UserDefaults.standard.integer(forKey: Key.microCommitmentUsedToday.rawValue)
        }
        set { UserDefaults.standard.set(newValue, forKey: Key.microCommitmentUsedToday.rawValue) }
    }

    private func resetMicroCountIfNeeded() {
        let lastReset = UserDefaults.standard.object(forKey: Key.microCommitmentLastResetDate.rawValue) as? Date
        let today = Calendar.current.startOfDay(for: Date())
        if lastReset == nil || lastReset! < today {
            UserDefaults.standard.set(0, forKey: Key.microCommitmentUsedToday.rawValue)
            UserDefaults.standard.set(today, forKey: Key.microCommitmentLastResetDate.rawValue)
        }
    }

    // MARK: - Streak Calculation
    func updateStreak(completedSessionDate: Date = Date()) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: completedSessionDate)

        if let last = lastFocusDate {
            let lastDay = calendar.startOfDay(for: last)
            let diff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if diff == 0 {
                // Same day — no change to streak count
            } else if diff == 1 {
                // Consecutive day
                streakCurrentDays += 1
            } else {
                // Broken streak
                streakCurrentDays = 1
            }
        } else {
            streakCurrentDays = 1
        }

        // Update longest streak
        if streakCurrentDays > streakLongestDays {
            streakLongestDays = streakCurrentDays
        }

        lastFocusDate = completedSessionDate
    }
}

// MARK: - App Language
enum AppLanguage: String, CaseIterable {
    case system = "system"
    case english = "en"
    case vietnamese = "vi"

    var displayName: String {
        switch self {
        case .system: return "System Default"
        case .english: return "English"
        case .vietnamese: return "Tiếng Việt"
        }
    }
}
