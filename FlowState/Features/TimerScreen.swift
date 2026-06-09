import SwiftUI

struct TimerScreen: View {
    @Environment(TimerViewModel.self) private var timerVM
    @Environment(AudioService.self) private var audioService
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            AppColors.night.ignoresSafeArea()

            VStack(spacing: 0) {
                // Phase indicator
                phaseLabel
                    .padding(.top, 20)

                Spacer()

                // Timer Ring
                TimerRingView(
                    progress: timerVM.progress,
                    timeRemaining: timerVM.timeRemaining,
                    phase: timerVM.currentPhase,
                    mode: timerVM.selectedMode
                )
                .frame(width: 220, height: 220)

                // Task name
                if let task = timerVM.currentTaskName {
                    Text(task)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textMuted)
                        .padding(.top, 12)
                        .lineLimit(1)
                }

                // Session dots — shifted down for more breathing room below the ring
                sessionDots
                    .padding(.top, 28)

                Spacer()

                // Controls — shifted up to create clear gap above soundscape bar
                timerControls
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)

                // Soundscape bar
                soundscapeBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Phase Label
    private var phaseLabel: some View {
        Text(phaseLabelText)
            .font(AppTypography.overline)
            .foregroundStyle(AppColors.textDim)
            .tracking(2)
    }

    private var phaseLabelText: String {
        switch timerVM.currentPhase {
        case .work:
            return "\(L10n.timerPhaseWork) · \(L10n.timerSession) \(timerVM.currentSessionNumber) / \(timerVM.totalSessionsInSequence)"
        case .shortBreak:
            return L10n.timerPhaseShortBreak
        case .longBreak:
            return L10n.timerPhaseLongBreak
        }
    }

    // MARK: - Session Progress Dots
    private var sessionDots: some View {
        HStack(spacing: 8) {
            ForEach(1...timerVM.totalSessionsInSequence, id: \.self) { i in
                Circle()
                    .fill(dotColor(for: i))
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(dotBorderColor(for: i), lineWidth: 1.5)
                    )
                    .shadow(
                        color: i == timerVM.currentSessionNumber ? timerVM.phaseColor.opacity(0.4) : .clear,
                        radius: 4
                    )
                    .scaleEffect(i == timerVM.currentSessionNumber ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: timerVM.currentSessionNumber)
            }
        }
    }

    private func dotColor(for i: Int) -> Color {
        if i < timerVM.currentSessionNumber { return AppColors.amber }
        if i == timerVM.currentSessionNumber { return timerVM.phaseColor }
        return AppColors.surface2
    }

    private func dotBorderColor(for i: Int) -> Color {
        if i == timerVM.currentSessionNumber { return timerVM.phaseColor.opacity(0.5) }
        return .clear
    }

    // MARK: - Timer Controls
    private var timerControls: some View {
        HStack(alignment: .center, spacing: 24) {
            // Skip / Forward:
            //   • Work phase  → skip work early, go to break
            //   • Break phase → skip break, go to next work session
            let canSkip = timerVM.isRunning || timerVM.isPaused || timerVM.isInBreak
            CircleControlButton(icon: "forward.end.fill", size: .small) {
                HapticService.shared.tap()
                if timerVM.isInBreak {
                    timerVM.skipBreak()
                } else {
                    timerVM.skipToBreak()
                }
            }
            .opacity(canSkip ? 1.0 : 0.3)

            // Pause / Resume (main)
            CircleControlButton(
                icon: timerVM.isRunning ? "pause.fill" : "play.fill",
                size: .large,
                color: AppColors.amber
            ) {
                timerVM.pauseResume()
            }

            // Stop
            CircleControlButton(icon: "stop.fill", size: .small) {
                HapticService.shared.tap()
                timerVM.endSession(modelContext: modelContext)
            }
        }
    }

    // MARK: - Soundscape Bar
    private var soundscapeBar: some View {
        Button {
            timerVM.showSoundscapePicker = true
        } label: {
            HStack(spacing: 10) {
                let soundscape = Soundscape.find(id: audioService.currentSoundscapeId) ?? Soundscape.all[0]
                Image(systemName: soundscape.sfSymbol)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppColors.textMuted)
                Text(soundscape.name)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
                Spacer()
                if audioService.isPlaying {
                    SoundWaveView()
                }
                Image(systemName: "chevron.up")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppColors.textDim)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(AppColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - Circle Control Button
struct CircleControlButton: View {
    enum ButtonSize {
        case small, large
        var diameter: CGFloat { self == .large ? 60 : 44 }
        var iconSize: CGFloat { self == .large ? 20 : 14 }
    }

    let icon: String
    let size: ButtonSize
    var color: Color = AppColors.surface
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(size == .large
                          ? LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                          : LinearGradient(colors: [AppColors.surface, AppColors.surface], startPoint: .top, endPoint: .bottom))
                    .frame(width: size.diameter, height: size.diameter)
                    .overlay(Circle().stroke(AppColors.border, lineWidth: 1))
                    .shadow(color: size == .large ? color.opacity(0.35) : .clear, radius: 12, y: 4)

                Image(systemName: icon)
                    .font(.system(size: size.iconSize, weight: .semibold))
                    .foregroundStyle(size == .large ? Color(hex: "#1A0F00") : AppColors.textMuted)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sound Wave Animation
struct SoundWaveView: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(AppColors.sage.opacity(0.7))
                    .frame(width: 2, height: animate ? CGFloat([8, 13, 5, 11, 7][i]) : 4)
                    .animation(
                        .easeInOut(duration: 0.5 + Double(i) * 0.1).repeatForever(autoreverses: true),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}

#Preview {
    TimerScreen()
        .environment(TimerViewModel())
        .environment(AudioService())
}
