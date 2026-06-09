import Foundation
import SwiftUI
import SwiftData

@Observable
final class TimerViewModel {

    // MARK: - State Machine
    var timerState: TimerState = .idle
    var currentPhase: TimerPhase = .work
    var timeRemaining: TimeInterval = 0
    var progress: Double = 0
    var currentSessionNumber: Int = 1
    var totalSessionsInSequence: Int = 4

    // MARK: - Session Config
    var selectedMode: SessionMode = UserPreferences.shared.defaultMode
    var currentEnergyLevel: EnergyLevel? = nil
    var currentTaskName: String? = nil
    var workDuration: TimeInterval = 0
    var breakDuration: TimeInterval = 0

    // MARK: - Micro-Commitment
    var isMicroMode: Bool = false
    var microTaskName: String = ""

    // MARK: - UI State
    var showEnergyCheckin: Bool = false
    var showEnergyConfirmOverlay: Bool = false
    var pendingEnergy: EnergyLevel? = nil
    var showPaywall: Bool = false
    var showSoundscapePicker: Bool = false
    var showModeSelector: Bool = false
    var paywallTrigger: PaywallFeature = .microCommitmentLimit

    // MARK: - Services
    private let timerService = TimerService()
    private let notificationService = NotificationService.shared
    private let haptics = HapticService.shared
    private let liveActivity = LiveActivityService.shared

    // Set from ContentView via .onChange(of: subService.isPremium)
    var isPremium: Bool = false

    // MARK: - Current Session Reference (for SwiftData logging)
    private var currentSessionStartDate: Date?
    /// Stored so timer-completion callbacks (which have no view context) can still update SwiftData.
    private var storedModelContext: ModelContext?

    // MARK: - VM Persistence Keys
    private enum VMPersistKey {
        static let phase          = "vm_phase"          // "work" | "break"
        static let sessionNumber  = "vm_sessionNumber"
        static let workDuration   = "vm_workDuration"
        static let breakDuration  = "vm_breakDuration"
        static let modeRaw        = "vm_mode"
    }

    // MARK: - Init
    init() {
        setupMode(selectedMode)
        setupTimerCallbacks()
        timerService.restoreState()
        restoreVMState()
    }

    // MARK: - Setup Mode
    func setupMode(_ mode: SessionMode) {
        selectedMode = mode
        workDuration = mode.workDuration
        breakDuration = mode.breakDuration
        totalSessionsInSequence = mode.longBreakAfter
        if timerState == .idle {
            timeRemaining = workDuration
        }
    }

    func setupModeWithEnergy(_ energy: EnergyLevel, finalDuration: TimeInterval) {
        currentEnergyLevel = energy
        workDuration = finalDuration
        // Keep the mode's break duration — energy only adjusts work time
        breakDuration = selectedMode.breakDuration
        if timerState == .idle {
            timeRemaining = workDuration
        }
    }

    // MARK: - Start Session
    func startSession(in modelContext: ModelContext? = nil) {
        guard timerState == .idle else { return }

        // Check energy check-in
        if UserPreferences.shared.energyCheckInEnabled && currentEnergyLevel == nil {
            showEnergyCheckin = true
            return
        }

        beginWork(modelContext: modelContext)
    }

    /// Called from EnergyCheckinView after user confirms.
    /// `finalDuration` is either the adjusted duration or the mode's original duration.
    /// Called when user picks an energy level — stores pending, closes sheet.
    func energySelected(_ energy: EnergyLevel) {
        pendingEnergy = energy
        showEnergyCheckin = false
    }

    /// Called from confirm overlay with the final chosen duration.
    func startAfterEnergyCheckIn(energy: EnergyLevel, finalDuration: TimeInterval, modelContext: ModelContext? = nil) {
        setupModeWithEnergy(energy, finalDuration: finalDuration)
        pendingEnergy = nil
        showEnergyConfirmOverlay = false
        beginWork(modelContext: modelContext)
    }

    func cancelEnergyConfirm() {
        pendingEnergy = nil
        showEnergyConfirmOverlay = false
    }

