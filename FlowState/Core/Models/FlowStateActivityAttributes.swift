import ActivityKit
import Foundation

// MARK: - FlowStateActivityAttributes
// ⚠️ Add this file AND ActivityPhase.swift to BOTH the main app target AND the widget extension target in Xcode.

struct FlowStateActivityAttributes: ActivityAttributes {

    // MARK: - Dynamic state
    public struct ContentState: Codable, Hashable {
        /// Wall-clock date when this phase ends.
        /// The widget uses Text(sessionEndDate, style: .timer) so iOS renders
        /// the countdown automatically — no per-second push from the app needed.
        /// This makes the Live Activity work correctly on the lock screen.
        var sessionEndDate: Date
        /// Phase start date (for arc progress)
        var phaseStartDate: Date
        /// Total duration of the current phase (for arc progress calculation)
        var phaseDuration: TimeInterval
        /// Current phase
        var phase: ActivityPhase
        /// Mode display name e.g. "Deep Work"
        var sessionMode: String
        /// Optional task name
        var taskName: String?
        /// Whether the timer is paused
        var isPaused: Bool
        /// Elapsed time when paused (for static display while paused)
        var pausedElapsed: TimeInterval

        var progress: Double {
            guard phaseDuration > 0 else { return 0 }
            let elapsed = isPaused
                ? pausedElapsed
                : Date().timeIntervalSince(phaseStartDate)
            return max(0, min(1, elapsed / phaseDuration))
        }

        var pausedTimeRemaining: TimeInterval {
            max(0, phaseDuration - pausedElapsed)
        }

        var pausedTimeString: String {
            let total = Int(pausedTimeRemaining)
            return String(format: "%d:%02d", total / 60, total % 60)
        }
    }

    // MARK: - Static (set once at start, never changes)
    var sessionId: UUID
}

// ActivityPhase is defined in ActivityPhase.swift (no ActivityKit import needed there)
