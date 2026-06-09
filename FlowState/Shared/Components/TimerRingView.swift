import SwiftUI

struct TimerRingView: View {
    let progress: Double
    let timeRemaining: TimeInterval
    let phase: TimerPhase
    let mode: SessionMode

    @State private var breathe = false

    private var ringGradient: LinearGradient {
        switch phase {
        case .work:
            return LinearGradient(
                colors: [AppColors.indigo, AppColors.amber],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .shortBreak:
            return LinearGradient(
                colors: [AppColors.sage, AppColors.sageLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .longBreak:
            return LinearGradient(
                colors: [AppColors.amber, AppColors.amberLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let lineWidth: CGFloat = size * 0.05

            ZStack {
                // Background breathing glow (idle/paused hint)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [phaseGlowColor.opacity(0.08), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.5
                        )
                    )
                    .scaleEffect(breathe ? 1.08 : 0.96)
                    .animation(
                        .easeInOut(duration: 3).repeatForever(autoreverses: true),
                        value: breathe
                    )

                // Track ring
                Circle()
                    .stroke(AppColors.surface2, lineWidth: lineWidth)

                // Progress ring
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(ringGradient, style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    ))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                // Center content
                VStack(spacing: 3) {
                    Text(timeRemaining.timerString)
                        .font(.custom("DMSerifDisplay-Regular", size: size * 0.2))
                        .foregroundStyle(AppColors.text)
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: true))
                        .animation(.linear(duration: 0.3), value: timeRemaining)
                        .accessibilityLabel(timeRemaining.accessibilityString)

                    Text(phaseLabelShort)
                        .font(.custom("PlusJakartaSans-Bold", size: size * 0.06))
                        .foregroundStyle(AppColors.textMuted)
                        .tracking(1.5)
                        .textCase(.uppercase)
                }
            }
            .frame(width: size, height: size)
        }
        .onAppear { breathe = true }
    }

    private var phaseGlowColor: Color {
        switch phase {
        case .work: return AppColors.indigo
        case .shortBreak: return AppColors.sage
        case .longBreak: return AppColors.amber
        }
    }

    private var phaseLabelShort: String {
        switch phase {
        case .work: return "FOCUS"
        case .shortBreak: return "BREAK"
        case .longBreak: return "REST"
        }
    }
}

#Preview {
    ZStack {
        AppColors.night.ignoresSafeArea()
        TimerRingView(
            progress: 0.65,
            timeRemaining: 16 * 60 + 32,
            phase: .work,
            mode: .deepWork
        )
        .frame(width: 220, height: 220)
    }
}
