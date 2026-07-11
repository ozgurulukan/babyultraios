import SwiftUI
import RevenueCat

// MARK: - Premium Paywall (New Design)
struct PremiumView: View {
    @Environment(\.presentationMode) var dismiss
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var subscriptionsManager: SubscriptionsManager
    @Environment(\.openURL) var openURL

    @State private var selectedPlan = 0
    @State private var isPurchasing = false
    @State private var showSuccessBanner = false

    private let planDisplays: [PlanDisplay] = [
        PlanDisplay(
            title: NSLocalizedString("premium.yearly_title", comment: ""),
            subtitle: NSLocalizedString("premium.yearly_subtitle", comment: ""),
            tag: NSLocalizedString("premium.best_value", comment: ""),
            productIndex: 0
        ),
        PlanDisplay(
            title: NSLocalizedString("premium.weekly_title", comment: ""),
            subtitle: NSLocalizedString("premium.billed_weekly", comment: ""),
            tag: nil,
            productIndex: 1
        ),
    ]

    // Design colors
    private let creamBg = Color(hex: "FFF3F1")
    private let cardBg = Color.white.opacity(0.4)
    private let primaryText = Color(hex: "2D2422")
    private let secondaryText = Color.white
    private let accentBrown = Color(hex: "FF4D85")
    private let accentCoral = Color(hex: "FF88A8")
    private let starYellow = Color(hex: "FF4D85")

