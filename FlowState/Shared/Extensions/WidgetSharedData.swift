import Foundation
import WidgetKit

// MARK: - Shared container
// App Group ID must match in both targets' entitlements:
//   group.com.yourteam.FlowState   (replace with your real bundle prefix)
// See setup guide in FlowState/Docs/WidgetSetup.md

let kAppGroupID = "group.com.flowstate.app"

// MARK: - Data model written by the main app, read by widgets

struct WidgetSharedData: Codable {
    var todayFocusMinutes: Int          // minutes of completed focus today
    var currentStreak: Int              // days
    var longestStreak: Int              // days
    var weekFocusMinutes: Int           // minutes this week
    var lastSessionTaskName: String?    // most recent session's task name
    var lastSessionDate: Date?          // when last session ended
    var totalFocusHours: Double         // all-time hours

    static let empty = WidgetSharedData(
        todayFocusMinutes: 0,
        currentStreak: 0,
        longestStreak: 0,
        weekFocusMinutes: 0,
        lastSessionTaskName: nil,
        lastSessionDate: nil,
        totalFocusHours: 0
    )
}

// MARK: - Writer (call from main app after every session + on foreground)

enum WidgetDataWriter {
    private static let key = "widgetSharedData"

    static func write(_ data: WidgetSharedData) {
        guard let defaults = UserDefaults(suiteName: kAppGroupID) else {
            print("[Widget] App Group not configured — skipping write")
            return
        }
        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: key)
        }
        // Tell WidgetKit to re-fetch timelines immediately
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func read() -> WidgetSharedData {
        guard let defaults = UserDefaults(suiteName: kAppGroupID),
              let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(WidgetSharedData.self, from: data)
        else { return .empty }
        return decoded
    }
}
