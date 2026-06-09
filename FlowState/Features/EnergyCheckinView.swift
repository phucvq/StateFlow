import SwiftUI

// MARK: - Energy Checkin View (single-step picker)

struct EnergyCheckinView: View {
    let sessionMode: SessionMode
    /// Called when user confirms their energy level.
    let onSelect: (EnergyLevel) -> Void

    @State private var selected: EnergyLevel? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Sheet handle
            RoundedRectangle(cornerRadius: 2)
                .fill(AppColors.surface2)
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // Title + subtitle
            VStack(spacing: 6) {
                Text(L10n.energyTitle)
                    .font(AppTypography.titleMedium)
                    .foregroundStyle(AppColors.text)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(L10n.energySubtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)

            // Mode context chip
            HStack(spacing: 6) {
                Image(systemName: sessionMode.sfSymbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(sessionMode.accentColor)
                Text(sessionMode.displayName)
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(sessionMode.accentColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(sessionMode.accentColor.opacity(0.1))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(sessionMode.accentColor.opacity(0.25), lineWidth: 1))
            .padding(.bottom, 16)

            // Energy options
            VStack(spacing: 10) {
                ForEach(EnergyLevel.allCases) { level in
                    EnergyOptionRow(
                        level: level,
                        sessionMode: sessionMode,
                        isSelected: selected == level
                    ) {
                        withAnimation(.spring(duration: 0.25)) { selected = level }
                        HapticService.shared.selection()
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 20)

            // Continue button
            PrimaryButton(
                title: selected != nil ? L10n.energyConfirmContinue : L10n.energySelectFirst,
                color: AppColors.amber
            ) {
                if let energy = selected {
                    HapticService.shared.tap()
                    onSelect(energy)
                }
            }
            .disabled(selected == nil)
            .opacity(selected != nil ? 1 : 0.5)
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Energy Option Row

struct EnergyOptionRow: View {
    let level: EnergyLevel
    let sessionMode: SessionMode
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: level.sfSymbol)
                    .font(.system(size: 22))
                    .foregroundStyle(level.symbolColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(level.displayName)
                        .font(AppTypography.labelMedium)
                        .foregroundStyle(AppColors.text)
                    Text(level.description)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textMuted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Text(level.adjustedDuration(for: sessionMode).shortTimerString)
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(isSelected ? AppColors.amber : AppColors.textMuted)
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected ? AppColors.amber.opacity(0.08) : AppColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? AppColors.amber : AppColors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppColors.deep.ignoresSafeArea()
        EnergyCheckinView(sessionMode: .deepWork) { _ in }
    }
}
