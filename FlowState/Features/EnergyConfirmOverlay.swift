import SwiftUI

// MARK: - Energy Confirm Overlay
// Centered popup shown after energy is picked, before session starts.

struct EnergyConfirmOverlay: View {
    let energy: EnergyLevel
    let sessionMode: SessionMode
    let onUseSuggested: () -> Void
    let onKeepOriginal: () -> Void
    let onDismiss: () -> Void

    @State private var countdown: Int = 5
    @State private var barProgress: Double = 1.0
    @State private var countdownTask: Task<Void, Never>?

    private var suggestedDuration: TimeInterval { energy.adjustedDuration(for: sessionMode) }
    private var originalDuration: TimeInterval { sessionMode.workDuration }
    private var isAdjusted: Bool { energy.needsAdjustment(for: sessionMode) }

    var body: some View {
        ZStack {
            // Dim background — tap to dismiss
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture {
                    countdownTask?.cancel()
                    onDismiss()
                }

            // Card
            VStack(spacing: 0) {
                // Mode + energy badges
                HStack(spacing: 8) {
                    HStack(spacing: 5) {
                        Image(systemName: sessionMode.sfSymbol)
                            .font(.system(size: 11, weight: .semibold))
                        Text(sessionMode.displayName)
                            .font(AppTypography.labelSmall)
                    }
                    .foregroundStyle(sessionMode.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(sessionMode.accentColor.opacity(0.12))
                    .clipShape(Capsule())

                    Text("+")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textDim)

                    HStack(spacing: 5) {
                        Image(systemName: energy.sfSymbol)
                            .font(.system(size: 11))
                            .foregroundStyle(energy.symbolColor)
                        Text(energy.displayName)
                            .font(AppTypography.labelSmall)
                            .foregroundStyle(AppColors.text)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppColors.surface2)
                    .clipShape(Capsule())
                }
                .padding(.bottom, 20)

                // Suggestion label
                if isAdjusted {
                    Text("FlowState đề xuất")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textMuted)
                        .padding(.bottom, 4)
                }

                // Big duration
                Text(suggestedDuration.shortTimerString)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.amber)

                // Strikethrough original
                if isAdjusted {
                    HStack(spacing: 4) {
                        Text("thay vì")
                        Text(originalDuration.shortTimerString)
                            .strikethrough(color: AppColors.textDim.opacity(0.6))
                    }
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textDim)
                    .padding(.top, 3)
                } else {
                    Text("Phiên đầy đủ 💪")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textDim)
                        .padding(.top, 3)
                }

                // Progress bar countdown
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(AppColors.surface2)
                        Capsule()
                            .fill(AppColors.amber.opacity(0.7))
                            .frame(width: geo.size.width * barProgress)
                            .animation(.linear(duration: 1), value: barProgress)
                    }
                }
                .frame(height: 3)
                .padding(.top, 18)
                .padding(.bottom, 6)

                Text("Tự động bắt đầu sau \(countdown)s")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textDim)
                    .monospacedDigit()
                    .padding(.bottom, 20)

                // Primary start button
                PrimaryButton(
                    title: "Bắt đầu \(suggestedDuration.shortTimerString)",
                    icon: "play.fill",
                    color: AppColors.amber
                ) {
                    countdownTask?.cancel()
                    onUseSuggested()
                }

                // Keep original option
                if isAdjusted {
                    Button {
                        countdownTask?.cancel()
                        onKeepOriginal()
                    } label: {
                        Text("Giữ nguyên \(originalDuration.shortTimerString)")
                            .font(AppTypography.labelSmall)
                            .foregroundStyle(AppColors.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(24)
            .background(AppColors.deep)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(AppColors.border, lineWidth: 1))
            .shadow(color: .black.opacity(0.35), radius: 32, y: 10)
            .padding(.horizontal, 28)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .center)))
        .onAppear { startCountdown() }
        .onDisappear { countdownTask?.cancel() }
    }

    // MARK: - Countdown

    private func startCountdown() {
        countdown = 5
        barProgress = 1.0
        countdownTask = Task {
            do {
                for remaining in stride(from: 4, through: 0, by: -1) {
                    try await Task.sleep(for: .seconds(1))
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        countdown = remaining
                        barProgress = Double(remaining) / 5.0
                    }
                }
                guard !Task.isCancelled else { return }
                await MainActor.run { onUseSuggested() }
            } catch {}
        }
    }
}
