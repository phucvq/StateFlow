import Foundation
import SwiftUI

// MARK: - Session Mode
enum SessionMode: String, Codable, CaseIterable, Identifiable {
    case standard = "standard"
    case deepWork = "deep_work"
    case quickSprint = "quick_sprint"
    case micro = "micro"
    case ultraShort = "ultra_short"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard: return L10n.modeStandard
        case .deepWork: return L10n.modeDeepWork
        case .quickSprint: return L10n.modeQuickSprint
        case .micro: return L10n.modeMicro
        case .ultraShort: return L10n.modeUltraShort
        }
    }

    var icon: String {
        switch self {
        case .standard: return "🍅"
        case .deepWork: return "🧠"
        case .quickSprint: return "⚡"
        case .micro: return "🌱"
        case .ultraShort: return "✨"
        }
    }

    var sfSymbol: String {
        switch self {
        case .standard:    return "timer"
        case .deepWork:    return "scope"
        case .quickSprint: return "hare.fill"
        case .micro:       return "leaf.fill"
        case .ultraShort:  return "sparkle"
        }
    }

    var accentColor: Color {
        switch self {
        case .standard: return AppColors.amber
        case .deepWork: return AppColors.indigo
        case .quickSprint: return Color(hex: "#E07A7A")
        case .micro: return AppColors.sage
        case .ultraShort: return Color(hex: "#B8A9E8")
        }
    }

    var workDuration: TimeInterval {
        switch self {
        case .standard: return 25 * 60
        case .deepWork: return 50 * 60
        case .quickSprint: return 15 * 60
        case .micro: return 10 * 60
        case .ultraShort: return 5 * 60
        }
    }

    var breakDuration: TimeInterval {
        switch self {
        case .standard: return 5 * 60
        case .deepWork: return 10 * 60
        case .quickSprint: return 3 * 60
        case .micro: return 2 * 60
        case .ultraShort: return 1 * 60
        }
    }

    var longBreakAfter: Int {
        switch self {
        case .standard: return 4
        case .deepWork: return 2
        case .quickSprint: return 4
        case .micro: return 5
        case .ultraShort: return 6
        }
    }
}

// MARK: - Session Status
enum SessionStatus: String, Codable {
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
}

// MARK: - Energy Level
enum EnergyLevel: String, Codable, CaseIterable, Identifiable {
    case low = "low"
    case medium = "medium"
    case high = "high"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low: return L10n.energyLow
        case .medium: return L10n.energyMedium
        case .high: return L10n.energyHigh
        }
    }

    var description: String {
        switch self {
        case .low: return L10n.energyLowDesc
        case .medium: return L10n.energyMediumDesc
        case .high: return L10n.energyHighDesc
        }
    }

    var emoji: String {
        switch self {
        case .low: return "🌅"
        case .medium: return "☀️"
        case .high: return "🚀"
        }
    }

    var sfSymbol: String {
        switch self {
        case .low:    return "moon.zzz.fill"
        case .medium: return "sun.max.fill"
        case .high:   return "bolt.fill"
        }
    }

    var symbolColor: Color {
        switch self {
        case .low:    return AppColors.sage
        case .medium: return AppColors.amber
        case .high:   return Color(hex: "#E07A7A")
        }
    }

    var suggestedWorkDuration: TimeInterval {
        switch self {
        case .low: return 10 * 60
        case .medium: return 25 * 60
        case .high: return 45 * 60
        }
    }

    var suggestedBreakDuration: TimeInterval {
        switch self {
        case .low: return 3 * 60
        case .medium: return 5 * 60
        case .high: return 10 * 60
        }
    }

    /// Duration adjusted for the chosen session mode.
    /// High energy = full mode duration; lower energy scales down proportionally.
    func adjustedDuration(for mode: SessionMode) -> TimeInterval {
        switch (self, mode) {
        case (.low,    .deepWork):    return 25 * 60
        case (.medium, .deepWork):    return 35 * 60
        case (.high,   .deepWork):    return 50 * 60

        case (.low,    .standard):    return 12 * 60
        case (.medium, .standard):    return 20 * 60
        case (.high,   .standard):    return 25 * 60

        case (.low,    .quickSprint): return 10 * 60
        case (.medium, .quickSprint): return 12 * 60
        case (.high,   .quickSprint): return 15 * 60

        case (.low,    .micro):       return  5 * 60
        case (.medium, .micro):       return  8 * 60
        case (.high,   .micro):       return 10 * 60

        case (.low,    .ultraShort):  return  3 * 60
        case (.medium, .ultraShort):  return  4 * 60
        case (.high,   .ultraShort):  return  5 * 60
        }
    }

    /// Whether the adjusted duration differs from the mode's default (i.e. energy is not at full).
    func needsAdjustment(for mode: SessionMode) -> Bool {
        adjustedDuration(for: mode) < mode.workDuration
    }
}

