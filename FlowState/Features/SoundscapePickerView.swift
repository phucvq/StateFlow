import SwiftUI

// MARK: - Soundscape Picker
struct SoundscapePickerView: View {
    @Environment(AudioService.self) private var audioService
    @Environment(SubscriptionService.self) private var subService
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false
    @ObservedObject private var locManager = LocalizationManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2)
                .fill(AppColors.surface2)
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            Text(L10n.soundPickerTitle)
                .font(AppTypography.titleMedium)
                .foregroundStyle(AppColors.text)
                .padding(.bottom, 20)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Soundscape.all) { soundscape in
                        SoundscapeCell(
                            soundscape: soundscape,
                            isSelected: audioService.currentSoundscapeId == soundscape.id,
                            isLocked: soundscape.isPremium && !subService.isPremium
                        ) {
                            if soundscape.isPremium && !subService.isPremium {
                                showPaywall = true
                            } else {
                                audioService.play(soundscapeId: soundscape.id)
                                UserPreferences.shared.selectedSoundscapeId = soundscape.id
                                HapticService.shared.selection()
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 20)
        }
        .onAppear {
            // Auto-play current selection so user can hear it immediately on open
            let id = audioService.currentSoundscapeId
            if id != "none" && !audioService.isPlaying {
                audioService.play(soundscapeId: id, fadeIn: false)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallScreen(trigger: .analytics)
        }
    }
}

struct SoundscapeCell: View {
    let soundscape: Soundscape
    let isSelected: Bool
    let isLocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isSelected ? AppColors.indigo.opacity(0.15) : AppColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isSelected ? AppColors.indigo : AppColors.border, lineWidth: isSelected ? 2 : 1)
                        )
                        .frame(height: 60)

                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppColors.textDim)
                            .offset(x: 18, y: -18)
                    }

                    Image(systemName: soundscape.sfSymbol)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(isSelected ? AppColors.indigoLight : AppColors.textMuted)
                }

                Text(soundscape.name)
                    .font(AppTypography.caption)
                    .foregroundStyle(isSelected ? AppColors.indigoLight : AppColors.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Session Mode Picker
struct SessionModePickerView: View {
    let onSelect: (SessionMode) -> Void
    @Environment(TimerViewModel.self) private var timerVM
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(AppColors.surface2)
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            Text(L10n.modeSelectorTitle)
                .font(AppTypography.titleMedium)
                .foregroundStyle(AppColors.text)
                .padding(.bottom, 20)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(SessionMode.allCases) { mode in
                        SessionModeRow(
                            mode: mode,
                            isSelected: timerVM.selectedMode == mode
                        ) {
                            onSelect(mode)
                            HapticService.shared.selection()
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 32)
        }
    }
}

struct SessionModeRow: View {
    let mode: SessionMode
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: mode.sfSymbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(mode.accentColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.displayName)
                        .font(AppTypography.labelMedium)
                        .foregroundStyle(AppColors.text)
                    HStack(spacing: 8) {
                        Label(mode.workDuration.shortTimerString, systemImage: "timer")
                            .font(AppTypography.caption)
                            .foregroundStyle(mode.accentColor)
                        Text("·").foregroundStyle(AppColors.textDim)
                        Label(mode.breakDuration.shortTimerString, systemImage: "pause")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textDim)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(mode.accentColor)
                        .font(.system(size: 18))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? mode.accentColor.opacity(0.08) : AppColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? mode.accentColor : AppColors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
