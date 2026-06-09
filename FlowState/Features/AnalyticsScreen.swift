import SwiftUI
import Charts
import SwiftData

struct AnalyticsScreen: View {
    @Environment(SubscriptionService.self) private var subService

    // @Query gives us live, reactive updates whenever SwiftData changes.
    // No more onAppear / modelContext.fetch() needed.
    @Query(sort: \SessionRecord.startedAt, order: .reverse)
    private var allSessions: [SessionRecord]

    @State private var analyticsVM = AnalyticsViewModel()
    @State private var showPaywall = false
    @ObservedObject private var locManager = LocalizationManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.night.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // Header
                        headerSection

                        // Milestone banner (if newly unlocked)
                        if let milestone = analyticsVM.newMilestone {
                            milestoneBanner(milestone)
                        }

                        // Stats Grid
                        statsGrid

                        // Weekly Chart
                        if subService.isPremium {
                            weeklyChart
                        } else {
                            premiumBlurCard(L10n.analyticsWeeklyBlur) { showPaywall = true }
                        }

                        // Energy Pattern (Premium only)
                        if subService.isPremium {
                            energyPatternSection
                        }

                        // Insight
                        if !analyticsVM.insightText.isEmpty {
                            insightCard
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationBarHidden(true)
            // Defer heavy computation past the navigation animation, then
            // recompute reactively whenever sessions change.
            .onAppear {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(120))
                    analyticsVM.recompute(allSessions: allSessions, isPremium: subService.isPremium)
                }
            }
            .onChange(of: allSessions) { _, newSessions in
                analyticsVM.recompute(allSessions: newSessions, isPremium: subService.isPremium)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallScreen(trigger: .analytics)
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.analyticsTitle)
                .font(AppTypography.titleLarge)
                .foregroundStyle(AppColors.text)
            Text(L10n.analyticsSubtitle)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
        }
    }

    // MARK: - Milestone Banner
    private func milestoneBanner(_ milestone: FocusMilestone) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.amber.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: milestone.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(AppColors.amber)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.title)
                    .font(AppTypography.labelMedium)
                    .foregroundStyle(AppColors.text)
                Text(milestone.subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
                    .lineLimit(2)
            }
            Spacer()
            Button {
                withAnimation { analyticsVM.dismissMilestone() }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textDim)
            }
        }
        .padding(14)
        .background(AppColors.amber.opacity(0.07))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.amber.opacity(0.25), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Stats Grid
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            // Row 1 — available to all
            StatCard(
                icon: "sun.max.fill",
                value: analyticsVM.totalFocusToday.focusTimeString,
                label: L10n.statsToday,
                color: AppColors.amber
            )
            StatCard(
                icon: "calendar.badge.clock",
                value: subService.isPremium
                    ? analyticsVM.totalFocusWeek.focusTimeString
                    : "—",
                label: L10n.statsThisWeek,
                color: subService.isPremium ? AppColors.text : AppColors.textDim,
                badge: weekChangeBadge
            )

            // Row 2 — streak (free) + all-time hours (premium)
            StatCard(
                icon: "flame.fill",
                value: "\(analyticsVM.currentStreak)d",
                label: L10n.statsStreak,
                color: AppColors.amber
            )
            StatCard(
                icon: "trophy.fill",
                value: subService.isPremium
                    ? analyticsVM.totalFocusHoursAllTime.hoursString
                    : "—",
                label: L10n.statsAllTime,
                color: subService.isPremium ? AppColors.amber : AppColors.textDim
            )

            // Row 3 — longest streak (free) + total sessions all-time (premium)
            StatCard(
                icon: "chart.line.uptrend.xyaxis",
                value: "\(analyticsVM.longestStreak)d",
                label: L10n.statsLongestStreak,
                color: AppColors.indigoLight
            )
            StatCard(
                icon: "number.circle.fill",
                value: subService.isPremium
                    ? analyticsVM.totalSessionsAllTime.kFormatted
                    : "—",
                label: "SESSIONS",
                color: subService.isPremium ? AppColors.sage : AppColors.textDim
            )
        }
    }

    private var weekChangeBadge: String? {
        guard subService.isPremium, let pct = analyticsVM.weekChangePercent, pct != 0 else { return nil }
        return pct > 0 ? "+\(pct)%" : "\(pct)%"
    }

    // MARK: - Weekly Chart
    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.analyticsWeeklyTitle)
                .font(AppTypography.overline)
                .foregroundStyle(AppColors.textDim)
                .tracking(1.5)

            let allEmpty = analyticsVM.weeklyStats.allSatisfy { $0.totalMinutes == 0 }

            if analyticsVM.weeklyStats.isEmpty || allEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 24))
                        .foregroundStyle(AppColors.textDim)
                    Text(L10n.analyticsNoData)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textDim)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
            } else {
                Chart(analyticsVM.weeklyStats) { day in
                    BarMark(
                        x: .value("Day", day.dayLabel),
                        y: .value("Minutes", day.totalMinutes)
                    )
                    .foregroundStyle(
                        Calendar.current.isDateInToday(day.date)
                        ? LinearGradient(colors: [AppColors.amber, AppColors.amberLight], startPoint: .bottom, endPoint: .top)
                        : LinearGradient(colors: [AppColors.indigo.opacity(0.6), AppColors.indigoLight.opacity(0.8)], startPoint: .bottom, endPoint: .top)
                    )
                    .cornerRadius(5)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(AppColors.border)
                        AxisValueLabel {
                            if let mins = value.as(Int.self) {
                                Text("\(mins)m")
                                    .font(AppTypography.overline)
                                    .foregroundStyle(AppColors.textDim)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(AppTypography.overline)
                                    .foregroundStyle(AppColors.textDim)
                            }
                        }
                    }
                }
                .frame(height: 120)
            }
        }
        .padding(14)
        .background(AppColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Energy Pattern Section
    // Renders a stacked bar for each time block showing the count of
    // sessions at each energy level (low / medium / high).
    // This correctly represents mixed-energy blocks instead of collapsing
    // to a single average color.
    private var energyPatternSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(L10n.analyticsEnergyTitle)
                    .font(AppTypography.overline)
                    .foregroundStyle(AppColors.textDim)
                    .tracking(1.5)
                Spacer()
                HStack(spacing: 8) {
                    energyLegendDot(AppColors.sage, L10n.energyLow)
                    energyLegendDot(AppColors.amber, L10n.energyMedium)
                    energyLegendDot(Color(hex: "#E07A7A"), L10n.energyHigh)
                }
            }

            let hasData = analyticsVM.energyTimeBlocks.contains { $0.hasData }

            if !hasData {
                Text(L10n.analyticsEnergyNoData)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textDim)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                let maxCount = analyticsVM.energyTimeBlocks.map { $0.sessionCount }.max() ?? 1
                // 160pt gives ~5px per session when maxCount ≈ 30 days.
                // 72 was too small — bars were near-invisible with real data.
                let barMaxHeight: CGFloat = 160

                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(analyticsVM.energyTimeBlocks) { block in
                        VStack(spacing: 4) {
                            if block.hasData {
                                // Stacked bar: low (bottom) → medium → high (top)
                                VStack(spacing: 1) {
                                    stackedSegment(
                                        count: block.highCount,
                                        total: maxCount,
                                        maxHeight: barMaxHeight,
                                        color: Color(hex: "#E07A7A"),
                                        isTop: true
                                    )
                                    stackedSegment(
                                        count: block.mediumCount,
                                        total: maxCount,
                                        maxHeight: barMaxHeight,
                                        color: AppColors.amber,
                                        isTop: block.highCount == 0
                                    )
                                    stackedSegment(
                                        count: block.lowCount,
                                        total: maxCount,
                                        maxHeight: barMaxHeight,
                                        color: AppColors.sage,
                                        isTop: block.highCount == 0 && block.mediumCount == 0
                                    )
                                }
                            } else {
                                // Empty placeholder bar
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AppColors.surface2)
                                    .frame(height: 6)
                            }
                            Text(block.label)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(AppColors.textDim)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: barMaxHeight + 20) // bar + label + spacing
                .padding(.top, 4)
            }
        }
        .padding(14)
        .background(AppColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    /// One colored segment in the stacked bar.
    @ViewBuilder
    private func stackedSegment(count: Int, total: Int, maxHeight: CGFloat, color: Color, isTop: Bool) -> some View {
        if count > 0 {
            // 3pt floor ensures even a 1-session segment is clearly visible.
            // Height is otherwise strictly proportional: count/maxCount * barMaxHeight,
            // so the block with the most sessions fills barMaxHeight exactly.
            let height = max(3, CGFloat(count) / CGFloat(max(total, 1)) * maxHeight)
            RoundedRectangle(cornerRadius: isTop ? 4 : 2)
                .fill(color)
                .frame(height: height)
        }
    }

    private func energyLegendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.system(size: 9)).foregroundStyle(AppColors.textDim)
        }
    }

    // MARK: - Insight Card
    private var insightCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 13))
                .foregroundStyle(AppColors.amber)
            Text(analyticsVM.insightText)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
                .lineSpacing(3)
        }
        .padding(12)
        .background(AppColors.indigo.opacity(0.07))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.indigo.opacity(0.2), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Premium Blur Card
    private func premiumBlurCard(_ message: String, action: @escaping () -> Void) -> some View {
        ZStack {
            Rectangle()
                .fill(AppColors.surface)
                .frame(height: 140)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .blur(radius: 8)

            VStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .font(.title3)
                    .foregroundStyle(AppColors.amber)
                Text(message)
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.textMuted)
                    .multilineTextAlignment(.center)
                Button(action: action) {
                    Text(L10n.upgrade)
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.amber)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .overlay(Capsule().stroke(AppColors.amber, lineWidth: 1))
                }
            }
        }
        .frame(height: 140)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    var icon: String? = nil
    let value: String
    let label: String
    var color: Color = AppColors.text
    var badge: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(color.opacity(0.7))
                }
                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(badge.hasPrefix("+") ? AppColors.sage : Color(hex: "#E07A7A"))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(badge.hasPrefix("+") ? AppColors.sage.opacity(0.12) : Color(hex: "#E07A7A").opacity(0.12))
                        .clipShape(Capsule())
                }
                Spacer(minLength: 0)
            }
            Text(value)
                .font(AppTypography.statValue)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(AppTypography.overline)
                .foregroundStyle(AppColors.textMuted)
                .tracking(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Int Extensions
extension Int {
    var focusTimeString: String {
        if self < 60 { return "\(self)m" }
        let h = self / 60
        let m = self % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    /// 247 → "247", 1200 → "1.2k", 12000 → "12k"
    var kFormatted: String {
        if self < 1000 { return "\(self)" }
        let k = Double(self) / 1000.0
        if k < 10 { return String(format: "%.1fk", k) }
        return "\(Int(k))k"
    }
}

// MARK: - Double Extensions
extension Double {
    /// Formats all-time focus hours, e.g. 1.5 → "1.5h", 100.0 → "100h"
    var hoursString: String {
        if self >= 10 { return "\(Int(self))h" }
        return String(format: "%.1fh", self)
    }
}