// MARK: - Timer State
enum TimerState: Equatable {
    case idle
    case workRunning
    case workPaused
    /// Work phase finished — waiting for user to consciously start the break.
    case breakReady
    case breakRunning
    case breakPaused
    /// Break finished — waiting for user to consciously start the next work session.
    case workReady
    case sessionComplete(totalSessions: Int)
}

// MARK: - Timer Phase
enum TimerPhase {
    case work
    case shortBreak
    case longBreak
}

// MARK: - Break Enforcement
enum BreakEnforcement: String, CaseIterable {
    case gentle = "gentle"
    case firm = "firm"
    case off = "off"

    var displayName: String {
        switch self {
        case .gentle: return L10n.breakEnforcementGentle
        case .firm: return L10n.breakEnforcementFirm
        case .off: return L10n.breakEnforcementOff
        }
    }
}

// MARK: - Onboarding Challenge
enum OnboardingChallenge: String, CaseIterable, Identifiable {
    case timeBlinness = "time_blindness"
    case procrastination = "procrastination"
    case deepWork = "deep_work"
    case justATimer = "just_a_timer"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .timeBlinness: return "⏰"
        case .procrastination: return "😅"
        case .deepWork: return "🧠"
        case .justATimer: return "⏱"
        }
    }

    var title: String {
        switch self {
        case .timeBlinness: return L10n.challengeTimeBlinndess
        case .procrastination: return L10n.challengeProcrastination
        case .deepWork: return L10n.challengeDeepWork
        case .justATimer: return L10n.challengeJustTimer
        }
    }

    var recommendedMode: SessionMode {
        switch self {
        case .timeBlinness: return .micro
        case .procrastination: return .standard
        case .deepWork: return .deepWork
        case .justATimer: return .standard
        }
    }
}

// MARK: - Soundscape
struct Soundscape: Identifiable, Hashable {
    let id: String
    let name: String
    let emoji: String
    let sfSymbol: String
    let filename: String?
    let isPremium: Bool

    static var all: [Soundscape] { [
        Soundscape(id: "none",        name: L10n.soundNone,       emoji: "🔇", sfSymbol: "speaker.slash.fill",  filename: nil,          isPremium: false),
        Soundscape(id: "rain",        name: L10n.soundRain,       emoji: "🌧", sfSymbol: "cloud.rain.fill",      filename: "rain",        isPremium: false),
        Soundscape(id: "cafe",        name: L10n.soundCafe,       emoji: "☕", sfSymbol: "cup.and.saucer.fill",  filename: "cafe",        isPremium: false),
        Soundscape(id: "white_noise", name: L10n.soundWhiteNoise, emoji: "🌊", sfSymbol: "waveform",             filename: "white_noise", isPremium: false),
        Soundscape(id: "brown_noise", name: L10n.soundBrownNoise, emoji: "🎧", sfSymbol: "headphones",           filename: "brown_noise", isPremium: false),
        Soundscape(id: "forest",      name: L10n.soundForest,     emoji: "🌲", sfSymbol: "leaf.fill",            filename: "forest",      isPremium: false),
        Soundscape(id: "lofi",        name: L10n.soundLofi,       emoji: "🎵", sfSymbol: "music.note",           filename: "lofi",        isPremium: true),
        Soundscape(id: "fireplace",   name: L10n.soundFireplace,  emoji: "🔥", sfSymbol: "flame.fill",           filename: "fireplace",   isPremium: true),
        Soundscape(id: "ocean",       name: L10n.soundOcean,      emoji: "🌊", sfSymbol: "water.waves",          filename: "ocean",       isPremium: true),
        Soundscape(id: "library",     name: L10n.soundLibrary,    emoji: "📚", sfSymbol: "books.vertical.fill",  filename: "library",     isPremium: true),
        Soundscape(id: "deep_space",  name: L10n.soundDeepSpace,  emoji: "🚀", sfSymbol: "moon.stars.fill",      filename: "deep_space",  isPremium: true),
        Soundscape(id: "wind",        name: L10n.soundWind,       emoji: "🌬", sfSymbol: "wind",                 filename: "wind",        isPremium: true),
    ] }

    static func find(id: String) -> Soundscape? {
        all.first { $0.id == id }
    }
}

// MARK: - Paywall Feature
enum PaywallFeature {
    case microCommitmentLimit
    case liveActivity
    case analytics
    case streakProtection

    var title: String {
        switch self {
        case .microCommitmentLimit: return L10n.paywallMicroLimit
        case .liveActivity: return L10n.paywallLiveActivity
        case .analytics: return L10n.paywallAnalytics
        case .streakProtection: return L10n.paywallStreak
        }
    }
}