    private func beginWork(modelContext: ModelContext?) {
        storedModelContext = modelContext ?? storedModelContext
        timerState = .workRunning
        currentPhase = .work
        currentSessionStartDate = Date()
        timeRemaining = workDuration

        timerService.start(duration: workDuration)
        notificationService.scheduleSessionEnd(in: workDuration, taskName: currentTaskName)
        haptics.sessionStart()
        saveVMState()

        // Start Live Activity (Premium only, iOS 16.2+)
        if isPremium {
            liveActivity.startActivity(
                sessionId: UUID(),
                phaseStartDate: Date(),
                phaseDuration: workDuration,
                timerPhase: .work,
                sessionMode: selectedMode.displayName,
                taskName: currentTaskName
            )
        }

        // Log session start in SwiftData
        if let context = modelContext {
            let record = SessionRecord(
                mode: selectedMode,
                plannedDuration: workDuration,
                taskName: currentTaskName,
                energyLevel: currentEnergyLevel,
                soundscapeId: UserPreferences.shared.selectedSoundscapeId
            )
            context.insert(record)
            try? context.save()
        }
    }

    // MARK: - Pause / Resume
    func pauseResume() {
        switch timerState {
        case .workRunning:
            timerService.pause()
            timerState = .workPaused
            notificationService.cancelSessionNotifications()
            if isPremium {
                liveActivity.updateActivity(
                    phaseStartDate: Date(),
                    phaseDuration: workDuration,
                    timerPhase: .work,
                    sessionMode: selectedMode.displayName,
                    taskName: currentTaskName,
                    isPaused: true,
                    pausedElapsed: timerService.elapsedTime
                )
            }
        case .workPaused:
            timerService.resume()
            timerState = .workRunning
            notificationService.scheduleSessionEnd(in: timerService.timeRemaining, taskName: currentTaskName)
            if isPremium {
                // phaseStartDate = now so sessionEndDate = now + remaining
                liveActivity.updateActivity(
                    phaseStartDate: Date().addingTimeInterval(-timerService.elapsedTime),
                    phaseDuration: workDuration,
                    timerPhase: .work,
                    sessionMode: selectedMode.displayName,
                    taskName: currentTaskName,
                    isPaused: false,
                    pausedElapsed: 0
                )
            }
        case .breakRunning:
            timerService.pause()
            timerState = .breakPaused
        case .breakPaused:
            timerService.resume()
            timerState = .breakRunning
        default:
            break
        }
        haptics.tap()
    }

    // MARK: - Skip Break
    func skipBreak() {
        guard timerState == .breakRunning || timerState == .breakPaused || timerState == .breakReady else { return }
        timerService.stop()
        currentSessionNumber += 1
        if isPremium { liveActivity.endActivity() }
        timerState = .workReady
    }

    /// Skip the current work session early and go to break.
    /// Available during workRunning / workPaused. Not available in micro-commitment mode.
    func skipToBreak() {
        guard !isMicroMode else { return }
        guard timerState == .workRunning || timerState == .workPaused else { return }
        timerService.stop()
        notificationService.cancelSessionNotifications()
        // Freeze Live Activity while user decides to start break
        if isPremium {
            liveActivity.updateActivity(
                phaseStartDate: Date(),
                phaseDuration: breakDuration,
                timerPhase: currentSessionNumber >= totalSessionsInSequence ? .longBreak : .shortBreak,
                sessionMode: selectedMode.displayName,
                taskName: currentTaskName,
                isPaused: true,
                pausedElapsed: 0
            )
        }
        timerState = .breakReady
    }

    /// Called when user taps "Start Session" on the workReady screen.
    func startNextSessionNow(modelContext: ModelContext? = nil) {
        guard timerState == .workReady else { return }
        startNextWorkSession(modelContext: modelContext ?? storedModelContext)
    }

    // MARK: - Extend Break
    func extendBreak(by minutes: Int = 5) {
        guard timerState == .breakRunning else { return }
        let additional = TimeInterval(minutes * 60)
        // Must capture remaining BEFORE stop() — stop() resets plannedDuration to 0
        // which makes timeRemaining return 0, causing the break to restart at only `additional`.
        let remaining = timerService.timeRemaining
        let newDuration = remaining + additional
        timerService.stop()
        timerService.start(duration: newDuration)
        // Recreate Live Activity with updated end date
        if isPremium {
            liveActivity.startActivity(
                sessionId: UUID(),
                phaseStartDate: Date(),
                phaseDuration: newDuration,
                timerPhase: currentPhase,
                sessionMode: selectedMode.displayName,
                taskName: currentTaskName
            )
        }
    }