    var body: some View {
        ZStack {
            Image("bg")
                .resizable()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                closeButton
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .zIndex(1)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        heroSection
                            .padding(.top, 16)

                        benefitsSection
                            .padding(.horizontal, 24)

                        pricingSection
                            .padding(.horizontal, 24)

                        ctaSection
                            .padding(.horizontal, 24)

                        footerLinks
                            .padding(.top, 8)
                            .padding(.bottom, 32)
                    }
                }
            }
        }
        .preferredColorScheme(.light)
        .overlay(
            successBanner
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSuccessBanner)
        )
        .onAppear { Task { await subscriptionsManager.loadProducts() } }
    }

    var closeButton: some View {
        HStack {
            Spacer()
            Button { dismiss.wrappedValue.dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(primaryText)
                    .frame(width: 40, height: 40)
                    .background(Color(hex: "FFF3F1").opacity(0.5))
                    .background(.ultraThinMaterial.opacity(0.8))
                    .clipShape(Circle())
            }
        }
    }

    var heroSection: some View {
        VStack(spacing: 16) {
            // PRO Badge
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12, weight: .bold))
                Text(NSLocalizedString("premium.pro_badge", comment: ""))
                    .font(.system(size: 14, weight: .bold))
                    .tracking(1.0)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [accentBrown, accentCoral],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: accentBrown.opacity(0.3), radius: 8, x: 0, y: 4)

            // Titles
            VStack(spacing: 8) {
                Text(NSLocalizedString("premium.unlock_title", comment: ""))
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(primaryText)
                    .multilineTextAlignment(.center)
                    .tracking(-0.5)

                Text(NSLocalizedString("premium.unlock_subtitle", comment: ""))
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
        }
    }

    var benefitsSection: some View {
        VStack(spacing: 12) {
            BenefitRow(
                icon: "sparkles",
                text: NSLocalizedString("premium.benefit_pro_templates", comment: ""),
                iconBg: Color(hex: "FF88A8").opacity(0.15),
                iconColor: Color(hex: "FF4D85")
            )
            BenefitRow(
                icon: "tag.fill",
                text: NSLocalizedString("premium.benefit_credits", comment: ""),
                iconBg: Color(hex: "FF88A8").opacity(0.15),
                iconColor: Color(hex: "FF4D85")
            )
            BenefitRow(
                icon: "drop.fill",
                text: NSLocalizedString("premium.benefit_no_watermark", comment: ""),
                iconBg: Color(hex: "FF88A8").opacity(0.15),
                iconColor: Color(hex: "FF4D85")
            )
            BenefitRow(
                icon: "arrow.down.circle.fill",
                text: NSLocalizedString("premium.benefit_4k", comment: ""),
                iconBg: Color(hex: "FF88A8").opacity(0.15),
                iconColor: Color(hex: "FF4D85")
            )
        }
        // Card background removed as requested
    }

    private var dynamicPlanDisplays: [PlanDisplay] {
        var displays = planDisplays
        if let yearlyPackage = packageForPlan(at: 0) {
            let product = yearlyPackage.storeProduct
            let yearlyNS = NSDecimalNumber(decimal: product.price)
            let monthlyNS = yearlyNS.dividing(by: NSDecimalNumber(value: 12))
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = product.currencyCode
            let monthlyStr = formatter.string(from: monthlyNS) ?? "$4.16"
            displays[0] = PlanDisplay(
                title: NSLocalizedString("premium.yearly_title", comment: ""),
                subtitle: String(format: NSLocalizedString("premium.yearly_subtitle_format", comment: ""), monthlyStr),
                tag: NSLocalizedString("premium.best_value", comment: ""),
                productIndex: 0
            )
        }
        return displays
    }

    var pricingSection: some View {
        HStack(spacing: 16) {
            ForEach(dynamicPlanDisplays.indices, id: \.self) { index in
                PlanCardNew(
                    plan: dynamicPlanDisplays[index],
                    package: packageForPlan(at: index),
                    isSelected: selectedPlan == index
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedPlan = index
                    }
                }
            }
        }
    }

    func packageForPlan(at index: Int) -> Package? {
        let productIdx = planDisplays[index].productIndex
        guard subscriptionsManager.packages.indices.contains(productIdx) else { return nil }
        return subscriptionsManager.packages[productIdx]
    }

    private var ctaFooterText: String {
        if selectedPlan == 1 { return "" }
        if let package = packageForPlan(at: selectedPlan) {
            let unit = package.storeProduct.subscriptionPeriod?.unit
            let periodText = unit == .week ? NSLocalizedString("common.week_unit", comment: "") : NSLocalizedString("common.year_unit", comment: "")
            return String(format: NSLocalizedString("premium.trial_format", comment: ""), package.localizedPriceString, periodText)
        }
        return NSLocalizedString("premium.yearly_fallback", comment: "")
    }

    var ctaSection: some View {
        VStack(spacing: 12) {
            Button {
                isPurchasing = true
                if let package = packageForPlan(at: selectedPlan) {
                    Task {
                        do {
                            _ = try await subscriptionsManager.buyProduct(package)
                            showSuccessBanner = true
                            dismiss.wrappedValue.dismiss()
                        } catch {
                            print("Purchase failed: \(error)")
                        }
                        isPurchasing = false
                    }
                } else { isPurchasing = false }
            } label: {
                Text(selectedPlan == 0 ? NSLocalizedString("premium.start_free_trial", comment: "") : NSLocalizedString("premium.subscribe_now", comment: ""))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [accentBrown, accentCoral],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: accentBrown.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .disabled(isPurchasing)
            .buttonStyle(.plain)

            Text(ctaFooterText)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(secondaryText)
        }
    }

    var footerLinks: some View {
        HStack(spacing: 16) {
            Button { Task { await subscriptionsManager.restorePurchases() } } label: {
                Text(NSLocalizedString("premium.restore_purchase", comment: ""))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(secondaryText)
            }

            Text("•")
                .font(.system(size: 12))
                .foregroundStyle(secondaryText)

            Button { openURL(URL(string: "https://fagore.com/terms/")!) } label: {
                Text(NSLocalizedString("menu.terms_of_service", comment: ""))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(secondaryText)
            }

            Text("•")
                .font(.system(size: 12))
                .foregroundStyle(secondaryText)

            Button { openURL(URL(string: "https://fagore.com/privacy/")!) } label: {
                Text(NSLocalizedString("menu.privacy_policy", comment: ""))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(secondaryText)
            }
        }
    }

    private var successBanner: some View {
        VStack {
            if showSuccessBanner {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.green)
                    Text(NSLocalizedString("premium.purchase_success", comment: ""))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.primary)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.55), lineWidth: 1)
                        )
                )
                .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        withAnimation { showSuccessBanner = false }
                    }
                }
            }
            Spacer()
        }
    }
}

