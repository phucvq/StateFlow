import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity Widget
// Renders on: Lock Screen banner, Dynamic Island (compact + expanded)

// Widget Extension deployment target is iOS 16.2+ — no @available guard needed here.
struct FlowStateLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FlowStateActivityAttributes.self) { context in
            // MARK: Lock Screen / Notification Banner
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: Dynamic Island — Expanded (long press)
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: context.state.phase.sfSymbol)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(widgetColor(context.state.phase.colorHex))
                        Text(context.state.phase.displayName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isPaused {
                        Text(context.state.pausedTimeString)
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundStyle(widgetColor(context.state.phase.colorHex))
                    } else {
                        ClampedTimerText(
                            endDate: context.state.sessionEndDate,
                            font: .system(size: 22, weight: .bold, design: .monospaced),
                            color: widgetColor(context.state.phase.colorHex)
                        )
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        if let task = context.state.taskName, !task.isEmpty {
                            Label(task, systemImage: "checkmark.circle")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(1)
                        } else {
                            Label(context.state.sessionMode, systemImage: "timer")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.7))
                        }

                        Spacer()

                        // Arc progress
                        CircularProgressView(
                            progress: context.state.progress,
                            color: widgetColor(context.state.phase.colorHex)
                        )
                        .frame(width: 24, height: 24)
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                // MARK: Dynamic Island — Compact Leading
                Image(systemName: context.state.phase.sfSymbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(widgetColor(context.state.phase.colorHex))
            } compactTrailing: {
                // MARK: Dynamic Island — Compact Trailing
                if context.state.isPaused {
                    Text(context.state.pausedTimeString)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(widgetColor(context.state.phase.colorHex))
                } else {
                    ClampedTimerText(
                        endDate: context.state.sessionEndDate,
                        font: .system(size: 12, weight: .bold, design: .monospaced),
                        color: widgetColor(context.state.phase.colorHex)
                    )
                }
            } minimal: {
                // MARK: Dynamic Island — Minimal (when two activities compete)
                Image(systemName: context.state.phase.sfSymbol)
                    .font(.system(size: 11))
                    .foregroundStyle(widgetColor(context.state.phase.colorHex))
            }
        }
    }
}

// MARK: - Lock Screen View
private struct LockScreenView: View {
    let context: ActivityViewContext<FlowStateActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            // Phase icon + arc
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 3)
                    .frame(width: 52, height: 52)

                Circle()
                    .trim(from: 0, to: context.state.progress)
                    .stroke(
                        widgetColor(context.state.phase.colorHex),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))

                Image(systemName: context.state.isPaused ? "pause.fill" : context.state.phase.sfSymbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(widgetColor(context.state.phase.colorHex))
            }

            // Center info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(context.state.phase.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(widgetColor(context.state.phase.colorHex))
                    if context.state.isPaused {
                        Text("PAUSED")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.orange)
                    }
                }

                // ClampedTimerText renders a self-updating countdown — works on lock screen
                // without the app needing to push per-second updates.
                // Uses clamped helper to prevent count-up when sessionEndDate is in the past
                // (race window between phase ending and isPaused:true update arriving).
                if context.state.isPaused {
                    Text(context.state.pausedTimeString)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                } else {
                    ClampedTimerText(
                        endDate: context.state.sessionEndDate,
                        font: .system(size: 28, weight: .bold, design: .monospaced),
                        color: .white
                    )
                }

                if let task = context.state.taskName, !task.isEmpty {
                    Text(task)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                } else {
                    Text(context.state.sessionMode)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Spacer()

            // App branding
            VStack(spacing: 2) {
                Image(systemName: "timer")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.5))
                Text("FlowState")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [widgetColor("#0D0D1A"), widgetColor("#141428")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// MARK: - Circular Progress Helper
private struct CircularProgressView: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Clamped timer view (widget-private)
// Text(date, style:.timer) counts DOWN while date is future, then counts UP once
// the date passes — causing the "timer jumps up" bug when a phase ends.
//
// Fix: use Text(timerInterval:countsDown:true) instead.
// This API clamps at "0:00" when the interval expires — it never reverses direction.
// max(endDate, Date()) ensures a valid non-negative range when endDate is already past.
// Available iOS 16.0+ — matches the widget extension deployment target.
private struct ClampedTimerText: View {
    let endDate: Date
    let font: Font
    let color: Color

    var body: some View {
        let safeEnd = max(endDate, Date())
        Text(timerInterval: Date()...safeEnd, countsDown: true)
            .font(font)
            .foregroundStyle(color)
            .monospacedDigit()
    }
}

// MARK: - Hex color helper (widget-private)
// Named differently from AppColors to avoid duplicate symbol if AppColors
// is accidentally included in the widget target's membership.
private func widgetColor(_ hex: String) -> Color {
    let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: h).scanHexInt64(&int)
    let r = Double((int >> 16) & 0xFF) / 255
    let g = Double((int >> 8) & 0xFF) / 255
    let b = Double(int & 0xFF) / 255
    return Color(red: r, green: g, blue: b)
}
