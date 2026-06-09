import Foundation
import SwiftUI

// MARK: - Localization Manager
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    private init() {}

    // English-only for now. Multi-language support is preserved but disabled.
    @Published var currentLanguage: AppLanguage = .english

    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: "pref_app_language")
        objectWillChange.send()
    }

    var bundle: Bundle {
        // Always use English bundle regardless of UserDefaults
        return Bundle.main.path(forResource: "en", ofType: "lproj")
            .flatMap(Bundle.init) ?? .main
    }
}

// MARK: - L10n
// Centralized localization key access
enum L10n {
    // MARK: - Generic helper
    static func string(_ key: String) -> String {
        NSLocalizedString(key, bundle: LocalizationManager.shared.bundle, comment: "")
    }

    // MARK: - Tabs
    static var tabHome: String { NSLocalizedString("tab.home", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var tabStats: String { NSLocalizedString("tab.stats", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var tabSettings: String { NSLocalizedString("tab.settings", bundle: LocalizationManager.shared.bundle, comment: "") }

    // MARK: - Modes
    static var modeStandard: String { NSLocalizedString("mode.standard", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var modeDeepWork: String { NSLocalizedString("mode.deep_work", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var modeQuickSprint: String { NSLocalizedString("mode.quick_sprint", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var modeMicro: String { NSLocalizedString("mode.micro", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var modeUltraShort: String { NSLocalizedString("mode.ultra_short", bundle: LocalizationManager.shared.bundle, comment: "") }

    // MARK: - Energy
    static var energyTitle: String { NSLocalizedString("energy.title", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var energySubtitle: String { NSLocalizedString("energy.subtitle", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var energyLow: String { NSLocalizedString("energy.low", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var energyMedium: String { NSLocalizedString("energy.medium", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var energyHigh: String { NSLocalizedString("energy.high", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var energyLowDesc: String { NSLocalizedString("energy.low.desc", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var energyMediumDesc: String { NSLocalizedString("energy.medium.desc", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var energyHighDesc: String { NSLocalizedString("energy.high.desc", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var energySelectFirst: String { NSLocalizedString("energy.select_first", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var energyStartWith: String { NSLocalizedString("energy.start_with", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var energyConfirmContinue: String { NSLocalizedString("energy.confirm.continue", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var energyConfirmSuggested: String { NSLocalizedString("energy.confirm.suggested", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var energyConfirmFullSession: String { NSLocalizedString("energy.confirm.full_session", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var energyConfirmInstead: String { NSLocalizedString("energy.confirm.instead", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var energyConfirmAutoStart: String { NSLocalizedString("energy.confirm.auto_start", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var energyConfirmStart: String { NSLocalizedString("energy.confirm.start", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var energyConfirmKeepOriginal: String { NSLocalizedString("energy.confirm.keep_original", bundle: LocalizationManager.shared.bundle, comment: "") }

    // MARK: - Home
    static var homeStart: String { NSLocalizedString("home.start", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var homeTagline: String { NSLocalizedString("home.tagline", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var homeTodayMinutes: String { NSLocalizedString("home.today_minutes", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var homeMicroStartPrompt: String { NSLocalizedString("home.micro_start_prompt", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var homeMicroStartAction: String { NSLocalizedString("home.micro_start_action", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var greetingMorning: String { NSLocalizedString("greeting.morning", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var greetingAfternoon: String { NSLocalizedString("greeting.afternoon", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var greetingEvening: String { NSLocalizedString("greeting.evening", bundle: LocalizationManager.shared.bundle, comment: "") }

    // MARK: - Timer
    static var timerPhaseWork: String { NSLocalizedString("timer.phase.work", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var timerPhaseShortBreak: String { NSLocalizedString("timer.phase.short_break", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var timerPhaseLongBreak: String { NSLocalizedString("timer.phase.long_break", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var timerSession: String { NSLocalizedString("timer.session", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var timerWork: String { NSLocalizedString("timer.work", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var timerBreak: String { NSLocalizedString("timer.break", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var timerEndSession: String { NSLocalizedString("timer.end_session", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var timerRemaining: String { NSLocalizedString("timer.remaining", bundle: LocalizationManager.shared.bundle, comment: "") }

    // MARK: - Break
    static var breakTitle: String { NSLocalizedString("break.title", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var breakSkip: String { NSLocalizedString("break.skip", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var breakExtend: String { NSLocalizedString("break.extend", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var breakActivity1: String { NSLocalizedString("break.activity1", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var breakActivity2: String { NSLocalizedString("break.activity2", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var breakActivity3: String { NSLocalizedString("break.activity3", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var breakActivity4: String { NSLocalizedString("break.activity4", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var breakEnforcementGentle: String { NSLocalizedString("break.enforcement.gentle", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var breakEnforcementFirm: String { NSLocalizedString("break.enforcement.firm", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var breakEnforcementOff: String { NSLocalizedString("break.enforcement.off", bundle: LocalizationManager.shared.bundle, comment: "") }

    // MARK: - Micro
    static var microTitle: String { NSLocalizedString("micro.title", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var microSubtitle: String { NSLocalizedString("micro.subtitle", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var microTaskLabel: String { NSLocalizedString("micro.task_label", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var microTaskPlaceholder: String { NSLocalizedString("micro.task_placeholder", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var microStartButton: String { NSLocalizedString("micro.start_button", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var microUseRegular: String { NSLocalizedString("micro.use_regular", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var microCommitmentLabel: String { NSLocalizedString("micro.commitment_label", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var microCommitmentText: String { NSLocalizedString("micro.commitment_text", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var microPhaseLabel: String { NSLocalizedString("micro.phase_label", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var microEncouragement: String { NSLocalizedString("micro.encouragement", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var microCompleteTitle: String { NSLocalizedString("micro.complete_title", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var microCompleteSubtitle: String { NSLocalizedString("micro.complete_subtitle", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var microContinueWith: String { NSLocalizedString("micro.continue_with", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var microStopMessage: String { NSLocalizedString("micro.stop_message", bundle: LocalizationManager.shared.bundle, comment: "") }

    // MARK: - Analytics
    static var analyticsTitle: String { NSLocalizedString("analytics.title", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var analyticsSubtitle: String { NSLocalizedString("analytics.subtitle", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var analyticsWeeklyTitle: String { NSLocalizedString("analytics.weekly_title", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var analyticsWeeklyBlur: String { NSLocalizedString("analytics.weekly_blur", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var analyticsNoData: String { NSLocalizedString("analytics.no_data", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var analyticsEnergyTitle: String { NSLocalizedString("analytics.energy_title", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var analyticsEnergyNoData: String { NSLocalizedString("analytics.energy_no_data", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var statsToday: String { NSLocalizedString("stats.today", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var statsThisWeek: String { NSLocalizedString("stats.this_week", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var statsStreak: String { NSLocalizedString("stats.streak", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var statsLongestStreak: String { NSLocalizedString("stats.longest_streak", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var statsAllTime: String { NSLocalizedString("stats.all_time", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var statsCompletion: String { NSLocalizedString("stats.completion", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var statsSessions: String { NSLocalizedString("stats.sessions", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var statsFocused: String { NSLocalizedString("stats.focused", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var insightBestHour: String { NSLocalizedString("insight.best_hour", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var insightWeekTotal: String { NSLocalizedString("insight.week_total", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var insightWeekChange: String { NSLocalizedString("insight.week_change", bundle: LocalizationManager.shared.bundle, comment: "") }

    // MARK: - Milestones
    static var milestone7DaysTitle: String { NSLocalizedString("milestone.7days.title", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var milestone7DaysSubtitle: String { NSLocalizedString("milestone.7days.subtitle", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var milestone30DaysTitle: String { NSLocalizedString("milestone.30days.title", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var milestone30DaysSubtitle: String { NSLocalizedString("milestone.30days.subtitle", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var milestone100HoursTitle: String { NSLocalizedString("milestone.100hours.title", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var milestone100HoursSubtitle: String { NSLocalizedString("milestone.100hours.subtitle", bundle: LocalizationManager.shared.bundle, comment: "") }

    // MARK: - Session Complete
    static var completeTitle: String { NSLocalizedString("complete.title", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var completeSubtitle: String { NSLocalizedString("complete.subtitle", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var completeStartAnother: String { NSLocalizedString("complete.start_another", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var completeDone: String { NSLocalizedString("complete.done", bundle: LocalizationManager.shared.bundle, comment: "") }

    // MARK: - Streak
    static var streakDays: String { NSLocalizedString("streak.days", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var streakResetTitle: String { NSLocalizedString("streak.reset_title", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var streakResetMessage: String { NSLocalizedString("streak.reset_message", bundle: LocalizationManager.shared.bundle, comment: "") }

    // MARK: - Settings
    static var settingsSectionFocus: String { NSLocalizedString("settings.section.focus", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var settingsSectionSensory: String { NSLocalizedString("settings.section.sensory", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var settingsSectionApp: String { NSLocalizedString("settings.section.app", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var settingsEnergyCheckin: String { NSLocalizedString("settings.energy_checkin", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var settingsEnergyCheckinDesc: String { NSLocalizedString("settings.energy_checkin.desc", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var settingsBreakEnforcement: String { NSLocalizedString("settings.break_enforcement", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var settingsHaptics: String { NSLocalizedString("settings.haptics", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var settingsHapticsDesc: String { NSLocalizedString("settings.haptics.desc", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var settingsSoundVolume: String { NSLocalizedString("settings.sound_volume", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var settingsLanguage: String { NSLocalizedString("settings.language", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var settingsAbout: String { NSLocalizedString("settings.about", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var settingsPremiumActive: String { NSLocalizedString("settings.premium_active", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var settingsPremiumUpgrade: String { NSLocalizedString("settings.premium_upgrade", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var settingsPremiumDesc: String { NSLocalizedString("settings.premium.desc", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var settingsPremiumUpgradeDesc: String { NSLocalizedString("settings.premium_upgrade.desc", bundle: LocalizationManager.shared.bundle, comment: "") }

    // MARK: - Onboarding
    static var onboardingLanguageTitle: String { "Choose your language" }
    static var onboardingLanguageSubtitle: String { "You can change this later in Settings" }
    static var onboardingNext: String { NSLocalizedString("onboarding.next", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var onboardingGetStarted: String { NSLocalizedString("onboarding.get_started", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var onboardingWelcomeTitle: String { NSLocalizedString("onboarding.welcome.title", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var onboardingWelcomeTagline: String { NSLocalizedString("onboarding.welcome.tagline", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var onboardingWelcomeDesc: String { NSLocalizedString("onboarding.welcome.desc", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var onboardingChallengeTitle: String { NSLocalizedString("onboarding.challenge.title", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var onboardingChallengeSubtitle: String { NSLocalizedString("onboarding.challenge.subtitle", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var onboardingPersonalizeTitle: String { NSLocalizedString("onboarding.personalize.title", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var onboardingPersonalizeFor: String { NSLocalizedString("onboarding.personalize.for", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var onboardingRecommended: String { NSLocalizedString("onboarding.recommended", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var onboardingNotifTitle: String { NSLocalizedString("onboarding.notif.title", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var onboardingNotifDesc: String { NSLocalizedString("onboarding.notif.desc", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var onboardingNotifNote: String { NSLocalizedString("onboarding.notif.note", bundle: LocalizationManager.shared.bundle, comment: "") }

    // MARK: - Challenges
    static var challengeTimeBlinndess: String { NSLocalizedString("challenge.time_blindness", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var challengeProcrastination: String { NSLocalizedString("challenge.procrastination", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var challengeDeepWork: String { NSLocalizedString("challenge.deep_work", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var challengeJustTimer: String { NSLocalizedString("challenge.just_timer", bundle: LocalizationManager.shared.bundle, comment: "") }

    // MARK: - Paywall
    static var paywallTitle: String { NSLocalizedString("paywall.title", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var paywallSubtitle: String { NSLocalizedString("paywall.subtitle", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var paywallTrialCTA: String { NSLocalizedString("paywall.trial_cta", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var paywallMonthlyCTA: String { NSLocalizedString("paywall.monthly_cta", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var paywallFinePrint: String { NSLocalizedString("paywall.fine_print", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var paywallRestore: String { NSLocalizedString("paywall.restore", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var paywallMicroLimit: String { NSLocalizedString("paywall.micro_limit", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var paywallLiveActivity: String { NSLocalizedString("paywall.live_activity", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var paywallAnalytics: String { NSLocalizedString("paywall.analytics", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var paywallStreak: String { NSLocalizedString("paywall.streak", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var paywallFeature1: String { NSLocalizedString("paywallFeature1", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var paywallFeature2: String { NSLocalizedString("paywallFeature2", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var paywallFeature3: String { NSLocalizedString("paywallFeature3", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var paywallFeature4: String { NSLocalizedString("paywallFeature4", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var paywallFeature5: String { NSLocalizedString("paywallFeature5", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var paywallFeature6: String { NSLocalizedString("paywallFeature6", bundle: LocalizationManager.shared.bundle, comment: "") }

    // MARK: - Plans
    static var planAnnual: String { NSLocalizedString("plan.annual", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var planMonthly: String { NSLocalizedString("plan.monthly", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var planMonth: String { NSLocalizedString("plan.month", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var planBestValue: String { NSLocalizedString("plan.best_value", bundle: LocalizationManager.shared.bundle, comment: "") }

    // MARK: - Common
    static var premiumRequired: String { NSLocalizedString("common.premium_required", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var upgrade: String { NSLocalizedString("common.upgrade", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var change: String { NSLocalizedString("common.change", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var skip: String { NSLocalizedString("common.skip", bundle: LocalizationManager.shared.bundle, comment: "") }

    // MARK: - Soundscapes
    static var soundPickerTitle: String { NSLocalizedString("sound.picker_title", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var soundNone: String { NSLocalizedString("sound.none", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var soundRain: String { NSLocalizedString("sound.rain", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var soundCafe: String { NSLocalizedString("sound.cafe", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var soundWhiteNoise: String { NSLocalizedString("sound.white_noise", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var soundBrownNoise: String { NSLocalizedString("sound.brown_noise", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var soundForest: String { NSLocalizedString("sound.forest", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var soundLofi: String { NSLocalizedString("sound.lofi", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var soundFireplace: String { NSLocalizedString("sound.fireplace", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var soundOcean: String { NSLocalizedString("sound.ocean", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var soundLibrary: String { NSLocalizedString("sound.library", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var soundDeepSpace: String { NSLocalizedString("sound.deep_space", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var soundWind: String { NSLocalizedString("sound.wind", bundle: LocalizationManager.shared.bundle, comment: "") }

    // MARK: - Mode Selector
    static var modeSelectorTitle: String { NSLocalizedString("mode_selector.title", bundle: LocalizationManager.shared.bundle, comment: "") }

    // MARK: - Notifications
    static var notifSessionEndTitle: String { NSLocalizedString("notif.session_end.title", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var notifSessionEndBody: String { NSLocalizedString("notif.session_end.body", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var notifSessionEndBodyTask: String { NSLocalizedString("notif.session_end.body_task", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var notifBreakReminderTitle: String { NSLocalizedString("notif.break_reminder.title", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var notifBreakReminderBody: String { NSLocalizedString("notif.break_reminder.body", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var notifBreakEndTitle: String { NSLocalizedString("notif.break_end.title", bundle: LocalizationManager.shared.bundle, comment: "") }
    static var notifBreakEndBody: String { NSLocalizedString("notif.break_end.body", bundle: LocalizationManager.shared.bundle, comment: "") }
}