// MARK: - Plan Display Model
struct PlanDisplay: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let tag: String?
    let productIndex: Int
}

// MARK: - Benefit Row
struct BenefitRow: View {
    let icon: String
    let text: String
    let iconBg: Color
    let iconColor: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconBg)
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            Text(text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: "2D2422"))

            Spacer()
        }
    }
}

// MARK: - Plan Card (New Design)
struct PlanCardNew: View {
    let plan: PlanDisplay
    let package: Package?
    let isSelected: Bool
    let action: () -> Void
    @State private var shimmerPhase: CGFloat = -1.5

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    if plan.tag != nil {
                        Color.clear.frame(height: 12)
                    }

                    Text(plan.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(hex: "FFF5EC"))
                        .shadow(color: .black.opacity(0.35), radius: 1, x: 0, y: 1)

                    Text(package?.localizedPriceString ?? (plan.title == "Yearly" ? "$49.99" : "$14.99"))
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(Color(hex: "FFF5EC"))
                        .shadow(color: .black.opacity(0.35), radius: 1, x: 0, y: 1)

                    Spacer()

                    Text(plan.subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.35), radius: 1, x: 0, y: 1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(16)
                .background(isSelected ? Color.white : Color.white.opacity(0.5))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(isSelected ? Color(hex: "FF4D85") : Color.white.opacity(0.8), lineWidth: isSelected ? 2.5 : 1)
                )
                .shadow(color: isSelected ? Color(hex: "FF4D85").opacity(0.15) : Color.black.opacity(0.04), radius: isSelected ? 12 : 8, x: 0, y: 6)

                if let tag = plan.tag {
                    Text(tag)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .tracking(0.5)
                        .textCase(.uppercase)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color(hex: "FF4D85"))
                        .clipShape(Capsule())
                        .shadow(color: Color(hex: "FF4D85").opacity(0.3), radius: 4, x: 0, y: 2)
                        .offset(y: -10)
                }
            }
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
    }
}

