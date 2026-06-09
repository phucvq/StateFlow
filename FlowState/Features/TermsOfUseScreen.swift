import SwiftUI

// MARK: - TermsOfUseScreen
struct TermsOfUseScreen: View {

    private let effectiveDate = "June 1, 2025"
    private let contactEmail  = "petphuc.vq@gmail.com"

    var body: some View {
        ZStack {
            AppColors.night.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Terms of Use")
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

                    Group {
                        termsSection(
                            icon: "doc.text.fill",
                            color: AppColors.amber,
                            title: "Agreement to Terms",
                            body: """
By downloading or using FlowState, you agree to be bound by these Terms of Use. If you do not agree to these terms, please do not use the app.

These terms apply to the FlowState app for iOS, developed and operated by Phuc Vo ("we", "us", or "our").
"""
                        )

                        termsSection(
                            icon: "app.fill",
                            color: AppColors.indigo,
                            title: "Use of the App",
                            body: """
FlowState is a focus and productivity timer application. You may use it for personal, non-commercial purposes in accordance with these terms.

You agree not to:
• Reverse engineer, decompile, or attempt to extract the source code of the app
• Use the app for any unlawful purpose or in violation of any regulations
• Attempt to gain unauthorized access to any part of the app or its infrastructure
• Reproduce, copy, or sell any portion of the app without express written permission
"""
                        )

                        termsSection(
                            icon: "crown.fill",
                            color: AppColors.amber,
                            title: "Premium Subscription",
                            body: """
FlowState offers optional Premium features available through a paid subscription ("FlowState Premium"). By subscribing:

Billing: Subscriptions are billed through your Apple ID account on a monthly or annual basis, as selected at purchase. Payment is charged to your Apple ID account at confirmation of purchase.

Auto-renewal: Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period.

Cancellation: You may cancel at any time via iOS Settings → Your Name → Subscriptions. Cancellation takes effect at the end of the current billing period; no refunds are issued for unused time.

Free trial: If offered, the free trial period begins immediately upon subscription. You will be charged at the end of the trial unless cancelled beforehand.

Price changes: We reserve the right to change subscription prices. You will be notified of any price change before it takes effect.
"""
                        )

                        termsSection(
                            icon: "lock.fill",
                            color: AppColors.sage,
                            title: "Intellectual Property",
                            body: """
All content, design, graphics, user interface, and code within FlowState are the intellectual property of Phuc Vo and are protected by applicable copyright and intellectual property laws.

You are granted a limited, non-exclusive, non-transferable licence to use FlowState on devices you own or control, solely for your personal, non-commercial purposes.

The "FlowState" name, logo, and any associated marks are proprietary to Phuc Vo.
"""
                        )

                        termsSection(
                            icon: "exclamationmark.triangle.fill",
                            color: Color(hex: "#E07A7A"),
                            title: "Disclaimer of Warranties",
                            body: """
FlowState is provided on an "as is" and "as available" basis without warranties of any kind, either express or implied.

We do not warrant that:
• The app will be uninterrupted, error-free, or free of viruses
• The results obtained from use of the app will be accurate or reliable
• Any defects in the app will be corrected

FlowState is a productivity tool. We make no claims about its effectiveness for any medical, therapeutic, or clinical purpose.
"""
                        )

                        termsSection(
                            icon: "shield.slash.fill",
                            color: AppColors.textMuted,
                            title: "Limitation of Liability",
                            body: """
To the fullest extent permitted by applicable law, Phuc Vo shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of (or inability to use) FlowState.

Our total liability to you for any claims arising from your use of the app shall not exceed the amount you paid for Premium in the 12 months preceding the claim.
"""
                        )

                        termsSection(
                            icon: "arrow.triangle.2.circlepath",
                            color: AppColors.amber,
                            title: "Changes to These Terms",
                            body: """
We reserve the right to modify these Terms of Use at any time. When we make changes, we will update the effective date at the top of this page and notify you via an in-app notice for material changes.

Your continued use of FlowState following any changes constitutes your acceptance of the new terms.
"""
                        )

                        termsSection(
                            icon: "scale.3d",
                            color: AppColors.indigo,
                            title: "Governing Law",
                            body: """
These Terms of Use are governed by and construed in accordance with the laws of Vietnam, without regard to conflict of law principles.

Any disputes arising from these terms or your use of FlowState shall be resolved through good-faith negotiation. If resolution cannot be reached, disputes shall be subject to the exclusive jurisdiction of the competent courts of Vietnam.
"""
                        )

                        termsSection(
                            icon: "envelope.fill",
                            color: AppColors.sage,
                            title: "Contact",
                            body: """
If you have questions about these Terms of Use, please contact us at:

\(contactEmail)
"""
                        )
                    }

                    Spacer(minLength: 60)
                }
            }
        }
        .navigationTitle("Terms of Use")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.night, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Sub-views

    private func termsSection(icon: String, color: Color, title: String, body: String) -> some View {
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
            sectionDivider
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
    NavigationStack { TermsOfUseScreen() }
        .preferredColorScheme(.dark)
}