    // MARK: - End Session
    func endSession(modelContext: ModelContext? = nil) {
        let elapsed = timerService.elapsedTime
        timerService.stop()
        notificationService.cancelSessionNotifications()

        // Update SwiftData record
        let ctx = modelContext ?? storedModelContext
        if let context = ctx, let startDate = currentSessionStartDate {
            let descriptor = FetchDescriptor<SessionRecord>(
                predicate: #Predicate { $0.statusRaw == "in_progress" }
            )
            if let records = try? context.fetch(descriptor),
               let record = records.first(where: { $0.startedAt >= startDate.addingTimeInterval(-5) }) {
                record.actualWorkDuration = elapsed
                record.status = .cancelled
                record.endedAt = Date()
                try? context.save()
            }
        }

        liveActivity.endActivity()
        resetToIdle()
        haptics.tap()
    }

    // MARK: - Session Complete (called by timer callback)
    private func handleWorkComplete(modelContext: ModelContext? = nil) {
        notificationService.cancelSessionNotifications()
        haptics.sessionComplete()

        // Micro-commitment always ends after one work session — no break loop
        if isMicroMode {
            if isPremium {
                // Pause display first so the timer freezes instead of counting up,
                // then dismiss — both happen in sequence inside a single Task.
                liveActivity.pauseAndEnd(
                    phaseDuration: workDuration,
                    timerPhase: .work,
                    sessionMode: "Micro",
                    taskName: currentTaskName
                )
            }
            timerState = .sessionComplete(totalSessions: currentSessionNumber)
            return
        }

        // Update record — fall back to context stored at session start
        let ctx = modelContext ?? storedModelContext
        if let context = ctx, let startDate = currentSessionStartDate {
            let descriptor = FetchDescriptor<SessionRecord>(
                predicate: #Predicate { $0.statusRaw == "in_progress" }
            )
            if let records = try? context.fetch(descriptor),
               let record = records.first(where: { $0.startedAt >= startDate.addingTimeInterval(-5) }) {
                record.actualWorkDuration = workDuration
                record.status = .completed
                record.endedAt = Date()
                record.breakCount += 1
                try? context.save()
            }
        }

        // Update streak
        UserPreferences.shared.updateStreak()

        // Sync widget data (partial — AnalyticsViewModel fills weekly/all-time on next open)
        var existing = WidgetDataWriter.read()
        existing.currentStreak = UserPreferences.shared.streakCurrentDays
        existing.longestStreak = max(UserPreferences.shared.streakLongestDays, UserPreferences.shared.streakCurrentDays)
        existing.lastSessionTaskName = currentTaskName
        existing.lastSessionDate = Date()
        WidgetDataWriter.write(existing)

        // Pause Live Activity display while user decides whether to break
        if isPremium {
            liveActivity.updateActivity(
                phaseStartDate: Date(),
                phaseDuration: breakDuration,
                timerPhase: currentSessionNumber >= totalSessionsInSequence ? .longBreak : .shortBreak,
                sessionMode: selectedMode.displayName,
                taskName: currentTaskName,
                isPaused: true,
                pausedElapsed: 0
            )
        }

        // Don't auto-start break — wait for user confirmation
        if currentSessionNumber >= totalSessionsInSequence {
            liveActivity.endActivity()
            timerState = .sessionComplete(totalSessions: currentSessionNumber)
        } else {
            timerState = .breakReady
        }
    }

    /// Called when user taps "Start Break" on the breakReady screen.
    func startBreakNow() {
        guard timerState == .breakReady else { return }
        startBreak()
    }

    // MARK: - Break
    private func startBreak() {
        timerState = .breakRunning
        currentPhase = currentSessionNumber >= totalSessionsInSequence ? .longBreak : .shortBreak
        timeRemaining = breakDuration
        timerService.start(duration: breakDuration)
        notificationService.scheduleBreakEnd(in: breakDuration)
        saveVMState()

        // End existing activity and create a fresh one for the break phase
        if isPremium {
            liveActivity.startActivity(
                sessionId: UUID(),
                phaseStartDate: Date(),
                phaseDuration: breakDuration,
                timerPhase: currentPhase,
                sessionMode: selectedMode.displayName,
                taskName: currentTaskName
            )
        }
    }

