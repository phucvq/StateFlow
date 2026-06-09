import SwiftUI

// MARK: - PrivacyPolicyScreen
struct PrivacyPolicyScreen: View {

    private let effectiveDate = "June 1, 2025"
    private let contactEmail  = "phucvq2@gmail.com"

    var body: some View {
        ZStack {
            AppColors.night.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Privacy Policy")
                            .font(AppTypography.titleLarge)
                            .foregroundStyle(AppColors.text)
                        Text("Effective \(effectiveDate)")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textDim)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 28)

                    sectionDivider

                    // Sections
                    Group {
                        policySection(
                            icon: "hand.raised.fill",
                            color: AppColors.sage,
                            title: "The Short Version",
                            body: """
FlowState is a focus timer app designed with your privacy in mind. We do not collect personal data, we do not run ads, and we do not sell or share anything about you with third parties. Full stop.

Everything you do in FlowState — your sessions, streaks, and preferences — stays on your device.
"""
                        )

                        policySection(
                            icon: "internaldrive.fill",
                            color: AppColors.amber,
                            title: "Data Stored on Your Device",
                            body: """
FlowState stores the following data locally on your iPhone, in Apple's secure on-device storage:

• Focus session history (start time, duration, mode, task name, energy level)
• App preferences (timer mode, notification settings, soundscape choice, language)
• Streak counts and milestone flags
• Subscription status (verified locally via StoreKit 2)

This data never leaves your device unless you opt into iCloud sync (see below).
"""
                        )

                        policySection(
                            icon: "icloud.fill",
                            color: AppColors.indigo,
                            title: "iCloud Sync (Premium)",
                            body: """
Premium subscribers can sync their session history across devices using Apple's CloudKit. When enabled:

• Your session data is encrypted and stored in your personal iCloud container.
• Only you can access it — FlowState (the developer) has no access to your iCloud data.
• iCloud sync is entirely optional and can be disabled at any time in iOS Settings → Your Name → iCloud.

Apple's iCloud privacy policy governs this data: apple.com/privacy
"""
                        )

                        policySection(
                            icon: "chart.bar.xaxis",
                            color: AppColors.amber,
                            title: "Analytics & Crash Reporting",
                            body: """
FlowState does not use any third-party analytics SDKs (no Firebase, no Mixpanel, no Amplitude, etc.).

We do not track how you use the app, which screens you visit, or which features you tap.

If the app crashes, Apple may collect anonymized diagnostic data through their standard crash reporting system. This is governed by Apple's own privacy policy and cannot be disabled per Apple's terms. We only see aggregate, anonymised crash data with no link to individual users.
"""
                        )

                        policySection(
                            icon: "dollarsign.circle.fill",
                            color: AppColors.sage,
                            title: "In-App Purchases",
                            body: """
FlowState offers a Premium subscription through Apple's App Store. All payment processing is handled entirely by Apple — we never see or store your payment information, card details, or billing address.

Purchase history is verified on-device through StoreKit 2. We store only a boolean flag indicating whether you are currently a Premium subscriber.
"""
                        )

                        policySection(
                            icon: "person.2.fill",
                            color: AppColors.textMuted,
                            title: "Children's Privacy",
                            body: """
FlowState is not directed to children under 13 years of age. We do not knowingly collect personal information from children.

If you are a parent or guardian and believe your child has provided personal information through FlowState, please contact us at \(contactEmail) and we will take appropriate action.
"""
                        )

                        policySection(
                            icon: "arrow.triangle.2.circlepath",
                            color: AppColors.amber,
                            title: "Changes to This Policy",
                            body: """
We may update this Privacy Policy from time to time. When we do, the effective date at the top of this page will be updated. For significant changes, we will notify you via an in-app notice.

Your continued use of FlowState after any changes constitutes acceptance of the updated policy.
"""
                        )

                        policySection(
                            icon: "envelope.fill",
                            color: AppColors.indigo,
                            title: "Contact Us",
                            body: """
If you have questions about this Privacy Policy or how your data is handled, please reach out:

\(contactEmail)

We are committed to responding to privacy inquiries within 7 business days.
"""
                        )
                    }

                    Spacer(minLength: 60)
                }
            }
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.night, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Sub-views

    private func policySection(icon: String, color: Color, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.13))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(color)
                }
                Text(title)
                    .font(AppTypography.labelMedium)
                    .foregroundStyle(AppColors.text)
            }

            Text(body)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .overlay(alignment: .bottom) {
            sectionDivider.padding(.horizontal, 24)
        }
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(AppColors.border)
            .frame(height: 1)
            .padding(.horizontal, 24)
    }
}

#Preview {
    NavigationStack { PrivacyPolicyScreen() }
        .preferredColorScheme(.dark)
}
