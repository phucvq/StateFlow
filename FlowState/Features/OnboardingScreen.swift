import SwiftUI

struct OnboardingScreen: View {
    @Binding var isPresented: Bool
    @Environment(TimerViewModel.self) private var timerVM

    @State private var currentStep = 0
    @State private var selectedChallenge: OnboardingChallenge? = nil
    @State private var notificationGranted = false

    // Total steps: 0=Welcome, 1=Challenge, 2=Personalize, 3=Notifications
    private let totalSteps = 4

    var body: some View {
        ZStack {
            AppColors.night.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button (hidden on first and last step)
                HStack {
                    Spacer()
                    if currentStep > 0 && currentStep < totalSteps - 1 {
                        Button(L10n.skip) {
                            completeOnboarding()
                        }
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textDim)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Step content
                TabView(selection: $currentStep) {
                    step1Welcome.tag(0)
                    step2Challenge.tag(1)
                    step3Personalize.tag(2)
                    step4Notifications.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(duration: 0.4), value: currentStep)

                // Progress dots + CTA
                VStack(spacing: 20) {
                    progressDots

                    PrimaryButton(
                        title: currentStep < totalSteps - 1 ? L10n.onboardingNext : L10n.onboardingGetStarted,
                        color: AppColors.amber
                    ) {
                        HapticService.shared.tap()
                        advanceStep()
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Step 0: Welcome (formerly Step 1)
    private var step1Welcome: some View {
        VStack(spacing: 0) {
            Spacer()

            // App icon placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(LinearGradient(
                        colors: [AppColors.indigo, AppColors.amber],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                Text("⏱")
                    .font(.system(size: 48))
            }
            .padding(.bottom, 32)

            Text(L10n.onboardingWelcomeTitle)
                .font(AppTypography.titleHero)
                .foregroundStyle(AppColors.text)
                .multilineTextAlignment(.center)

            Text(L10n.onboardingWelcomeTagline)
                .font(AppTypography.bodyLarge)
                .foregroundStyle(AppColors.amber)
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            Text(L10n.onboardingWelcomeDesc)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.top, 16)
                .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Step 2: Challenge
    private var step2Challenge: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text(L10n.onboardingChallengeTitle)
                    .font(AppTypography.titleLarge)
                    .foregroundStyle(AppColors.text)
                    .multilineTextAlignment(.center)
                Text(L10n.onboardingChallengeSubtitle)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)
            .padding(.horizontal, 24)
            .padding(.bottom, 28)

            VStack(spacing: 10) {
                ForEach(OnboardingChallenge.allCases) { challenge in
                    OnboardingOptionRow(
                        emoji: challenge.emoji,
                        title: challenge.title,
                        isSelected: selectedChallenge == challenge
                    ) {
                        withAnimation(.spring(duration: 0.25)) {
                            selectedChallenge = challenge
                        }
                        HapticService.shared.selection()
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Step 3: Personalize
    private var step3Personalize: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text(L10n.onboardingPersonalizeTitle)
                    .font(AppTypography.titleLarge)
                    .foregroundStyle(AppColors.text)
                    .multilineTextAlignment(.center)

                if let challenge = selectedChallenge {
                    Text(String(format: L10n.onboardingPersonalizeFor, challenge.title))
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textMuted)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 24)
            .padding(.bottom, 28)

            // Recommended mode
            if let challenge = selectedChallenge {
                let mode = challenge.recommendedMode
                VStack(spacing: 12) {
                    Text(L10n.onboardingRecommended)
                        .font(AppTypography.overline)
                        .foregroundStyle(AppColors.textDim)
                        .tracking(1.5)

                    VStack(spacing: 8) {
                        Text(mode.icon + " " + mode.displayName)
                            .font(AppTypography.titleMedium)
                            .foregroundStyle(AppColors.text)

                        HStack(spacing: 20) {
                            VStack {
                                Text(mode.workDuration.shortTimerString)
                                    .font(AppTypography.labelMedium)
                                    .foregroundStyle(mode.accentColor)
                                Text(L10n.timerWork)
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColors.textDim)
                            }
                            Text("·").foregroundStyle(AppColors.textDim)
                            VStack {
                                Text(mode.breakDuration.shortTimerString)
                                    .font(AppTypography.labelMedium)
                                    .foregroundStyle(AppColors.sage)
                                Text(L10n.timerBreak)
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColors.textDim)
                            }
                        }
                    }
                    .padding(20)
                    .background(AppColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(mode.accentColor.opacity(0.3), lineWidth: 1.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .padding(.horizontal, 24)
            }

            Spacer()
        }
    }

    // MARK: - Step 4: Notifications
    private var step4Notifications: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("🔔")
                .font(.system(size: 56))
                .padding(.bottom, 24)

            Text(L10n.onboardingNotifTitle)
                .font(AppTypography.titleLarge)
                .foregroundStyle(AppColors.text)
                .multilineTextAlignment(.center)

            Text(L10n.onboardingNotifDesc)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.top, 12)
                .padding(.horizontal, 32)

            Text(L10n.onboardingNotifNote)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textDim)
                .multilineTextAlignment(.center)
                .padding(.top, 12)
                .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Progress Dots
    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps) { i in
                Capsule()
                    .fill(i == currentStep ? AppColors.amber : AppColors.surface2)
                    .frame(width: i == currentStep ? 20 : 6, height: 6)
                    .animation(.spring(duration: 0.3), value: currentStep)
            }
        }
    }

    // MARK: - Navigation
    private func advanceStep() {
        if currentStep < totalSteps - 1 {
            withAnimation { currentStep += 1 }
        } else {
            // Request notifications then complete
            Task {
                _ = await NotificationService.shared.requestPermission()
                await MainActor.run { completeOnboarding() }
            }
        }
    }

    private func completeOnboarding() {
        // Apply selected mode
        if let challenge = selectedChallenge {
            timerVM.setupMode(challenge.recommendedMode)
            UserPreferences.shared.defaultMode = challenge.recommendedMode
        }
        isPresented = true
    }
}

// MARK: - Onboarding Option Row
struct OnboardingOptionRow: View {
    let emoji: String
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Text(emoji)
                    .font(.system(size: 24))
                Text(title)
                    .font(AppTypography.labelMedium)
                    .foregroundStyle(AppColors.text)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.amber)
                        .font(.system(size: 18))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? AppColors.amber.opacity(0.08) : AppColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppColors.amber : AppColors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    OnboardingScreen(isPresented: .constant(false))
        .environment(TimerViewModel())
}