    private func startNextWorkSession(modelContext: ModelContext? = nil) {
        timerState = .workRunning
        currentPhase = .work
        currentSessionStartDate = Date()
        timeRemaining = workDuration
        timerService.start(duration: workDuration)
        notificationService.scheduleSessionEnd(in: workDuration, taskName: currentTaskName)
        haptics.sessionStart()

        // End existing break activity and create a fresh work activity
        if isPremium {
            liveActivity.startActivity(
                sessionId: UUID(),
                phaseStartDate: Date(),
                phaseDuration: workDuration,
                timerPhase: .work,
                sessionMode: selectedMode.displayName,
                taskName: currentTaskName
            )
        }

        // Log new SwiftData record for this session
        let ctx = modelContext ?? storedModelContext
        if let context = ctx {
            let record = SessionRecord(
                mode: selectedMode,
                plannedDuration: workDuration,
                taskName: currentTaskName,
                energyLevel: currentEnergyLevel,
                soundscapeId: UserPreferences.shared.selectedSoundscapeId,
                sessionNumber: currentSessionNumber
            )
            context.insert(record)
            try? context.save()
        }
    }

    private func handleBreakComplete() {
        haptics.breakEnd()
        notificationService.cancelSessionNotifications()
        currentSessionNumber += 1
        // Freeze Live Activity while user decides to start next session.
        // Without this update, sessionEndDate is now in the past and
        // Text(.timer) counts UP — the counting-up bug.
        if isPremium {
            liveActivity.updateActivity(
                phaseStartDate: Date(),
                phaseDuration: workDuration,
                timerPhase: .work,
                sessionMode: selectedMode.displayName,
                taskName: currentTaskName,
                isPaused: true,
                pausedElapsed: 0
            )
        }
        // Don't auto-start next work session — wait for user
        timerState = .workReady
    }

