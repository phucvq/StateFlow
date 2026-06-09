import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct FlowStateEntry: TimelineEntry {
    let date: Date
    let data: WidgetSharedData
}

// MARK: - Provider

struct FlowStateWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> FlowStateEntry {
        FlowStateEntry(date: Date(), data: WidgetSharedData(
            todayFocusMinutes: 45,
            currentStreak: 7,
            longestStreak: 14,
            weekFocusMinutes: 210,
            lastSessionTaskName: "Deep Work",
            lastSessionDate: Date(),
            totalFocusHours: 32.5
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (FlowStateEntry) -> Void) {
        completion(FlowStateEntry(date: Date(), data: WidgetDataWriter.read()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FlowStateEntry>) -> Void) {
        let entry = FlowStateEntry(date: Date(), data: WidgetDataWriter.read())
        // Refresh at midnight so "today" stats roll over, or on demand via WidgetCenter.reloadAllTimelines()
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }
}

// MARK: - Widget Definition

struct FlowStateWidget: Widget {
    let kind = "FlowStateWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FlowStateWidgetProvider()) { entry in
            FlowStateWidgetEntryView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("FlowState")
        .description("Track today's focus time and streak.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Router View

struct FlowStateWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FlowStateEntry

    var body: some View {
        switch family {
        case .systemSmall:       SmallWidgetView(data: entry.data)
        case .systemMedium:      MediumWidgetView(data: entry.data)
        case .systemLarge:       LargeWidgetView(data: entry.data)
        case .accessoryCircular: AccessoryCircularView(data: entry.data)
        case .accessoryRectangular: AccessoryRectangularView(data: entry.data)
        case .accessoryInline:   AccessoryInlineView(data: entry.data)
        default:                 SmallWidgetView(data: entry.data)
        }
    }
}

// MARK: - Color helpers (widget-private, avoids duplicate symbol with app target)

private func wColor(_ hex: String) -> Color {
    let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: h).scanHexInt64(&int)
    return Color(
        red:   Double((int >> 16) & 0xFF) / 255,
        green: Double((int >> 8)  & 0xFF) / 255,
        blue:  Double( int        & 0xFF) / 255
    )
}

private let wAmber   = wColor("#F5A623")
private let wIndigo  = wColor("#6C63FF")
private let wSage    = wColor("#7EC8A4")
private let wNight   = wColor("#0D0D1A")
private let wSurface = wColor("#1A1A2E")
private let wMuted   = wColor("#8888AA")

// MARK: - Focus time formatter (mirrors Int.focusTimeString in main app)

private func focusString(_ minutes: Int) -> String {
    if minutes < 60 { return "\(minutes)m" }
    let h = minutes / 60; let m = minutes % 60
    return m == 0 ? "\(h)h" : "\(h)h \(m)m"
}

// ─────────────────────────────────────────────
// MARK: - systemSmall
// Shows: today focus + streak
// ─────────────────────────────────────────────

struct SmallWidgetView: View {
    let data: WidgetSharedData

    var body: some View {
        ZStack {
            wSurface

            VStack(alignment: .leading, spacing: 0) {
                // App label
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(wAmber)
                    Text("FlowState")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(wMuted)
                }

                Spacer()

                // Today focus — big number
                VStack(alignment: .leading, spacing: 2) {
                    Text("TODAY")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(wMuted)
                        .tracking(1)
                    Text(focusString(data.todayFocusMinutes))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }

                Spacer()

                // Streak pill
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(wAmber)
                    Text("\(data.currentStreak)d streak")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(wAmber.opacity(0.15))
                .clipShape(Capsule())
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - systemMedium
// Shows: today + week + streak + last session
// ─────────────────────────────────────────────

struct MediumWidgetView: View {
    let data: WidgetSharedData

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [wNight, wSurface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 0) {
                // Left — big today stat
                VStack(alignment: .leading, spacing: 4) {
                    Label("FlowState", systemImage: "timer")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(wAmber)

                    Spacer()

                    Text("TODAY")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(wMuted)
                        .tracking(1)
                    Text(focusString(data.todayFocusMinutes))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)

                    Spacer()

                    // Last session task
                    if let task = data.lastSessionTaskName, !task.isEmpty {
                        Label(task, systemImage: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(wSage)
                            .lineLimit(1)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1)
                    .padding(.vertical, 12)

                // Right — stats column
                VStack(alignment: .leading, spacing: 10) {
                    MediumStatRow(
                        icon: "calendar.badge.clock",
                        iconColor: wIndigo,
                        label: "WEEK",
                        value: focusString(data.weekFocusMinutes)
                    )
                    MediumStatRow(
                        icon: "flame.fill",
                        iconColor: wAmber,
                        label: "STREAK",
                        value: "\(data.currentStreak)d"
                    )
                    MediumStatRow(
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: wSage,
                        label: "BEST",
                        value: "\(data.longestStreak)d"
                    )
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct MediumStatRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(wMuted)
                    .tracking(0.8)
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - systemLarge
// Shows: all stats + 7-day bar chart (minutes per day from widget data)
// ─────────────────────────────────────────────

struct LargeWidgetView: View {
    let data: WidgetSharedData

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [wNight, wSurface],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Label("FlowState", systemImage: "timer")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(wAmber)
                    Spacer()
                    Text(Date(), style: .date)
                        .font(.system(size: 10))
                        .foregroundStyle(wMuted)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Spacer(minLength: 12)

                // Today hero
                VStack(alignment: .leading, spacing: 2) {
                    Text("TODAY'S FOCUS")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(wMuted)
                        .tracking(1.5)
                    Text(focusString(data.todayFocusMinutes))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 12)

                // Stats row
                HStack(spacing: 0) {
                    LargeStatCell(icon: "flame.fill",     color: wAmber,  label: "Streak",    value: "\(data.currentStreak)d")
                    LargeStatCell(icon: "chart.line.uptrend.xyaxis", color: wSage, label: "Best", value: "\(data.longestStreak)d")
                    LargeStatCell(icon: "calendar.badge.clock", color: wIndigo, label: "This week", value: focusString(data.weekFocusMinutes))
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 12)

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                Spacer(minLength: 12)

                // Last session
                if let task = data.lastSessionTaskName, !task.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("LAST SESSION")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(wMuted)
                            .tracking(1)
                        Label(task, systemImage: "checkmark.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(wSage)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 12)
                }

                // All-time
                HStack {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(wAmber)
                    Text(String(format: data.totalFocusHours >= 10 ? "%.0fh total focus" : "%.1fh total focus", data.totalFocusHours))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(wMuted)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct LargeStatCell: View {
    let icon: String; let color: Color; let label: String; let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(wMuted)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// ─────────────────────────────────────────────
// MARK: - Accessory (Lock Screen / Watch Face)
// ─────────────────────────────────────────────

struct AccessoryCircularView: View {
    let data: WidgetSharedData
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                Image(systemName: "timer")
                    .font(.system(size: 12, weight: .semibold))
                Text(focusString(data.todayFocusMinutes))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
        }
        .widgetLabel {
            Label("\(data.currentStreak)d", systemImage: "flame.fill")
        }
    }
}

struct AccessoryRectangularView: View {
    let data: WidgetSharedData
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("FlowState", systemImage: "timer")
                .font(.system(size: 11, weight: .bold))
            HStack(spacing: 10) {
                Label(focusString(data.todayFocusMinutes), systemImage: "sun.max.fill")
                    .font(.system(size: 11))
                Label("\(data.currentStreak)d", systemImage: "flame.fill")
                    .font(.system(size: 11))
            }
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AccessoryInlineView: View {
    let data: WidgetSharedData
    var body: some View {
        Label(
            "\(focusString(data.todayFocusMinutes)) · \(data.currentStreak)d streak",
            systemImage: "timer"
        )
    }
}
