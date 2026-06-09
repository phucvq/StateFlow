import Foundation
import ActivityKit   // Required: Activity<>, ActivityAuthorizationInfo, etc.
                     // Callers (TimerViewModel) do NOT need to import ActivityKit —
                     // our public interface uses only Foundation + TimerPhase types.

// MARK: - LiveActivityService
// Manages the ActivityKit Live Activity lifecycle.
// Public API uses TimerPhase (app-internal type) — no ActivityKit import needed by callers.
// Requires iOS 16.2+. All public methods no-op gracefully on older OS.

final class LiveActivityService {

    static let shared = LiveActivityService()
    private init() {}

    // MARK: - Public API (uses app-internal TimerPhase)

    /// Call when a phase starts (work, short break, long break).
    /// `phaseStartDate`: when this phase began counting. `phaseDuration`: total phase length.
    /// The Live Activity widget will use these to render a self-updating countdown via Text(.timer),
    /// so no per-second updates are needed for the time display.
    func startActivity(
        sessionId: UUID,
        phaseStartDate: Date = Date(),
        phaseDuration: TimeInterval,
        timerPhase: TimerPhase,
        sessionMode: String,
        taskName: String?
    ) {
        guard #available(iOS 16.2, *) else {
            print("[LiveActivity] Skipped: iOS 16.2+ required")
            return
        }
        let phase = toActivityPhase(timerPhase)
        Task {
            // Await end so we don't race with Activity.request
            await _endActivity()
            _startActivity(
                sessionId: sessionId,
                phaseStartDate: phaseStartDate,
                phaseDuration: phaseDuration,
                phase: phase,
                sessionMode: sessionMode,
                taskName: taskName
            )
        }
    }

    /// Call only when the phase changes (break ↔ work) or when pausing/resuming.
    /// Do NOT call every tick — the widget counts down automatically.
    func updateActivity(
        phaseStartDate: Date = Date(),
        phaseDuration: TimeInterval,
        timerPhase: TimerPhase,
        sessionMode: String,
        taskName: String?,
        isPaused: Bool = false,
        pausedElapsed: TimeInterval = 0
    ) {
        guard #available(iOS 16.2, *) else { return }
        let phase = toActivityPhase(timerPhase)
        Task {
            await _updateActivity(
                phaseStartDate: phaseStartDate,
                phaseDuration: phaseDuration,
                phase: phase,
                sessionMode: sessionMode,
                taskName: taskName,
                isPaused: isPaused,
                pausedElapsed: pausedElapsed
            )
        }
    }

    func endActivity() {
        guard #available(iOS 16.2, *) else { return }
        Task { await _endActivity() }
    }

    /// Freeze the timer display (isPaused = true) then dismiss the Live Activity.
    /// Use this instead of endActivity() when the phase has just completed —
    /// prevents the timer widget from counting *up* in the brief async window
    /// between session completion and dismissal.
    /// Returns true if there is a currently active Live Activity.
    /// Use this to detect when the activity was missed (e.g. started while app was in background).
    var hasActiveActivity: Bool {
        guard #available(iOS 16.2, *) else { return false }
        return currentActivity() != nil
    }

    func pauseAndEnd(
        phaseDuration: TimeInterval,
        timerPhase: TimerPhase,
        sessionMode: String,
        taskName: String?
    ) {
        guard #available(iOS 16.2, *) else { return }
        let phase = toActivityPhase(timerPhase)
        Task {
            await _updateActivity(
                phaseStartDate: Date(),
                phaseDuration: phaseDuration,
                phase: phase,
                sessionMode: sessionMode,
                taskName: taskName,
                isPaused: true,
                pausedElapsed: 0
            )
            await _endActivity()
        }
    }
}

// MARK: - TimerPhase → ActivityPhase (private, app-only)
private extension LiveActivityService {
    func toActivityPhase(_ phase: TimerPhase) -> ActivityPhase {
        switch phase {
        case .work:       return .work
        case .shortBreak: return .shortBreak
        case .longBreak:  return .longBreak
        }
    }
}

// MARK: - iOS 16.2+ Implementation
@available(iOS 16.2, *)
private extension LiveActivityService {

    nonisolated(unsafe) static var _activityRef: Any? = nil

    func currentActivity() -> Activity<FlowStateActivityAttributes>? {
        LiveActivityService._activityRef as? Activity<FlowStateActivityAttributes>
    }

    func setActivity(_ activity: Activity<FlowStateActivityAttributes>?) {
        LiveActivityService._activityRef = activity
    }

    func _startActivity(
        sessionId: UUID,
        phaseStartDate: Date,
        phaseDuration: TimeInterval,
        phase: ActivityPhase,
        sessionMode: String,
        taskName: String?
    ) {
        let authInfo = ActivityAuthorizationInfo()
        print("[LiveActivity] areActivitiesEnabled=\(authInfo.areActivitiesEnabled)")
        guard authInfo.areActivitiesEnabled else {
            print("[LiveActivity] Blocked: Live Activities disabled on device. " +
                  "Check Settings → \(sessionMode) app → Live Activities.")
            return
        }

        let endDate = phaseStartDate.addingTimeInterval(phaseDuration)
        let attributes = FlowStateActivityAttributes(sessionId: sessionId)
        let state = FlowStateActivityAttributes.ContentState(
            sessionEndDate: endDate,
            phaseStartDate: phaseStartDate,
            phaseDuration: phaseDuration,
            phase: phase,
            sessionMode: sessionMode,
            taskName: taskName,
            isPaused: false,
            pausedElapsed: 0
        )

        do {
            let activity = try Activity<FlowStateActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: state, staleDate: endDate.addingTimeInterval(60)),
                pushType: nil
            )
            print("[LiveActivity] Started: id=\(activity.id)")
            setActivity(activity)
        } catch {
            print("[LiveActivity] Failed to start: \(error.localizedDescription)")
        }
    }

    func _updateActivity(
        phaseStartDate: Date,
        phaseDuration: TimeInterval,
        phase: ActivityPhase,
        sessionMode: String,
        taskName: String?,
        isPaused: Bool,
        pausedElapsed: TimeInterval
    ) async {
        guard let activity = currentActivity() else { return }
        let endDate = isPaused
            ? Date().addingTimeInterval(phaseDuration - pausedElapsed)
            : phaseStartDate.addingTimeInterval(phaseDuration)
        let newState = FlowStateActivityAttributes.ContentState(
            sessionEndDate: endDate,
            phaseStartDate: phaseStartDate,
            phaseDuration: phaseDuration,
            phase: phase,
            sessionMode: sessionMode,
            taskName: taskName,
            isPaused: isPaused,
            pausedElapsed: pausedElapsed
        )
        await activity.update(
            .init(state: newState, staleDate: endDate.addingTimeInterval(60))
        )
    }

    func _endActivity() async {
        // End the tracked reference first
        if let activity = currentActivity() {
            await activity.end(nil, dismissalPolicy: .immediate)
            setActivity(nil)
        }
        // End any orphaned activities from a previous app session (e.g. after
        // force-quit). Without this, _activityRef is nil on relaunch but the
        // old Live Activity is still visible — starting a new session then
        // creates a duplicate alongside the orphan.
        for activity in Activity<FlowStateActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