// MARK: - Topup Credits Paywall
struct TopupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) var openURL
    @EnvironmentObject private var subscriptionsManager: SubscriptionsManager

    @State private var selectedPlan = 2
    @State private var isPurchasing = false
    @State private var purchaseError: String?

    // Fallback when RevenueCat products haven't loaded yet
    private let fallbackPlans: [CreditPlanDisplay] = [
        CreditPlanDisplay(title: NSLocalizedString("topup.100_credits", comment: ""), subtitle: "$14.99", tag: nil, credits: 100, productIdentifier: "com.fagore.BabyUltra.100credits"),
        CreditPlanDisplay(title: NSLocalizedString("topup.250_credits", comment: ""), subtitle: "$29.99", tag: nil, credits: 250, productIdentifier: "com.fagore.BabyUltra.250credits"),
        CreditPlanDisplay(title: NSLocalizedString("topup.1000_credits", comment: ""), subtitle: "$99.99", tag: NSLocalizedString("premium.best_value", comment: ""), credits: 1000, productIdentifier: "com.fagore.BabyUltra.1000credits"),
    ]

    // Dynamic credit plans from RevenueCat
    private var creditPlans: [CreditPlanDisplay] {
        let products = subscriptionsManager.creditProducts
        if products.isEmpty { return fallbackPlans }

        let order = ["com.fagore.BabyUltra.100credits", "com.fagore.BabyUltra.250credits", "com.fagore.BabyUltra.1000credits"]
        return order.compactMap { id in
            guard let product = products.first(where: { $0.productIdentifier == id }) else { return nil }
            let info = fallbackPlans.first { $0.productIdentifier == id }
            return CreditPlanDisplay(
                title: info?.title ?? NSLocalizedString("topup.credits_label", comment: ""),
                subtitle: product.localizedPriceString,
                tag: info?.tag,
                credits: info?.credits ?? 0,
                productIdentifier: id
            )
        }
    }

    // Design colors
    private let creamBg = Color(hex: "FFF3F1")
    private let cardBg = Color.white.opacity(0.4)
    private let primaryText = Color(hex: "2D2422")
    private let secondaryText = Color.white
    private let accentBrown = Color(hex: "FF4D85")
    private let accentCoral = Color(hex: "FF88A8")

    var body: some View {
        ZStack {
            Image("bg")
                .resizable()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                closeButton
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .zIndex(1)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        heroSection
                            .padding(.top, 16)

                        benefitsSection
                            .padding(.horizontal, 24)

                        pricingSection
                            .padding(.horizontal, 24)

                        ctaSection
                            .padding(.horizontal, 24)

                        footerLinks
                            .padding(.top, 8)
                            .padding(.bottom, 32)
                    }
                }
            }
        }
        .preferredColorScheme(.light)
        .task {
            await subscriptionsManager.loadCreditProducts()
        }
    }

    var closeButton: some View {
        HStack {
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(primaryText)
                    .frame(width: 40, height: 40)
                    .background(Color(hex: "FFF3F1").opacity(0.5))
                    .background(.ultraThinMaterial.opacity(0.8))
                    .clipShape(Circle())
            }
        }
    }

    var heroSection: some View {
        VStack(spacing: 16) {
            // Credits Badge
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                Text(NSLocalizedString("topup.credits_badge", comment: ""))
                    .font(.system(size: 14, weight: .bold))
                    .tracking(1.0)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [accentBrown, accentCoral],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: accentBrown.opacity(0.3), radius: 8, x: 0, y: 4)

            // Titles
            VStack(spacing: 8) {
                Text(NSLocalizedString("topup.title", comment: ""))
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(primaryText)
                    .multilineTextAlignment(.center)
                    .tracking(-0.5)

                Text(NSLocalizedString("topup.subtitle", comment: ""))
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
        }
    }

    var benefitsSection: some View {
        VStack(spacing: 12) {
            BenefitRow(
                icon: "bolt.fill",
                text: NSLocalizedString("topup.benefit_instant", comment: ""),
                iconBg: Color(hex: "FF88A8").opacity(0.15),
                iconColor: Color(hex: "FF4D85")
            )
            BenefitRow(
                icon: "clock.fill",
                text: NSLocalizedString("topup.benefit_no_expiration", comment: ""),
                iconBg: Color(hex: "FF88A8").opacity(0.15),
                iconColor: Color(hex: "FF4D85")
            )
            BenefitRow(
                icon: "sparkles",
                text: NSLocalizedString("topup.benefit_all_templates", comment: ""),
                iconBg: Color(hex: "FF88A8").opacity(0.15),
                iconColor: Color(hex: "FF4D85")
            )
        }
        // Card background removed as requested
    }

    var pricingSection: some View {
        HStack(spacing: 12) {
            ForEach(creditPlans.indices, id: \.self) { index in
                CreditPlanCard(
                    plan: creditPlans[index],
                    isSelected: selectedPlan == index
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedPlan = index
                    }
                }
            }
        }
    }

    var ctaSection: some View {
        VStack(spacing: 12) {
            Button {
                isPurchasing = true
                purchaseError = nil
                Task {
                    await purchaseSelectedCredits()
                }
            } label: {
                Text(NSLocalizedString("topup.purchase_credits", comment: ""))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [accentBrown, accentCoral],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: accentBrown.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .disabled(isPurchasing || subscriptionsManager.isLoadingCredits)
            .buttonStyle(.plain)

            if let error = purchaseError {
                Text(error)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.red)
            }

            Text(NSLocalizedString("topup.one_time_purchase", comment: ""))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(secondaryText)
        }
    }

    private func purchaseSelectedCredits() async {
        let plans = creditPlans
        guard selectedPlan < plans.count else {
            isPurchasing = false
            return
        }
        let plan = plans[selectedPlan]

        guard let product = subscriptionsManager.creditProducts.first(where: { $0.productIdentifier == plan.productIdentifier }) else {
            isPurchasing = false
            purchaseError = NSLocalizedString("common.product_unavailable", comment: "")
            return
        }

        do {
            _ = try await subscriptionsManager.buyCreditProduct(product)
            dismiss() // Close paywall immediately after successful purchase
            try await BabyUltraAPI.shared.syncPurchases()
            await AuthManager.shared.fetchProfile()
            isPurchasing = false
        } catch {
            isPurchasing = false
            purchaseError = error.localizedDescription
        }
    }

    var footerLinks: some View {
        HStack(spacing: 16) {
            Button { Task { await subscriptionsManager.restorePurchases() } } label: {
                Text(NSLocalizedString("premium.restore_purchase", comment: ""))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(secondaryText)
            }

            Text("•")
                .font(.system(size: 12))
                .foregroundStyle(secondaryText)

            Button { openURL(URL(string: "https://fagore.com/terms/")!) } label: {
                Text(NSLocalizedString("menu.terms_of_service", comment: ""))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(secondaryText)
            }

            Text("•")
                .font(.system(size: 12))
                .foregroundStyle(secondaryText)

            Button { openURL(URL(string: "https://fagore.com/privacy/")!) } label: {
                Text(NSLocalizedString("menu.privacy_policy", comment: ""))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(secondaryText)
            }
        }
    }
}

