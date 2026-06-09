import Foundation
import SwiftData

@Model
final class EnergyLog {

    var id: UUID
    var loggedAt: Date
    var energyLevelRaw: String
    var sessionId: UUID?

    var energyLevel: EnergyLevel {
        get { EnergyLevel(rawValue: energyLevelRaw) ?? .medium }
        set { energyLevelRaw = newValue.rawValue }
    }

    init(energyLevel: EnergyLevel, sessionId: UUID? = nil) {
        self.id = UUID()
        self.loggedAt = Date()
        self.energyLevelRaw = energyLevel.rawValue
        self.sessionId = sessionId
    }
}
