import SwiftUI

// MARK: - SplashScreen
// Shown on every cold launch. Overlaid on top of ContentView (which loads
// underneath), then fades out after ~1.5 s so the transition is instant.
// Add this file to the main app target only (not widgets/watch).

struct SplashScreen: View {

    @State private var scale: CGFloat = 0.82
    @State private var opacity: Double = 0
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            AppColors.night.ignoresSafeArea()

            VStack(spacing: 20) {
                // Icon with layered glow rings
                ZStack {
                    Circle()
                        .fill(AppColors.amber.opacity(0.06))
                        .frame(width: 120, height: 120)
                        .opacity(glowOpacity)

                    Circle()
                        .fill(AppColors.amber.opacity(0.11))
                        .frame(width: 92, height: 92)
                        .opacity(glowOpacity)

                    Circle()
                        .fill(AppColors.surface)
                        .frame(width: 72, height: 72)
                        .overlay(
                            Circle().stroke(AppColors.border, lineWidth: 1)
                        )

                    Image(systemName: "timer")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(AppColors.amber)
                }

                VStack(spacing: 6) {
                    Text("FlowState")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.text)

                    Text("Focus. Flow. Finish.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.textDim)
                        .tracking(2)
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                    scale = 1.0
                    opacity = 1.0
                }
                withAnimation(.easeIn(duration: 0.6).delay(0.15)) {
                    glowOpacity = 1.0
                }
            }
        }
    }
}

#Preview {
    SplashScreen()
}
