import SwiftUI

struct SettingsScreen: View {
    @Environment(SubscriptionService.self) private var subService
    @Environment(AudioService.self) private var audioService

    @AppStorage("pref_energy_checkin") private var energyCheckInEnabled: Bool = true
    @AppStorage("pref_haptics") private var hapticsEnabled: Bool = true
    @AppStorage("pref_soundscape_volume") private var soundscapeVolume: Double = 0.6
    @AppStorage("pref_break_enforcement") private var breakEnforcementRaw: String = "gentle"
    // @AppStorage("pref_app_language") private var appLanguageRaw: String = "system"  // TODO: re-enable with multi-language

    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.night.ignoresSafeArea()

                List {
                    // Account / Premium
                    Section {
                        premiumRow
                    }
                    .listRowBackground(AppColors.surface)

                    // Focus
                    Section(header: sectionHeader(L10n.settingsSectionFocus)) {
                        toggleRow(
                            title: L10n.settingsEnergyCheckin,
                            subtitle: L10n.settingsEnergyCheckinDesc,
                            icon: "bolt.circle.fill",
                            iconColor: AppColors.amber,
                            value: $energyCheckInEnabled
                        )

                        pickerRow(
                            title: L10n.settingsBreakEnforcement,
                            icon: "pause.circle.fill",
                            iconColor: AppColors.sage,
                            options: BreakEnforcement.allCases.map { $0.displayName },
                            selection: Binding(
                                get: { BreakEnforcement(rawValue: breakEnforcementRaw)?.displayName ?? "" },
                                set: { val in
                                    breakEnforcementRaw = BreakEnforcement.allCases.first {
                                        $0.displayName == val
                                    }?.rawValue ?? "gentle"
                                }
                            )
                        )
                    }
                    .listRowBackground(AppColors.surface)

                    // Sound & Haptics
                    Section(header: sectionHeader(L10n.settingsSectionSensory)) {
                        toggleRow(
                            title: L10n.settingsHaptics,
                            subtitle: L10n.settingsHapticsDesc,
                            icon: "waveform",
                            iconColor: AppColors.indigo,
                            value: $hapticsEnabled
                        )

                        volumeRow
                    }
                    .listRowBackground(AppColors.surface)

                    // App
                    Section(header: sectionHeader(L10n.settingsSectionApp)) {
                        // languageRow  // TODO: re-enable when multi-language is back
                        aboutRow
                    }
                    .listRowBackground(AppColors.surface)

                    // Debug (DEBUG only)
                    #if DEBUG
                    Section(header: sectionHeader("Debug")) {
                        Button("Toggle Premium (DEBUG)") {
                            subService.debugSetPremium(!subService.isPremium)
                        }
                        .foregroundStyle(AppColors.amber)

                        Button("Reset Onboarding") {
                            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                        }
                        .foregroundStyle(.red)
                    }
                    .listRowBackground(AppColors.surface)
                    #endif
                }
                .scrollContentBackground(.hidden)
                .background(AppColors.night)
            }
            .navigationTitle(L10n.tabSettings)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppColors.night, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallScreen(trigger: .analytics)
        }
    }

    // MARK: - Premium Row
    private var premiumRow: some View {
        HStack {
            SettingsIcon(icon: "crown.fill", color: AppColors.amber)
            VStack(alignment: .leading, spacing: 2) {
                Text(subService.isPremium ? L10n.settingsPremiumActive : L10n.settingsPremiumUpgrade)
                    .font(AppTypography.labelMedium)
                    .foregroundStyle(AppColors.text)
                Text(subService.isPremium ? L10n.settingsPremiumDesc : L10n.settingsPremiumUpgradeDesc)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
            }
            Spacer()
            if !subService.isPremium {
                Text(L10n.upgrade)
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.amber)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .overlay(Capsule().stroke(AppColors.amber, lineWidth: 1))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !subService.isPremium { showPaywall = true }
        }
    }

    // MARK: - Volume Row
    private var volumeRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SettingsIcon(icon: "speaker.wave.2.fill", color: Color(hex: "#B8A9E8"))
                Text(L10n.settingsSoundVolume)
                    .font(AppTypography.labelMedium)
                    .foregroundStyle(AppColors.text)
                Spacer()
                Text("\(Int(soundscapeVolume * 100))%")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
            }
            Slider(value: $soundscapeVolume, in: 0...1, step: 0.05)
                .tint(AppColors.indigo)
                .onChange(of: soundscapeVolume) { _, newVal in
                    audioService.volume = Float(newVal)
                    UserPreferences.shared.soundscapeVolume = Float(newVal)
                }
        }
    }

    // MARK: - Language Row (disabled — English only for now)
    // TODO: re-enable when multi-language is back
    // private var languageRow: some View { ... }

    // MARK: - About Row
    private var aboutRow: some View {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return NavigationLink(destination: AboutScreen()) {
            HStack {
                SettingsIcon(icon: "info.circle.fill", color: AppColors.textDim)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.settingsAbout)
                        .font(AppTypography.labelMedium)
                        .foregroundStyle(AppColors.text)
                    Text("FlowState v\(version)")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textMuted)
                }
                Spacer()
            }
        }
        .foregroundStyle(AppColors.text)
    }

    // MARK: - Helpers
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppTypography.overline)
            .foregroundStyle(AppColors.textDim)
            .tracking(1.2)
            .textCase(nil)
    }

    private func toggleRow(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        value: Binding<Bool>
    ) -> some View {
        HStack {
            SettingsIcon(icon: icon, color: iconColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.labelMedium)
                    .foregroundStyle(AppColors.text)
                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
            }
            Spacer()
            Toggle("", isOn: value)
                .tint(AppColors.amber)
                .labelsHidden()
        }
    }

    private func pickerRow(
        title: String,
        icon: String,
        iconColor: Color,
        options: [String],
        selection: Binding<String>
    ) -> some View {
        HStack {
            SettingsIcon(icon: icon, color: iconColor)
            Text(title)
                .font(AppTypography.labelMedium)
                .foregroundStyle(AppColors.text)
            Spacer()
            Menu {
                ForEach(options, id: \.self) { opt in
                    Button(opt) { selection.wrappedValue = opt }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selection.wrappedValue)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textMuted)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(AppColors.textDim)
                }
            }
        }
    }
}

// MARK: - Settings Icon
struct SettingsIcon: View {
    let icon: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.15))
                .frame(width: 32, height: 32)
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
        }
        .padding(.trailing, 4)
    }
}
