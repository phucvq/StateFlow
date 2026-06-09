import Foundation
import Combine

// MARK: - TimerService
// Uses Date-based countdown (not Timer.scheduledTimer) for accuracy in background
final class TimerService: ObservableObject {

    // MARK: - Persistence Keys
    private enum PersistKey {
        static let startDate = "timer_startDate"
        static let pausedElapsed = "timer_pausedElapsed"
        static let isPaused = "timer_isPaused"
        static let duration = "timer_duration"
        static let phase = "timer_phase"
    }

    // MARK: - State
    private(set) var sessionStartDate: Date?
    private(set) var pausedElapsed: TimeInterval = 0
    private(set) var isPaused: Bool = false
    private(set) var plannedDuration: TimeInterval = 0

    private var displayTimer: Timer?

    // Callback for UI updates (every second)
    var onTick: ((TimeInterval) -> Void)?
    var onComplete: (() -> Void)?

    // MARK: - Start
    func start(duration: TimeInterval) {
        plannedDuration = duration
        sessionStartDate = Date()
        pausedElapsed = 0
        isPaused = false
        saveState()
        startDisplayTimer()
    }

    // MARK: - Pause
    func pause() {
        guard !isPaused, let start = sessionStartDate else { return }
        pausedElapsed += Date().timeIntervalSince(start)
        sessionStartDate = nil
        isPaused = true
        saveState()
        stopDisplayTimer()
    }

    // MARK: - Resume
    func resume() {
        guard isPaused else { return }
        sessionStartDate = Date()
        isPaused = false
        saveState()
        startDisplayTimer()
    }

    // MARK: - Stop
    func stop() {
        sessionStartDate = nil
        pausedElapsed = 0
        isPaused = false
        plannedDuration = 0
        clearState()
        stopDisplayTimer()
    }

    // MARK: - Time Remaining
    var timeRemaining: TimeInterval {
        guard plannedDuration > 0 else { return 0 }
        let elapsed: TimeInterval
        if let start = sessionStartDate {
            elapsed = pausedElapsed + Date().timeIntervalSince(start)
        } else {
            elapsed = pausedElapsed
        }
        return max(0, plannedDuration - elapsed)
    }

    var elapsedTime: TimeInterval {
        guard let start = sessionStartDate else { return pausedElapsed }
        return pausedElapsed + Date().timeIntervalSince(start)
    }

    var progress: Double {
        guard plannedDuration > 0 else { return 0 }
        return min(1.0, elapsedTime / plannedDuration)
    }

    var isRunning: Bool {
        sessionStartDate != nil && !isPaused
    }

    // MARK: - Display Timer (UI Updates)
    private func startDisplayTimer() {
        stopDisplayTimer()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let remaining = self.timeRemaining
            self.onTick?(remaining)
            if remaining <= 0 {
                self.stopDisplayTimer()
                self.onComplete?()
            }
        }
        RunLoop.main.add(displayTimer!, forMode: .common)
    }

    private func stopDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = nil
    }

    // MARK: - Background Persistence
    func saveState() {
        UserDefaults.standard.set(sessionStartDate, forKey: PersistKey.startDate)
        UserDefaults.standard.set(pausedElapsed, forKey: PersistKey.pausedElapsed)
        UserDefaults.standard.set(isPaused, forKey: PersistKey.isPaused)
        UserDefaults.standard.set(plannedDuration, forKey: PersistKey.duration)
    }

    func restoreState() {
        plannedDuration = UserDefaults.standard.double(forKey: PersistKey.duration)
        pausedElapsed = UserDefaults.standard.double(forKey: PersistKey.pausedElapsed)
        isPaused = UserDefaults.standard.bool(forKey: PersistKey.isPaused)
        sessionStartDate = UserDefaults.standard.object(forKey: PersistKey.startDate) as? Date

        guard plannedDuration > 0 else { return }

        // If the timer was running when app was killed, it kept counting
        // Check if it already expired
        if timeRemaining <= 0 {
            onComplete?()
        } else if isRunning {
            startDisplayTimer()
        }
    }

    private func clearState() {
        UserDefaults.standard.removeObject(forKey: PersistKey.startDate)
        UserDefaults.standard.removeObject(forKey: PersistKey.pausedElapsed)
        UserDefaults.standard.removeObject(forKey: PersistKey.isPaused)
        UserDefaults.standard.removeObject(forKey: PersistKey.duration)
    }
}
