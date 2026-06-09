import SwiftUI

struct AboutScreen: View {
    @Environment(\.dismiss) private var dismiss

    private let appVersion: String = {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(v) (\(b))"
    }()


    var body: some View {
        ZStack {
            AppColors.night.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: - Hero
                    heroSection
                        .padding(.horizontal, 24)
                        .padding(.top, 32)

                    // MARK: - Manifesto
                    manifestoSection
                        .padding(.horizontal, 24)
                        .padding(.top, 40)

                    divider
                        .padding(.horizontal, 24)
                        .padding(.top, 36)

                    // MARK: - Core Beliefs
                    beliefsSection
                        .padding(.horizontal, 24)
                        .padding(.top, 28)

                    divider
                        .padding(.horizontal, 24)
                        .padding(.top, 32)

                    // MARK: - Links
                    linksSection
                        .padding(.horizontal, 24)
                        .padding(.top, 28)

                    // MARK: - Footer
                    footerSection
                        .padding(.horizontal, 24)
                        .padding(.top, 48)
                        .padding(.bottom, 60)
                }
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.night, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // App icon placeholder — a stylised flame ring
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.amber.opacity(0.18), AppColors.indigo.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .overlay(Circle().stroke(AppColors.amber.opacity(0.3), lineWidth: 1))

                Image(systemName: "flame.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.amber, AppColors.amberLight],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
            }

            Text("FlowState")
                .font(AppTypography.titleLarge)
                .foregroundStyle(AppColors.text)

            Text("Focus for brains that work differently.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Manifesto Section

    private var manifestoSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Why FlowState exists")
                .font(AppTypography.overline)
                .foregroundStyle(AppColors.textDim)
                .tracking(1.4)

            VStack(alignment: .leading, spacing: 14) {
                manifestoParagraph(
                    "Every focus app we tried assumed you already had focus. They handed you a 25-minute timer and left you to figure out the rest."
                )
                manifestoParagraph(
                    "But if your brain runs on dopamine and context-switching, a plain countdown isn't a tool — it's a taunt."
                )
                manifestoParagraph(
                    "FlowState is built differently. It meets your energy where it is, helps you start before you feel ready, and treats rest as part of the work — not a reward you have to earn."
                )
            }
        }
    }

    private func manifestoParagraph(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.body)
            .foregroundStyle(AppColors.textMuted)
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Core Beliefs

    private var beliefsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("What we believe")
                .font(AppTypography.overline)
                .foregroundStyle(AppColors.textDim)
                .tracking(1.4)

            VStack(alignment: .leading, spacing: 14) {
                beliefRow(
                    accent: AppColors.amber,
                    symbol: "bolt.fill",
                    title: "Focus is a skill, not a trait.",
                    body: "You're not broken — you just haven't had tools built for how you think."
                )
                beliefRow(
                    accent: AppColors.sage,
                    symbol: "leaf.fill",
                    title: "Rest is fuel, not failure.",
                    body: "Breaks aren't a reward for finishing. They're what makes the next session possible."
                )
                beliefRow(
                    accent: AppColors.indigo,
                    symbol: "sparkle",
                    title: "Starting beats planning.",
                    body: "A 2-minute commitment right now is worth more than a perfect schedule you never begin."
                )
            }
        }
    }

    private func beliefRow(accent: Color, symbol: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(accent.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accent)
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.text)
                Text(body)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Links Section

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Get in touch")
                .font(AppTypography.overline)
                .foregroundStyle(AppColors.textDim)
                .tracking(1.4)
                .padding(.bottom, 8)

            linkRow(
                icon: "star.fill",
                iconColor: AppColors.amber,
                title: "Rate FlowState",
                subtitle: "Your review helps more people find focus.",
                action: { rateApp() }
            )

            // NavigationLink destinations — all in-app, no external URLs needed
            NavigationLink(destination: FeedbackScreen()) {
                linkRowContent(
                    icon: "bubble.left.fill",
                    iconColor: AppColors.indigo,
                    title: "Send Feedback",
                    subtitle: "Bug? Idea? We read everything."
                )
            }
            .buttonStyle(.plain)

            NavigationLink(destination: PrivacyPolicyScreen()) {
                linkRowContent(
                    icon: "lock.shield.fill",
                    iconColor: AppColors.sage,
                    title: "Privacy Policy",
                    subtitle: "We don't sell your data. Ever."
                )
            }
            .buttonStyle(.plain)

            NavigationLink(destination: TermsOfUseScreen()) {
                linkRowContent(
                    icon: "doc.text.fill",
                    iconColor: AppColors.textDim,
                    title: "Terms of Use",
                    subtitle: nil
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func linkRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            linkRowContent(icon: icon, iconColor: iconColor, title: title, subtitle: subtitle)
        }
        .buttonStyle(.plain)
    }

    /// Shared row layout used by both Button and NavigationLink rows.
    private func linkRowContent(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String?
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.13))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.labelMedium)
                    .foregroundStyle(AppColors.text)
                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textMuted)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppColors.textDim)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Made with 🧠 + ☕")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textDim)

            Text(appVersion)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(AppColors.textDim.opacity(0.6))

            Text("© \(Calendar.current.component(.year, from: Date())) FlowState")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textDim.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Divider
    private var divider: some View {
        Rectangle()
            .fill(AppColors.border)
            .frame(height: 1)
    }

    // MARK: - Actions

    private func rateApp() {
        // Replace YOUR_APP_ID with the App Store numeric ID once published
        if let url = URL(string: "https://apps.apple.com/app/idYOUR_APP_ID?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    NavigationStack {
        AboutScreen()
    }
    .preferredColorScheme(.dark)
}
