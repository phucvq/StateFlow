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
        static let timerStateRaw  = "vm_timerStateRaw"  // full state string
        static let phase          = "vm_phase"           // "work" | "break"
        static let sessionNumber  = "vm_sessionNumber"
        static let workDuration   = "vm_workDuration"
        static let breakDuration  = "vm_breakDuration"
        static let modeRaw        = "vm_mode"
        static let isMicroMode    = "vm_isMicroMode"
        static let taskName       = "vm_taskName"
        static let totalSessions  = "vm_totalSessions"
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
            saveVMState()
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
            saveVMState()
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
            saveVMState()
        case .breakPaused:
            timerService.resume()
            timerState = .breakRunning
            saveVMState()
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
        saveVMState()
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
        saveVMState()
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
            // Mark micro session record as completed (same as normal path)
            let microCtx = modelContext ?? storedModelContext
            if let context = microCtx, let startDate = currentSessionStartDate {
                let descriptor = FetchDescriptor<SessionRecord>(
                    predicate: #Predicate { $0.statusRaw == "in_progress" }
                )
                if let records = try? context.fetch(descriptor),
                   let record = records.first(where: { $0.startedAt >= startDate.addingTimeInterval(-5) }) {
                    record.actualWorkDuration = workDuration
                    record.status = .completed
                    record.endedAt = Date()
                    try? context.save()
                }
            }
            // Update streak + widget (micro sessions count toward today's focus)
            UserPreferences.shared.updateStreak()
            syncWidgetData(addedMinutes: Int(workDuration / 60))
            timerState = .sessionComplete(totalSessions: currentSessionNumber)
            saveVMState()
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

        // Sync widget — increment focus time by this session's duration so the widget
        // shows up-to-date data immediately without waiting for Analytics tab to open.
        // AnalyticsViewModel.syncWidgetData() will do a full recalculate on next open.
        syncWidgetData(addedMinutes: Int(workDuration / 60))

        // Don't auto-start break — wait for user confirmation
        if currentSessionNumber >= totalSessionsInSequence {
            // Last session: pause then dismiss in a single atomic Task so there's no
            // race between an updateActivity Task and a separate endActivity Task.
            // Without this, the two racing Tasks can leave the widget in the old state
            // (isPaused:false, sessionEndDate in the past) just before dismissal.
            if isPremium {
                liveActivity.pauseAndEnd(
                    phaseDuration: workDuration,
                    timerPhase: .work,
                    sessionMode: selectedMode.displayName,
                    taskName: currentTaskName
                )
            }
            timerState = .sessionComplete(totalSessions: currentSessionNumber)
            saveVMState()
        } else {
            // Intermediate session: freeze the display while user decides to start break.
            // Widget uses ClampedTimerText so even if this update arrives late, it shows
            // "0:00" rather than counting up.
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
            saveVMState()
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
        saveVMState()

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
        // The widget's ClampedTimerText acts as the primary guard against count-up
        // during the async propagation window; this update ensures correct paused
        // state once it arrives.
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
        saveVMState()
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
        saveVMState()
    }

    func continueMicroCommitment(withDuration duration: TimeInterval) {
        isMicroMode = false
        workDuration = duration
        timerState = .workRunning
        timeRemaining = duration
        timerService.start(duration: duration)
        notificationService.scheduleSessionEnd(in: duration, taskName: currentTaskName)
        saveVMState()
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

    // MARK: - Widget Sync

    /// Increments today's focus minutes (and all-time hours) by `addedMinutes` and
    /// writes the result to the shared App Group UserDefaults so the home screen
    /// widget refreshes immediately after every session — without waiting for the
    /// Analytics tab to open (which does a full recalculate).
    ///
    /// AnalyticsViewModel.syncWidgetData() will overwrite with authoritative values
    /// the next time the user opens Analytics, so any minor drift is self-correcting.
    private func syncWidgetData(addedMinutes: Int) {
        var data = WidgetDataWriter.read()
        // Reset today's count if the stored date is not today
        let today = Calendar.current.startOfDay(for: Date())
        if let lastDate = data.lastSessionDate,
           Calendar.current.startOfDay(for: lastDate) < today {
            data.todayFocusMinutes = 0
        }
        data.todayFocusMinutes  += addedMinutes
        data.weekFocusMinutes   += addedMinutes
        data.totalFocusHours    += Double(addedMinutes) / 60.0
        data.currentStreak       = UserPreferences.shared.streakCurrentDays
        data.longestStreak       = max(UserPreferences.shared.streakLongestDays,
                                       UserPreferences.shared.streakCurrentDays)
        data.lastSessionTaskName = currentTaskName
        data.lastSessionDate     = Date()
        WidgetDataWriter.write(data)
    }

    // MARK: - VM State Persistence (survives app kill in background)

    private var persistedStateRaw: String {
        switch timerState {
        case .idle:                                  return "idle"
        case .workRunning:                           return "workRunning"
        case .workPaused:                            return "workPaused"
        case .breakReady:                            return "breakReady"
        case .breakRunning:                          return "breakRunning"
        case .breakPaused:                           return "breakPaused"
        case .workReady:                             return "workReady"
        case .sessionComplete:                       return "sessionComplete"
        }
    }

    private func saveVMState() {
        let ud = UserDefaults.standard
        ud.set(persistedStateRaw,                         forKey: VMPersistKey.timerStateRaw)
        ud.set(currentPhase == .work ? "work" : "break",  forKey: VMPersistKey.phase)
        ud.set(currentSessionNumber,                       forKey: VMPersistKey.sessionNumber)
        ud.set(workDuration,                               forKey: VMPersistKey.workDuration)
        ud.set(breakDuration,                              forKey: VMPersistKey.breakDuration)
        ud.set(selectedMode.rawValue,                      forKey: VMPersistKey.modeRaw)
        ud.set(isMicroMode,                                forKey: VMPersistKey.isMicroMode)
        ud.set(currentTaskName,                            forKey: VMPersistKey.taskName)
        ud.set(totalSessionsInSequence,                    forKey: VMPersistKey.totalSessions)
    }

    private func clearVMState() {
        let ud = UserDefaults.standard
        [VMPersistKey.timerStateRaw, VMPersistKey.phase, VMPersistKey.sessionNumber,
         VMPersistKey.workDuration, VMPersistKey.breakDuration, VMPersistKey.modeRaw,
         VMPersistKey.isMicroMode, VMPersistKey.taskName, VMPersistKey.totalSessions
        ].forEach { ud.removeObject(forKey: $0) }
    }

    /// Called after `timerService.restoreState()` in `init()`.
    /// Restores ALL TimerState cases — including breakReady / workReady / sessionComplete
    /// (which have no running timer) and paused states.
    ///
    /// Key design decisions:
    /// • Keyed on `timerStateRaw` (not just phase), so every state survives a kill.
    /// • For workRunning/breakRunning with an expired timer (screen-off scenario), we
    ///   derive the correct *next* state rather than calling handleWorkComplete, which
    ///   requires a ModelContext we don't have at init time.  SwiftData cleanup (marking
    ///   the in-progress record .completed) is deferred to the view via storedModelContext
    ///   or the next time the user explicitly ends/starts a session.
    private func restoreVMState() {
        let ud = UserDefaults.standard

        guard let stateRaw = ud.string(forKey: VMPersistKey.timerStateRaw),
              stateRaw != "idle" else { return }

        // --- Restore shared context ---
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

        let savedTotal = ud.integer(forKey: VMPersistKey.totalSessions)
        if savedTotal > 0 { totalSessionsInSequence = savedTotal }

        isMicroMode     = ud.bool(forKey: VMPersistKey.isMicroMode)
        currentTaskName = ud.string(forKey: VMPersistKey.taskName)

        // --- Restore state ---
        switch stateRaw {

        // Static "waiting" states — no timer needed
        case "breakReady":
            timerState    = .breakReady
            currentPhase  = .work
            timeRemaining = 0
            progress      = 1.0

        case "workReady":
            timerState    = .workReady
            currentPhase  = currentSessionNumber >= totalSessionsInSequence ? .longBreak : .shortBreak
            timeRemaining = 0
            progress      = 1.0

        case "sessionComplete":
            timerState    = .sessionComplete(totalSessions: currentSessionNumber)
            timeRemaining = 0
            progress      = 1.0

        // Active work timer
        case "workRunning", "workPaused":
            let tr = timerService.timeRemaining
            if tr <= 0 {
                // Timer expired while app was killed (screen-off scenario).
                // Transition to the correct post-work state without calling
                // handleWorkComplete (no ModelContext in init).
                timerService.stop()
                if isMicroMode || currentSessionNumber >= totalSessionsInSequence {
                    timerState = .sessionComplete(totalSessions: currentSessionNumber)
                } else {
                    timerState = .breakReady
                }
                currentPhase  = .work
                timeRemaining = 0
                progress      = 1.0
            } else {
                timerState    = stateRaw == "workPaused" ? .workPaused : .workRunning
                currentPhase  = .work
                timeRemaining = tr
                progress      = timerService.progress
            }

        // Active break timer
        case "breakRunning", "breakPaused":
            let tr = timerService.timeRemaining
            if tr <= 0 {
                // Break expired while killed — advance session counter and wait.
                timerService.stop()
                currentSessionNumber += 1
                timerState    = .workReady
                currentPhase  = .shortBreak
                timeRemaining = 0
                progress      = 1.0
            } else {
                timerState    = stateRaw == "breakPaused" ? .breakPaused : .breakRunning
                currentPhase  = currentSessionNumber >= totalSessionsInSequence ? .longBreak : .shortBreak
                timeRemaining = tr
                progress      = timerService.progress
            }

        default:
            break
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

    // MARK: - Foreground Recovery

    /// Call this when the app returns to the foreground (scenePhase → .active).
    /// If a session or break is running but the Live Activity was never started
    /// (e.g. auto-start fired while the app was in the background), we restart it here.
    func handleForeground() {
        guard isPremium else { return }
        let liveActivityService = LiveActivityService.shared
        // Only recover if there's no existing activity
        guard !liveActivityService.hasActiveActivity else { return }

        switch timerState {
        case .workRunning, .workPaused:
            let elapsed = timerService.elapsedTime
            liveActivityService.startActivity(
                sessionId: UUID(),
                phaseStartDate: Date().addingTimeInterval(-elapsed),
                phaseDuration: workDuration,
                timerPhase: .work,
                sessionMode: selectedMode.displayName,
                taskName: currentTaskName
            )
            // If paused, immediately update to paused state
            if timerState == .workPaused {
                liveActivityService.updateActivity(
                    phaseStartDate: Date(),
                    phaseDuration: workDuration,
                    timerPhase: .work,
                    sessionMode: selectedMode.displayName,
                    taskName: currentTaskName,
                    isPaused: true,
                    pausedElapsed: elapsed
                )
            }
        case .breakRunning, .breakPaused:
            let elapsed = timerService.elapsedTime
            let phase: TimerPhase = currentSessionNumber >= totalSessionsInSequence ? .longBreak : .shortBreak
            liveActivityService.startActivity(
                sessionId: UUID(),
                phaseStartDate: Date().addingTimeInterval(-elapsed),
                phaseDuration: breakDuration,
                timerPhase: phase,
                sessionMode: selectedMode.displayName,
                taskName: currentTaskName
            )
            if timerState == .breakPaused {
                liveActivityService.updateActivity(
                    phaseStartDate: Date(),
                    phaseDuration: breakDuration,
                    timerPhase: phase,
                    sessionMode: selectedMode.displayName,
                    taskName: currentTaskName,
                    isPaused: true,
                    pausedElapsed: elapsed
                )
            }
        default:
            break
        }
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
