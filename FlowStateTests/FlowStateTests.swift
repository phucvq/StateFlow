import XCTest
@testable import FlowState

final class FlowStateTests: XCTestCase {

    // MARK: - TimeInterval Extensions
    func testTimerString() {
        XCTAssertEqual((25 * 60.0).timerString, "25:00")
        XCTAssertEqual((90.0).timerString, "01:30")
        XCTAssertEqual((0.0).timerString, "00:00")
    }

    func testShortTimerString() {
        XCTAssertEqual((25 * 60.0).shortTimerString, "25m")
        XCTAssertEqual((90 * 60.0).shortTimerString, "1h 30m")
        XCTAssertEqual((60 * 60.0).shortTimerString, "1h")
    }

    // MARK: - SessionMode
    func testSessionModeWorkDuration() {
        XCTAssertEqual(SessionMode.standard.workDuration, 25 * 60)
        XCTAssertEqual(SessionMode.deepWork.workDuration, 50 * 60)
        XCTAssertEqual(SessionMode.micro.workDuration, 10 * 60)
    }

    // MARK: - UserPreferences Streak
    func testStreakFirstSession() {
        let prefs = UserPreferences.shared
        prefs.streakCurrentDays = 0
        prefs.lastFocusDate = nil
        prefs.updateStreak(completedSessionDate: Date())
        XCTAssertEqual(prefs.streakCurrentDays, 1)
    }

    func testStreakConsecutiveDays() {
        let prefs = UserPreferences.shared
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        prefs.lastFocusDate = yesterday
        prefs.streakCurrentDays = 3
        prefs.updateStreak(completedSessionDate: Date())
        XCTAssertEqual(prefs.streakCurrentDays, 4)
    }

    func testStreakBreaks() {
        let prefs = UserPreferences.shared
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        prefs.lastFocusDate = twoDaysAgo
        prefs.streakCurrentDays = 5
        prefs.updateStreak(completedSessionDate: Date())
        XCTAssertEqual(prefs.streakCurrentDays, 1)
    }

    // MARK: - EnergyLevel
    func testEnergyLevelSuggestedDuration() {
        XCTAssertEqual(EnergyLevel.low.suggestedWorkDuration, 10 * 60)
        XCTAssertEqual(EnergyLevel.medium.suggestedWorkDuration, 25 * 60)
        XCTAssertEqual(EnergyLevel.high.suggestedWorkDuration, 45 * 60)
    }

    // MARK: - TimerService
    func testTimerServiceProgress() {
        let service = TimerService()
        service.start(duration: 100)
        // Progress should be between 0 and 1
        let progress = service.progress
        XCTAssertGreaterThanOrEqual(progress, 0)
        XCTAssertLessThanOrEqual(progress, 1.0)
        service.stop()
    }

    func testTimerServicePauseResume() {
        let service = TimerService()
        service.start(duration: 100)
        XCTAssertTrue(service.isRunning)
        service.pause()
        XCTAssertFalse(service.isRunning)
        XCTAssertTrue(service.isPaused)
        service.resume()
        XCTAssertTrue(service.isRunning)
        service.stop()
    }
}
