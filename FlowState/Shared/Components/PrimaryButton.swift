import SwiftUI

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = AppColors.amber
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(Color(hex: "#1A0F00"))
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text(title)
                        .font(AppTypography.labelMedium)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundStyle(Color(hex: "#1A0F00"))
            .clipShape(Capsule())
            .shadow(color: color.opacity(0.32), radius: 12, y: 5)
        }
        .disabled(isLoading)
        .buttonStyle(.plain)
    }
}

// MARK: - Streak Badge View
struct StreakBadgeView: View {
    let days: Int

    var body: some View {
        HStack(spacing: 7) {
            Text("🔥")
                .font(.system(size: 14))
            Text(String(format: L10n.streakDays, days))
                .font(AppTypography.labelSmall)
                .foregroundStyle(AppColors.amber)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 6)
        .background(AppColors.amber.opacity(0.1))
        .overlay(
            Capsule()
                .stroke(AppColors.amber.opacity(0.25), lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

// MARK: - Session Mode Card View
struct SessionModeCardView: View {
    let mode: SessionMode
    let workDuration: TimeInterval
    let breakDuration: TimeInterval
    let onChangeTap: () -> Void
    let onStartTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                Label {
                    Text(mode.displayName)
                        .font(.custom("PlusJakartaSans-Bold", size: 15))
                        .foregroundStyle(AppColors.indigoLight)
                        .tracking(0.8)
                        .textCase(.uppercase)
                } icon: {
                    Image(systemName: mode.sfSymbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(mode.accentColor)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(AppColors.indigo.opacity(0.12))
                .overlay(Capsule().stroke(AppColors.indigo.opacity(0.22), lineWidth: 1))
                .clipShape(Capsule())

                Spacer()

                Button(action: onChangeTap) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .semibold))
                        Text(L10n.change)
                            .font(.custom("PlusJakartaSans-Bold", size: 15))
                    }
                    .foregroundStyle(AppColors.textDim)
                }
            }
            .padding(.bottom, 22)

            // Durations
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workDuration.shortTimerString)
                        .font(.custom("DMSerifDisplay-Regular", size: 60))
                        .foregroundStyle(AppColors.text)
                    Text(L10n.timerWork)
                        .font(.custom("PlusJakartaSans-Bold", size: 17))
                        .foregroundStyle(AppColors.textDim)
                        .tracking(0.8)
                }
                Spacer()
                Text("·")
                    .font(.custom("DMSerifDisplay-Regular", size: 60))
                    .foregroundStyle(AppColors.textDim)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(breakDuration.shortTimerString)
                        .font(.custom("DMSerifDisplay-Regular", size: 60))
                        .foregroundStyle(AppColors.sage)
                    Text(L10n.timerBreak)
                        .font(.custom("PlusJakartaSans-Bold", size: 17))
                        .foregroundStyle(AppColors.textDim)
                        .tracking(0.8)
                }
            }
            .padding(.bottom, 22)

            // Start button (inside card)
            PrimaryButton(
                title: L10n.homeStart,
                icon: "play.fill",
                color: AppColors.amber,
                action: onStartTap
            )
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 32)
        .padding(.top, 40)
        .background(AppColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

#Preview {
    ZStack {
        AppColors.night.ignoresSafeArea()
        VStack(spacing: 20) {
            StreakBadgeView(days: 7)
            SessionModeCardView(
                mode: .deepWork,
                workDuration: 50 * 60,
                breakDuration: 10 * 60,
                onChangeTap: {},
                onStartTap: {}
            )
            .padding(.horizontal, 24)
            PrimaryButton(title: "Start Session", icon: "play.fill") {}
                .padding(.horizontal, 24)
        }
    }
}