    // MARK: - Timer Callbacks
    private func setupTimerCallbacks() {
        timerService.onTick = { [weak self] remaining in
            guard let self else { return }
            DispatchQueue.main.async {
                self.timeRemaining = remaining
                self.progress = self.timerService.progress

                // 1-minute warning
                if remaining <= 60 && remaining > 59 {
                    self.haptics.oneMinuteWarning()
                }
                // Live Activity countdown is driven by sessionEndDate in the widget —
                // no per-tick push needed. Only update on phase/pause state changes.
            }
        }

        timerService.onComplete = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.timeRemaining = 0
                self.progress = 1.0
                switch self.timerState {
                case .workRunning, .workPaused:
                    self.handleWorkComplete()
                case .breakRunning, .breakPaused:
                    self.handleBreakComplete()
                default:
                    break
                }
            }
        }
    }

    // MARK: - Micro-Commitment
    func startMicroCommitment(taskName: String, modelContext: ModelContext? = nil) {
        // Check free tier limit
        isMicroMode = true
        currentTaskName = taskName.isEmpty ? nil : taskName
        workDuration = 2 * 60  // 2 minutes
        breakDuration = 0

        timerState = .workRunning
        currentPhase = .work
        currentSessionStartDate = Date()
        timeRemaining = workDuration
        timerService.start(duration: workDuration)
        haptics.sessionStart()
        notificationService.scheduleSessionEnd(in: workDuration, taskName: currentTaskName)
        if isPremium {
            liveActivity.startActivity(
                sessionId: UUID(),
                phaseStartDate: Date(),
                phaseDuration: workDuration,
                timerPhase: .work,
                sessionMode: "Micro",
                taskName: currentTaskName
            )
        }

        // Increment usage counter
        UserPreferences.shared.microCommitmentUsedToday += 1
    }

    func continueMicroCommitment(withDuration duration: TimeInterval) {
        isMicroMode = false
        workDuration = duration
        timerState = .workRunning
        timeRemaining = duration
        timerService.start(duration: duration)
        notificationService.scheduleSessionEnd(in: duration, taskName: currentTaskName)
        if isPremium {
            liveActivity.startActivity(
                sessionId: UUID(),
                phaseStartDate: Date(),
                phaseDuration: duration,
                timerPhase: .work,
                sessionMode: selectedMode.displayName,
                taskName: currentTaskName
            )
        }
    }

    // MARK: - Check Free Limits
    func canUseMicroCommitment(isPremium: Bool) -> Bool {
        if isPremium { return true }
        return UserPreferences.shared.microCommitmentUsedToday < 3
    }

    // MARK: - VM State Persistence (survives app kill in background)

    private func saveVMState() {
        let ud = UserDefaults.standard
        ud.set(currentPhase == .work ? "work" : "break", forKey: VMPersistKey.phase)
        ud.set(currentSessionNumber,                      forKey: VMPersistKey.sessionNumber)
        ud.set(workDuration,                              forKey: VMPersistKey.workDuration)
        ud.set(breakDuration,                             forKey: VMPersistKey.breakDuration)
        ud.set(selectedMode.rawValue,                     forKey: VMPersistKey.modeRaw)
    }

    private func clearVMState() {
        let ud = UserDefaults.standard
        ud.removeObject(forKey: VMPersistKey.phase)
        ud.removeObject(forKey: VMPersistKey.sessionNumber)
        ud.removeObject(forKey: VMPersistKey.workDuration)
        ud.removeObject(forKey: VMPersistKey.breakDuration)
        ud.removeObject(forKey: VMPersistKey.modeRaw)
    }

    /// Called after `timerService.restoreState()` in `init()`.
    /// If TimerService has an active timer, sync TimerViewModel state accordingly
    /// so the UI doesn't fall back to the Home screen after an app kill.
    private func restoreVMState() {
        let ud = UserDefaults.standard
        guard timerService.plannedDuration > 0,
              timerService.timeRemaining > 0 else { return }

        // Restore durations & mode so card/UI display is correct
        if let modeRaw = ud.string(forKey: VMPersistKey.modeRaw),
           let mode = SessionMode(rawValue: modeRaw) {
            selectedMode = mode
        }
        let savedWork  = ud.double(forKey: VMPersistKey.workDuration)
        let savedBreak = ud.double(forKey: VMPersistKey.breakDuration)
        if savedWork  > 0 { workDuration  = savedWork  }
        if savedBreak > 0 { breakDuration = savedBreak }

        let savedSession = ud.integer(forKey: VMPersistKey.sessionNumber)
        if savedSession > 0 { currentSessionNumber = savedSession }

        let phase = ud.string(forKey: VMPersistKey.phase) ?? "work"
        timeRemaining = timerService.timeRemaining
        progress      = timerService.progress

        if phase == "break" {
            timerState   = .breakRunning
            currentPhase = .shortBreak
        } else {
            timerState   = .workRunning
            currentPhase = .work
        }
    }

    // MARK: - Reset
    func resetToIdle() {
        timerState = .idle
        currentPhase = .work
        currentSessionNumber = 1
        currentEnergyLevel = nil
        currentTaskName = nil
        isMicroMode = false
        // Reset durations to mode default so card shows correct value
        workDuration  = selectedMode.workDuration
        breakDuration = selectedMode.breakDuration
        timeRemaining = workDuration
        progress = 0
        clearVMState()
    }

    func dismissSessionComplete() {
        resetToIdle()
    }

    // MARK: - Computed
    var isRunning: Bool {
        timerState == .workRunning || timerState == .breakRunning
    }

    var isPaused: Bool {
        timerState == .workPaused || timerState == .breakPaused
    }

    var isIdle: Bool {
        timerState == .idle
    }

    var isInBreak: Bool {
        timerState == .breakRunning || timerState == .breakPaused || timerState == .breakReady
    }

    var isBreakReady: Bool { timerState == .breakReady }
    var isWorkReady: Bool  { timerState == .workReady }

    var phaseColor: Color {
        switch currentPhase {
        case .work: return AppColors.indigo
        case .shortBreak: return AppColors.sage
        case .longBreak: return AppColors.amber
        }
    }

    var formattedTimeRemaining: String {
        timeRemaining.timerString
    }
}
