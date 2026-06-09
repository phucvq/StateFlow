import Foundation
import SwiftData

@Model
final class SessionRecord {

    // MARK: - Identity
    var id: UUID
    var startedAt: Date
    var endedAt: Date?

    // MARK: - Session Config
    var plannedWorkDuration: TimeInterval
    var actualWorkDuration: TimeInterval
    var modeRaw: String
    var statusRaw: String

    // MARK: - Context
    var energyLevelRaw: String?
    var taskName: String?
    var soundscapeId: String?
    var breakCount: Int
    var sessionNumber: Int  // which pomodoro in a sequence

    // MARK: - Computed
    var mode: SessionMode {
        get { SessionMode(rawValue: modeRaw) ?? .standard }
        set { modeRaw = newValue.rawValue }
    }

    var status: SessionStatus {
        get { SessionStatus(rawValue: statusRaw) ?? .inProgress }
        set { statusRaw = newValue.rawValue }
    }

    var energyLevel: EnergyLevel? {
        get {
            guard let raw = energyLevelRaw else { return nil }
            return EnergyLevel(rawValue: raw)
        }
        set { energyLevelRaw = newValue?.rawValue }
    }

    var completionRate: Double {
        guard plannedWorkDuration > 0 else { return 0 }
        return min(1.0, actualWorkDuration / plannedWorkDuration)
    }

    var isCompleted: Bool { status == .completed }

    // MARK: - Init
    init(
        mode: SessionMode,
        plannedDuration: TimeInterval,
        taskName: String? = nil,
        energyLevel: EnergyLevel? = nil,
        soundscapeId: String? = nil,
        sessionNumber: Int = 1
    ) {
        self.id = UUID()
        self.startedAt = Date()
        self.endedAt = nil
        self.plannedWorkDuration = plannedDuration
        self.actualWorkDuration = 0
        self.modeRaw = mode.rawValue
        self.statusRaw = SessionStatus.inProgress.rawValue
        self.energyLevelRaw = energyLevel?.rawValue
        self.taskName = taskName
        self.soundscapeId = soundscapeId
        self.breakCount = 0
        self.sessionNumber = sessionNumber
    }
}
