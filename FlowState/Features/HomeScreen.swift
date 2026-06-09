import SwiftUI
import SwiftData

struct HomeScreen: View {
    @Environment(TimerViewModel.self) private var timerVM
    @Environment(SubscriptionService.self) private var subService
    @Environment(AudioService.self) private var audioService
    @Environment(\.modelContext) private var modelContext

    @State private var homeVM = HomeViewModel()
    @State private var showSessionComplete = false

    var body: some View {
        @Bindable var timerVM = timerVM

        NavigationStack {
            ZStack {
                AppColors.night.ignoresSafeArea()

                // Active timer or idle home
                if timerVM.isMicroMode {
                    MicroFlowView()
                } else if timerVM.isIdle {
                    idleHomeContent
                } else if case .sessionComplete(let n) = timerVM.timerState {
                    SessionCompleteView(totalSessions: n) {
                        timerVM.dismissSessionComplete()
                    }
                } else if timerVM.isBreakReady {
                    BreakReadyView()
                } else if timerVM.isWorkReady {
                    WorkReadyView()
                } else if timerVM.isInBreak {
                    BreakScreen()
                } else {
                    TimerScreen()
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $timerVM.showEnergyCheckin) {
            EnergyCheckinView(sessionMode: timerVM.selectedMode) { energy in
                timerVM.energySelected(energy)
            }
            .presentationDetents([.fraction(0.60), .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(AppColors.deep)
        }
        .onChange(of: timerVM.showEnergyCheckin) { _, isShowing in
            // When sheet closes with a pending energy, show confirm overlay after dismiss animation
            if !isShowing, timerVM.pendingEnergy != nil {
                Task {
                    try? await Task.sleep(for: .milliseconds(380))
                    timerVM.showEnergyConfirmOverlay = true
                }
            }
        }
        .overlay {
            if timerVM.showEnergyConfirmOverlay, let energy = timerVM.pendingEnergy {
                EnergyConfirmOverlay(
                    energy: energy,
                    sessionMode: timerVM.selectedMode,
                    onUseSuggested: {
                        timerVM.startAfterEnergyCheckIn(
                            energy: energy,
                            finalDuration: energy.adjustedDuration(for: timerVM.selectedMode),
                            modelContext: modelContext
                        )
                    },
                    onKeepOriginal: {
                        timerVM.startAfterEnergyCheckIn(
                            energy: energy,
                            finalDuration: timerVM.selectedMode.workDuration,
                            modelContext: modelContext
                        )
                    },
                    onDismiss: { timerVM.cancelEnergyConfirm() }
                )
                .transition(
                    AnyTransition.opacity.combined(
                        with: AnyTransition.scale(scale: 0.96, anchor: .center)
                    )
                )
                .zIndex(100)
            }
        }
        .animation(.spring(duration: 0.3), value: timerVM.showEnergyConfirmOverlay)
        .sheet(isPresented: $timerVM.showPaywall) {
            PaywallScreen(trigger: timerVM.paywallTrigger)
        }
        .sheet(isPresented: $timerVM.showSoundscapePicker) {
            SoundscapePickerView()
                .presentationDetents([.fraction(0.62), .large])
                .presentationBackground(AppColors.deep)
        }
        .sheet(isPresented: $timerVM.showModeSelector) {
            SessionModePickerView { mode in
                timerVM.setupMode(mode)
            }
            .presentationDetents([.fraction(0.72), .large])
            .presentationBackground(AppColors.deep)
        }
        .onAppear {
            homeVM.loadTodayStats(from: modelContext)
        }
        // Auto-manage audio with session lifecycle
        .onChange(of: timerVM.timerState) { _, newState in
            switch newState {
            case .workRunning:
                // Start soundscape when work session begins (if one is selected)
                let id = UserPreferences.shared.selectedSoundscapeId
                if id != "none" && !audioService.isPlaying {
                    audioService.play(soundscapeId: id)
                }
            case .idle, .sessionComplete:
                audioService.stop()
            default:
                break
            }
        }
    }

    // MARK: - Idle Home
    private var idleHomeContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header (includes inline streak badge)
                homeHeader
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                // Today stats
                if homeVM.todayFocusMinutes > 0 {
                    todayStatsChip
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }

                // Session Card
                SessionModeCardView(
                    mode: timerVM.selectedMode,
                    workDuration: timerVM.workDuration,
                    breakDuration: timerVM.breakDuration,
                    onChangeTap: { timerVM.showModeSelector = true },
                    onStartTap: {
                        HapticService.shared.tap()
                        timerVM.startSession(in: modelContext)
                    }
                )
                .padding(.horizontal, 24)
                .padding(.top, 24)

                // Micro-commitment link
                microStartLink
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                // Streak reset message
                if homeVM.showStreakResetMessage {
                    streakResetBanner
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                }

                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Header
    private var homeHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greetingText)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)

            Text(L10n.homeTagline)
                .font(AppTypography.titleLarge)
                .foregroundStyle(AppColors.text)

            if homeVM.streakDays > 0 {
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text(String(format: L10n.streakDays, homeVM.streakDays))
                        .font(AppTypography.labelSmall)
                }
                .foregroundStyle(AppColors.amber)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(AppColors.amber.opacity(0.08))
                .overlay(Capsule().stroke(AppColors.amber.opacity(0.25), lineWidth: 1))
                .clipShape(Capsule())
                .padding(.top, 6)
            }
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return L10n.greetingMorning }
        if hour < 17 { return L10n.greetingAfternoon }
        return L10n.greetingEvening
    }

    // MARK: - Today Stats Chip
    private var todayStatsChip: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 11, weight: .semibold))
            Text(String(format: L10n.homeTodayMinutes, homeVM.todayFocusMinutes))
                .font(AppTypography.labelSmall)
        }
        .foregroundStyle(AppColors.sage)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(AppColors.sage.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 100)
                .stroke(AppColors.sage.opacity(0.25), lineWidth: 1)
        )
        .clipShape(Capsule())
    }

    // MARK: - Micro Start Link
    private var microStartLink: some View {
        Button {
            HapticService.shared.tap()
            handleMicroStart()
        } label: {
            HStack(spacing: 6) {
                Text(L10n.homeMicroStartPrompt)
                    .foregroundStyle(AppColors.textMuted)
                Text(L10n.homeMicroStartAction)
                    .foregroundStyle(AppColors.sage)
                    .underline(pattern: .dot)
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppColors.sage)
            }
            .font(AppTypography.caption)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func handleMicroStart() {
        if timerVM.canUseMicroCommitment(isPremium: subService.isPremium) {
            // Navigate to micro commitment
            // We'll use a navigation push via timerVM state
            timerVM.isMicroMode = true
            // The TimerScreen will detect isMicroMode and show MicroCommitmentScreen
        } else {
            timerVM.paywallTrigger = .microCommitmentLimit
            timerVM.showPaywall = true
        }
    }

    // MARK: - Streak Reset Banner
    private var streakResetBanner: some View {
        HStack(spacing: 12) {
            Text("💪")
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.streakResetTitle)
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.text)
                Text(L10n.streakResetMessage)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
            }
            Spacer()
            Button {
                withAnimation { homeVM.showStreakResetMessage = false }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textDim)
            }
        }
        .padding(14)
        .background(AppColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Energy Confirm Overlay

struct EnergyConfirmOverlay: View {
    let energy: EnergyLevel
    let sessionMode: SessionMode
    let onUseSuggested: () -> Void
    let onKeepOriginal: () -> Void
    let onDismiss: () -> Void

    @State private var countdown: Int = 5
    @State private var barProgress: Double = 1.0
    @State private var countdownTask: Task<Void, Never>?
    @ObservedObject private var locManager = LocalizationManager.shared

    private var suggestedDuration: TimeInterval { energy.adjustedDuration(for: sessionMode) }
    private var originalDuration: TimeInterval { sessionMode.workDuration }
    private var isAdjusted: Bool { energy.needsAdjustment(for: sessionMode) }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { countdownTask?.cancel(); onDismiss() }

            VStack(spacing: 0) {
                // Badges
                HStack(spacing: 8) {
                    HStack(spacing: 5) {
                        Image(systemName: sessionMode.sfSymbol)
                            .font(.system(size: 11, weight: .semibold))
                        Text(sessionMode.displayName)
                            .font(AppTypography.labelSmall)
                    }
                    .foregroundStyle(sessionMode.accentColor)
                    .padding(.horizontal, 10).padding(.vertical, 5)
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
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(AppColors.surface2)
                    .clipShape(Capsule())
                }
                .padding(.bottom, 20)

                if isAdjusted {
                    Text(L10n.energyConfirmSuggested)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textMuted)
                        .padding(.bottom, 4)
                }

                Text(suggestedDuration.shortTimerString)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.amber)

                if isAdjusted {
                    HStack(spacing: 4) {
                        Text(L10n.energyConfirmInstead)
                        Text(originalDuration.shortTimerString)
                            .strikethrough(color: AppColors.textDim.opacity(0.6))
                    }
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textDim)
                    .padding(.top, 3)
                } else {
                    Text(L10n.energyConfirmFullSession)
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

                Text(String(format: L10n.energyConfirmAutoStart, countdown))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textDim)
                    .monospacedDigit()
                    .padding(.bottom, 20)

                PrimaryButton(
                    title: String(format: L10n.energyConfirmStart, suggestedDuration.shortTimerString),
                    icon: "play.fill",
                    color: AppColors.amber,
                    action: { countdownTask?.cancel(); onUseSuggested() }
                )

                if isAdjusted {
                    Button {
                        countdownTask?.cancel()
                        onKeepOriginal()
                    } label: {
                        Text(String(format: L10n.energyConfirmKeepOriginal, originalDuration.shortTimerString))
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
        .onAppear {
            countdown = 5; barProgress = 1.0
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
        .onDisappear { countdownTask?.cancel() }
    }
}

// MARK: - Micro Mode Navigation
extension HomeScreen {
    @ViewBuilder
    var microModeDestination: some View {
        if timerVM.isMicroMode && timerVM.isIdle {
            MicroCommitmentScreen()
        }
    }
}

#Preview {
    HomeScreen()
        .modelContainer(for: [SessionRecord.self, EnergyLog.self], inMemory: true)
        .environment(TimerViewModel())
        .environment(SubscriptionService())
        .environment(AudioService())
}
