import SwiftUI

// MARK: - Session Complete View
struct SessionCompleteView: View {
    let totalSessions: Int
    let onDismiss: () -> Void

    @State private var showCelebration = false

    var body: some View {
        ZStack {
            AppColors.night.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Celebration
                Text("🎉")
                    .font(.system(size: 60))
                    .scaleEffect(showCelebration ? 1.1 : 0.8)
                    .animation(.spring(duration: 0.5), value: showCelebration)
                    .padding(.bottom, 20)

                Text(L10n.completeTitle)
                    .font(AppTypography.titleLarge)
                    .foregroundStyle(AppColors.text)
                    .multilineTextAlignment(.center)

                Text(String(format: L10n.completeSubtitle, totalSessions))
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal, 32)

                // Stats summary
                statsRow
                    .padding(.top, 28)
                    .padding(.horizontal, 32)

                Spacer()

                // Actions
                VStack(spacing: 12) {
                    PrimaryButton(
                        title: L10n.completeStartAnother,
                        color: AppColors.amber
                    ) {
                        HapticService.shared.tap()
                        onDismiss()
                    }
                    .padding(.horizontal, 24)

                    Button(action: onDismiss) {
                        Text(L10n.completeDone)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textMuted)
                    }
                }
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            withAnimation { showCelebration = true }
            HapticService.shared.celebrate()
        }
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(
                value: "\(totalSessions)",
                label: L10n.statsSessions
            )
            Divider()
                .background(AppColors.border)
                .frame(height: 36)
            statItem(
                value: TimeInterval(totalSessions * 25 * 60).shortTimerString,
                label: L10n.statsFocused
            )
            Divider()
                .background(AppColors.border)
                .frame(height: 36)
            statItem(
                value: "🔥 \(UserPreferences.shared.streakCurrentDays)",
                label: L10n.statsStreak
            )
        }
        .padding(16)
        .background(AppColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(AppTypography.labelMedium)
                .foregroundStyle(AppColors.text)
            Text(label)
                .font(AppTypography.overline)
                .foregroundStyle(AppColors.textDim)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - SessionModePickerView moved to SoundscapePickerView.swift

#Preview {
    SessionCompleteView(totalSessions: 4, onDismiss: {})
}
