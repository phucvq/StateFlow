import SwiftUI

// MARK: - Micro Commitment Entry Screen
struct MicroCommitmentScreen: View {
    @Environment(TimerViewModel.self) private var timerVM
    @Environment(\.modelContext) private var modelContext

    @State private var taskInput: String = ""
    @FocusState private var isTextFocused: Bool

    var body: some View {
        ZStack {
            AppColors.night.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Back
                    Button {
                        HapticService.shared.tap()
                        timerVM.isMicroMode = false
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppColors.textMuted)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 20)

                    // Title
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.microTitle)
                            .font(AppTypography.titleLarge)
                            .foregroundStyle(AppColors.text)

                        Text(L10n.microSubtitle)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textMuted)
                            .lineSpacing(4)
                    }
                    .padding(.bottom, 28)

                    // Task input
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.microTaskLabel)
                            .font(AppTypography.overline)
                            .foregroundStyle(AppColors.indigoLight)

                        TextField(L10n.microTaskPlaceholder, text: $taskInput)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.text)
                            .focused($isTextFocused)
                            .tint(AppColors.amber)
                    }
                    .padding(14)
                    .background(AppColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.indigo.opacity(0.3), lineWidth: 1.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.bottom, 14)

                    // Commitment box
                    if !taskInput.isEmpty {
                        commitmentBox
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .animation(.spring(duration: 0.3), value: taskInput)
                            .padding(.bottom, 24)
                    } else {
                        Spacer().frame(height: 24)
                    }

                    // CTA
                    PrimaryButton(
                        title: L10n.microStartButton,
                        icon: "bolt.fill",
                        color: AppColors.sage
                    ) {
                        HapticService.shared.tap()
                        isTextFocused = false
                        timerVM.startMicroCommitment(
                            taskName: taskInput,
                            modelContext: modelContext
                        )
                    }
                    .padding(.bottom, 12)

                    // Regular session link
                    Button {
                        timerVM.isMicroMode = false
                    } label: {
                        Text(L10n.microUseRegular)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textDim)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 24)
            }
        }
        .onTapGesture { isTextFocused = false }
    }

    private var commitmentBox: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.microCommitmentLabel)
                .font(AppTypography.overline)
                .foregroundStyle(AppColors.sage)

            Text(commitmentText)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
                .lineSpacing(4)
        }
        .padding(12)
        .background(AppColors.sage.opacity(0.07))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.sage.opacity(0.22), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var commitmentText: String {
        let task = taskInput.isEmpty ? "..." : taskInput
        return String(format: L10n.microCommitmentText, task)
    }
}

// MARK: - Micro Timer Screen (2-minute minimal UI)
struct MicroTimerScreen: View {
    @Environment(TimerViewModel.self) private var timerVM
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            AppColors.night.ignoresSafeArea()

            VStack(spacing: 0) {
                Text(L10n.microPhaseLabel)
                    .font(AppTypography.overline)
                    .foregroundStyle(AppColors.textDim)
                    .tracking(2)
                    .padding(.top, 40)

                Spacer()

                // Minimal ring
                MicroTimerRing(progress: timerVM.progress, timeRemaining: timerVM.timeRemaining)
                    .frame(width: 200, height: 200)

                // Task name
                if let task = timerVM.currentTaskName {
                    Text(task)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textMuted)
                        .padding(.top, 16)
                }

                Text(L10n.microEncouragement)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textDim)
                    .padding(.top, 20)

                Spacer()

                CircleControlButton(
                    icon: timerVM.isRunning ? "pause.fill" : "play.fill",
                    size: .large,
                    color: AppColors.sage
                ) {
                    timerVM.pauseResume()
                }
                .padding(.bottom, 60)
            }
        }
    }
}

// MARK: - Micro Timer Ring
struct MicroTimerRing: View {
    let progress: Double
    let timeRemaining: TimeInterval

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(AppColors.surface2, lineWidth: 8)

            // Progress
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [AppColors.sage, AppColors.sageLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)

            // Center
            VStack(spacing: 2) {
                Text(timeRemaining.timerString)
                    .font(AppTypography.timerLarge)
                    .foregroundStyle(AppColors.text)
                Text(L10n.timerRemaining)
                    .font(AppTypography.overline)
                    .foregroundStyle(AppColors.textMuted)
                    .tracking(1.5)
            }
        }
    }
}

// MARK: - Micro Complete View
struct MicroCompleteView: View {
    @Environment(TimerViewModel.self) private var timerVM

    let onContinue: (TimeInterval) -> Void
    let onStop: () -> Void

    var body: some View {
        ZStack {
            AppColors.night.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Celebration
                Text("🌱")
                    .font(.system(size: 56))
                    .padding(.bottom, 16)

                Text(L10n.microCompleteTitle)
                    .font(AppTypography.titleLarge)
                    .foregroundStyle(AppColors.text)
                    .multilineTextAlignment(.center)

                if let task = timerVM.currentTaskName {
                    Text(task)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.sage)
                        .padding(.top, 4)
                }

                Text(L10n.microCompleteSubtitle)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 12)
                    .padding(.horizontal, 32)

                Spacer()

                // Continue options
                VStack(spacing: 10) {
                    PrimaryButton(
                        title: String(format: L10n.microContinueWith, "10"),
                        color: AppColors.sage
                    ) {
                        HapticService.shared.tap()
                        onContinue(10 * 60)
                    }
                    .padding(.horizontal, 24)

                    Button {
                        HapticService.shared.tap()
                        onStop()
                    } label: {
                        Text(L10n.microStopMessage)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textMuted)
                    }
                    .padding(.bottom, 8)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    MicroCommitmentScreen()
        .environment(TimerViewModel())
}
