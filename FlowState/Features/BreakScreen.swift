import SwiftUI

// MARK: - Break Ready View
// Shown after a work session completes. User chooses to start or skip break.
struct BreakReadyView: View {
    @Environment(TimerViewModel.self) private var timerVM
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            AppColors.night.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()

                // Checkmark
                ZStack {
                    Circle()
                        .fill(AppColors.sage.opacity(0.12))
                        .frame(width: 100, height: 100)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(AppColors.sage)
                }
                .padding(.bottom, 24)

                Text("Session \(timerVM.currentSessionNumber) Complete!")
                    .font(AppTypography.titleLarge)
                    .foregroundStyle(AppColors.text)

                Text("Time for a well-earned break.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textMuted)
                    .padding(.top, 6)

                // Break duration pill
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.system(size: 12, weight: .semibold))
                    Text(timerVM.breakDuration.shortTimerString)
                        .font(AppTypography.labelSmall)
                }
                .foregroundStyle(AppColors.sage)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(AppColors.sage.opacity(0.1))
                .overlay(Capsule().stroke(AppColors.sage.opacity(0.3), lineWidth: 1))
                .clipShape(Capsule())
                .padding(.top, 16)

                Spacer()

                VStack(spacing: 12) {
                    PrimaryButton(title: "Start Break", icon: "cup.and.saucer.fill", color: AppColors.sage) {
                        HapticService.shared.tap()
                        timerVM.startBreakNow()
                    }
                    .padding(.horizontal, 24)

                    Button {
                        HapticService.shared.tap()
                        timerVM.skipBreak()
                    } label: {
                        Label("Skip Break", systemImage: "forward.fill")
                            .font(AppTypography.labelSmall)
                            .foregroundStyle(AppColors.textMuted)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(AppColors.surface)
                            .overlay(RoundedRectangle(cornerRadius: 100).stroke(AppColors.border, lineWidth: 1))
                            .clipShape(Capsule())
                    }

                    Button {
                        HapticService.shared.tap()
                        timerVM.endSession(modelContext: modelContext)
                    } label: {
                        Text(L10n.timerEndSession)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textDim)
                    }
                }
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Work Ready View
// Shown after a break completes. User chooses to start next session or end.
struct WorkReadyView: View {
    @Environment(TimerViewModel.self) private var timerVM
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            AppColors.night.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()

                // Session number indicator
                ZStack {
                    Circle()
                        .fill(AppColors.indigo.opacity(0.12))
                        .frame(width: 100, height: 100)
                    VStack(spacing: 0) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(AppColors.indigoLight)
                        Text("#\(timerVM.currentSessionNumber)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColors.indigoLight)
                    }
                }
                .padding(.bottom, 24)

                Text("Break Over!")
                    .font(AppTypography.titleLarge)
                    .foregroundStyle(AppColors.text)

                Text("Ready for session \(timerVM.currentSessionNumber) of \(timerVM.totalSessionsInSequence)?")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
                    .padding(.horizontal, 32)

                // Work duration pill
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.system(size: 12, weight: .semibold))
                    Text(timerVM.workDuration.shortTimerString)
                        .font(AppTypography.labelSmall)
                }
                .foregroundStyle(AppColors.indigoLight)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(AppColors.indigo.opacity(0.1))
                .overlay(Capsule().stroke(AppColors.indigoLight.opacity(0.3), lineWidth: 1))
                .clipShape(Capsule())
                .padding(.top, 16)

                Spacer()

                VStack(spacing: 12) {
                    PrimaryButton(title: "Start Session", icon: "play.fill", color: AppColors.amber) {
                        HapticService.shared.tap()
                        timerVM.startNextSessionNow(modelContext: modelContext)
                    }
                    .padding(.horizontal, 24)

                    Button {
                        HapticService.shared.tap()
                        timerVM.endSession(modelContext: modelContext)
                    } label: {
                        Text(L10n.timerEndSession)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textDim)
                    }
                }
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Break Screen
struct BreakScreen: View {
    @Environment(TimerViewModel.self) private var timerVM
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            AppColors.night.ignoresSafeArea()

            VStack(spacing: 0) {
                phaseLabel.padding(.top, 20)

                Spacer()

                // Break ring (sage color)
                TimerRingView(
                    progress: timerVM.progress,
                    timeRemaining: timerVM.timeRemaining,
                    phase: .shortBreak,
                    mode: timerVM.selectedMode
                )
                .frame(width: 200, height: 200)

                // Break tip
                breakTip
                    .padding(.horizontal, 32)
                    .padding(.top, 24)

                Spacer()

                // Break actions
                VStack(spacing: 12) {
                    // Skip break
                    Button {
                        HapticService.shared.tap()
                        timerVM.skipBreak()
                    } label: {
                        Label(L10n.breakSkip, systemImage: "forward.fill")
                            .font(AppTypography.labelSmall)
                            .foregroundStyle(AppColors.textMuted)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(AppColors.surface)
                            .overlay(RoundedRectangle(cornerRadius: 100).stroke(AppColors.border, lineWidth: 1))
                            .clipShape(Capsule())
                    }

                    // Extend break
                    Button {
                        HapticService.shared.tap()
                        timerVM.extendBreak(by: 5)
                    } label: {
                        Label(L10n.breakExtend, systemImage: "plus")
                            .font(AppTypography.labelSmall)
                            .foregroundStyle(AppColors.textDim)
                    }

                    // End session
                    Button {
                        HapticService.shared.tap()
                        timerVM.endSession(modelContext: modelContext)
                    } label: {
                        Text(L10n.timerEndSession)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textDim)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

    private var phaseLabel: some View {
        Text(L10n.breakTitle)
            .font(AppTypography.overline)
            .foregroundStyle(AppColors.textDim)
            .tracking(2)
    }

    private var breakTip: some View {
        VStack(spacing: 8) {
            Text(breakActivity)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textMuted)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .padding(16)
        .background(AppColors.sage.opacity(0.06))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColors.sage.opacity(0.18), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var breakActivity: String {
        let activities = [
            L10n.breakActivity1,
            L10n.breakActivity2,
            L10n.breakActivity3,
            L10n.breakActivity4,
        ]
        return activities[timerVM.currentSessionNumber % activities.count]
    }
}