// MARK: - Credit Plan Display Model
struct CreditPlanDisplay: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let tag: String?
    let credits: Int
    let productIdentifier: String
}

// MARK: - Credit Plan Card
struct CreditPlanCard: View {
    let plan: CreditPlanDisplay
    let isSelected: Bool
    let action: () -> Void

    private var bundleName: String {
        switch plan.credits {
        case 100: return NSLocalizedString("topup.bundle_tiny", comment: "")
        case 250: return NSLocalizedString("topup.bundle_family", comment: "")
        case 1000: return NSLocalizedString("topup.bundle_ultimate", comment: "")
        default: return "\(plan.credits) cr"
        }
    }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    if plan.tag != nil {
                        Color.clear.frame(height: 12)
                    }

                    Text(plan.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "FFF5EC"))
                        .shadow(color: .black.opacity(0.35), radius: 1, x: 0, y: 1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(plan.subtitle)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(Color(hex: "FFF5EC"))
                        .shadow(color: .black.opacity(0.35), radius: 1, x: 0, y: 1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Spacer()

                    Text(bundleName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.35), radius: 1, x: 0, y: 1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(14)
                .background(isSelected ? Color.white : Color.white.opacity(0.5))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(isSelected ? Color(hex: "FF4D85") : Color.white.opacity(0.8), lineWidth: isSelected ? 2.5 : 1)
                )
                .shadow(color: isSelected ? Color(hex: "FF4D85").opacity(0.15) : Color.black.opacity(0.04), radius: isSelected ? 10 : 6, x: 0, y: 4)

                if let tag = plan.tag {
                    Text(tag)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .tracking(0.5)
                        .textCase(.uppercase)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Color(hex: "FF4D85"))
                        .clipShape(Capsule())
                        .shadow(color: Color(hex: "FF4D85").opacity(0.3), radius: 4, x: 0, y: 2)
                        .offset(y: -8)
                }
            }
        }
        .frame(height: 110)
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.03 : 1.0)
    }
}
