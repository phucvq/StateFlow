import SwiftUI
import StoreKit

struct PaywallScreen: View {
    @Environment(SubscriptionService.self) private var subService
    @Environment(\.dismiss) private var dismiss

    let trigger: PaywallFeature

    @State private var selectedPlan: String = SubscriptionService.ProductID.annual

    private let premiumFeatures: [(icon: String, text: String)] = [
        ("bolt.fill", "paywallFeature1"),
        ("waveform.badge.plus", "paywallFeature2"),
        ("chart.bar.fill", "paywallFeature3"),
        ("applewatch", "paywallFeature4"),
        ("speaker.wave.3.fill", "paywallFeature5"),
        ("square.grid.2x2.fill", "paywallFeature6"),
    ]

    var body: some View {
        ZStack {
            AppColors.night.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Close
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppColors.textDim)
                                .padding(10)
                                .background(AppColors.surface)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Trigger badge
                    Text(trigger.title)
                        .font(AppTypography.overline)
                        .foregroundStyle(AppColors.amber)
                        .tracking(1.2)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(AppColors.amber.opacity(0.1))
                        .overlay(Capsule().stroke(AppColors.amber.opacity(0.3), lineWidth: 1))
                        .clipShape(Capsule())
                        .padding(.top, 8)

                    // Title
                    VStack(spacing: 6) {
                        Text(L10n.paywallTitle)
                            .font(AppTypography.titleLarge)
                            .foregroundStyle(AppColors.text)
                            .multilineTextAlignment(.center)
                        Text(L10n.paywallSubtitle)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                    // Features
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(premiumFeatures, id: \.text) { feat in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(AppColors.amber.opacity(0.1))
                                        .frame(width: 28, height: 28)
                                    Image(systemName: feat.icon)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(AppColors.amber)
                                }
                                Text(L10n.string(feat.text))
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColors.textMuted)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)

                    // Plan selector
                    VStack(spacing: 10) {
                        if !subService.products.isEmpty {
                            ForEach(subService.products) { product in
                                PlanOptionRow(
                                    product: product,
                                    isSelected: selectedPlan == product.id,
                                    isRecommended: product.id == SubscriptionService.ProductID.annual
                                ) {
                                    selectedPlan = product.id
                                    HapticService.shared.selection()
                                }
                            }
                        } else {
                            // Placeholder when products not loaded
                            PlanOptionRow(
                                productId: SubscriptionService.ProductID.annual,
                                title: L10n.planAnnual,
                                price: "$24.99",
                                subPrice: "$2.08/\(L10n.planMonth)",
                                isSelected: selectedPlan == SubscriptionService.ProductID.annual,
                                isRecommended: true
                            ) {
                                selectedPlan = SubscriptionService.ProductID.annual
                            }
                            PlanOptionRow(
                                productId: SubscriptionService.ProductID.monthly,
                                title: L10n.planMonthly,
                                price: "$3.99/\(L10n.planMonth)",
                                subPrice: nil,
                                isSelected: selectedPlan == SubscriptionService.ProductID.monthly,
                                isRecommended: false
                            ) {
                                selectedPlan = SubscriptionService.ProductID.monthly
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // CTA
                    PrimaryButton(
                        title: selectedPlan == SubscriptionService.ProductID.annual
                            ? L10n.paywallTrialCTA
                            : L10n.paywallMonthlyCTA,
                        color: AppColors.amber,
                        isLoading: subService.isLoading
                    ) {
                        Task {
                            if let product = subService.products.first(where: { $0.id == selectedPlan }) {
                                let success = await subService.purchase(product)
                                if success { dismiss() }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Fine print
                    Text(L10n.paywallFinePrint)
                        .font(AppTypography.overline)
                        .foregroundStyle(AppColors.textDim)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.top, 10)

                    // Restore
                    Button {
                        Task { await subService.restorePurchases() }
                    } label: {
                        Text(L10n.paywallRestore)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textDim)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Plan Option Row (with Product)
struct PlanOptionRow: View {
    var product: Product? = nil
    var productId: String = ""
    var title: String = ""
    var price: String = ""
    var subPrice: String? = nil
    let isSelected: Bool
    let isRecommended: Bool
    let onSelect: () -> Void

    // Init with product
    init(product: Product, isSelected: Bool, isRecommended: Bool, onSelect: @escaping () -> Void) {
        self.product = product
        self.productId = product.id
        self.title = product.displayName
        self.price = product.displayPrice
        self.isSelected = isSelected
        self.isRecommended = isRecommended
        self.onSelect = onSelect
    }

    // Init with manual data
    init(productId: String, title: String, price: String, subPrice: String?, isSelected: Bool, isRecommended: Bool, onSelect: @escaping () -> Void) {
        self.productId = productId
        self.title = title
        self.price = price
        self.subPrice = subPrice
        self.isSelected = isSelected
        self.isRecommended = isRecommended
        self.onSelect = onSelect
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(AppTypography.labelMedium)
                            .foregroundStyle(AppColors.text)
                        if isRecommended {
                            Text(L10n.planBestValue)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color(hex: "#1A0F00"))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(AppColors.amber)
                                .clipShape(Capsule())
                        }
                    }
                    if let sub = subPrice {
                        Text(sub)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textDim)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(price)
                        .font(AppTypography.labelMedium)
                        .foregroundStyle(isSelected ? AppColors.amber : AppColors.textMuted)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? AppColors.amber.opacity(0.07) : AppColors.surface)
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
    PaywallScreen(trigger: .microCommitmentLimit)
        .environment(SubscriptionService())
}
