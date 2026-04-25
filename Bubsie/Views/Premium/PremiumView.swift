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
    private let creamBg = Color(hex: "FFF9EC")
    private let cardBg = Color.white
    private let primaryText = Color(hex: "1E1C10")
    private let secondaryText = Color(hex: "55433E")
    private let accentBrown = Color(hex: "97462E")
    private let accentCoral = Color(hex: "F08C6E")
    private let starYellow = Color(hex: "845400")

    var body: some View {
        ZStack {
            creamBg.ignoresSafeArea()

            VStack(spacing: 0) {
                closeButton
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .zIndex(1)

                mainCard
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 12)
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
                    .background(Color(hex: "E9E2D0").opacity(0.5))
                    .background(.ultraThinMaterial.opacity(0.3))
                    .clipShape(Circle())
            }
        }
    }

    var mainCard: some View {
        VStack(spacing: 0) {
            heroSection

            VStack(spacing: 14) {
                copySection
                    .padding(.top, 16)

                benefitsSection
                    .padding(.horizontal, 8)

                pricingSection

                ctaSection

                footerLinks
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 40))
        .shadow(color: Color(hex: "1E1C10").opacity(0.06), radius: 24, x: 0, y: 8)
    }

    var heroSection: some View {
        ZStack(alignment: .topLeading) {
            Image("defaultpaywallbg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 180)
                .clipped()

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .white.opacity(0.4), location: 0.5),
                    .init(color: .white, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 180)

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                Text(NSLocalizedString("premium.pro_badge", comment: ""))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .tracking(0.6)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(starYellow)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            .padding(.leading, 16)
            .padding(.top, 16)
        }
        .frame(height: 180)
    }

    var copySection: some View {
        VStack(spacing: 6) {
            Text(NSLocalizedString("premium.unlock_title", comment: ""))
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(primaryText)
                .multilineTextAlignment(.center)
                .tracking(-0.5)

            Text(NSLocalizedString("premium.unlock_subtitle", comment: ""))
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
    }

    var benefitsSection: some View {
        VStack(spacing: 10) {
            BenefitRow(
                icon: "sparkles",
                text: NSLocalizedString("premium.benefit_pro_templates", comment: ""),
                iconBg: Color(hex: "F08C6E").opacity(0.20),
                iconColor: Color(hex: "97462E")
            )
            BenefitRow(
                icon: "tag.fill",
                text: NSLocalizedString("premium.benefit_credits", comment: ""),
                iconBg: Color(hex: "F08C6E").opacity(0.20),
                iconColor: Color(hex: "97462E")
            )
            BenefitRow(
                icon: "drop.fill",
                text: NSLocalizedString("premium.benefit_no_watermark", comment: ""),
                iconBg: Color(hex: "FB856D").opacity(0.20),
                iconColor: Color(hex: "97462E")
            )
            BenefitRow(
                icon: "arrow.down.circle.fill",
                text: NSLocalizedString("premium.benefit_4k", comment: ""),
                iconBg: Color(hex: "F08C6E").opacity(0.20),
                iconColor: Color(hex: "97462E")
            )
        }
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
        if let package = packageForPlan(at: selectedPlan) {
            let unit = package.storeProduct.subscriptionPeriod?.unit
            let periodText = unit == .week ? NSLocalizedString("common.week_unit", comment: "") : NSLocalizedString("common.year_unit", comment: "")
            return String(format: NSLocalizedString("premium.trial_format", comment: ""), package.localizedPriceString, periodText)
        }
        return selectedPlan == 0 ? NSLocalizedString("premium.yearly_fallback", comment: "") : NSLocalizedString("premium.weekly_fallback", comment: "")
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
                Text(NSLocalizedString("premium.start_free_trial", comment: ""))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [accentBrown, accentCoral],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 4)
            }
            .disabled(isPurchasing)
            .buttonStyle(.plain)

            Text(ctaFooterText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(secondaryText)
        }
    }

    var footerLinks: some View {
        HStack(spacing: 16) {
            Button { Task { await subscriptionsManager.restorePurchases() } } label: {
                Text(NSLocalizedString("premium.restore_purchase", comment: ""))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(secondaryText)
            }

            Text("•")
                .font(.system(size: 11))
                .foregroundStyle(secondaryText)

            Button { openURL(URL(string: "https://fagore.com/terms/")!) } label: {
                Text(NSLocalizedString("menu.terms_of_service", comment: ""))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(secondaryText)
            }

            Text("•")
                .font(.system(size: 11))
                .foregroundStyle(secondaryText)

            Button { openURL(URL(string: "https://fagore.com/privacy/")!) } label: {
                Text(NSLocalizedString("menu.privacy_policy", comment: ""))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(secondaryText)
            }
        }
        .padding(.bottom, 16)
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
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.35), Color.white.opacity(0.08)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
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
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconBg)
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "1E1C10"))

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
                    // Reserve space for badge so text doesn't overlap
                    if plan.tag != nil {
                        Color.clear.frame(height: 10)
                    }

                    Text(plan.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "55433E"))

                    Text(package?.localizedPriceString ?? (plan.title == "Yearly" ? "$49.99" : "$14.99"))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color(hex: "1E1C10"))

                    Spacer()

                    Text(plan.subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color(hex: "55433E"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(12)
                .background(isSelected ? Color(hex: "E9E2D0") : Color(hex: "FAF3E0"))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(isSelected ? Color(hex: "97462E") : Color.clear, lineWidth: 2)
                )

                if let tag = plan.tag {
                    Text(tag)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .tracking(0.5)
                        .textCase(.uppercase)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Color(hex: "97462E"))
                        .overlay(
                            GeometryReader { geo in
                                LinearGradient(
                                    colors: [.clear, Color.white.opacity(0.55), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: geo.size.width * 0.6)
                                .offset(x: shimmerPhase * geo.size.width)
                            }
                        )
                        .clipShape(Capsule())
                        .offset(y: -8)
                        .onAppear {
                            withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                                shimmerPhase = 1.5
                            }
                        }
                }
            }
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
    }
}

#Preview {
    PremiumView()
        .environmentObject(EntitlementManager())
        .environmentObject(SubscriptionsManager(entitlementManager: EntitlementManager()))
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
        CreditPlanDisplay(title: NSLocalizedString("topup.100_credits", comment: ""), subtitle: "$14.99", tag: nil, credits: 100, productIdentifier: "com.fagore.bubsie.100credits"),
        CreditPlanDisplay(title: NSLocalizedString("topup.250_credits", comment: ""), subtitle: "$29.99", tag: nil, credits: 250, productIdentifier: "com.fagore.bubsie.250credits"),
        CreditPlanDisplay(title: NSLocalizedString("topup.1000_credits", comment: ""), subtitle: "$99.99", tag: NSLocalizedString("premium.best_value", comment: ""), credits: 1000, productIdentifier: "com.fagore.bubsie.1000credits"),
    ]

    // Dynamic credit plans from RevenueCat
    private var creditPlans: [CreditPlanDisplay] {
        let products = subscriptionsManager.creditProducts
        if products.isEmpty { return fallbackPlans }

        let order = ["com.fagore.bubsie.100credits", "com.fagore.bubsie.250credits", "com.fagore.bubsie.1000credits"]
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
    private let creamBg = Color(hex: "FFF9EC")
    private let cardBg = Color.white
    private let primaryText = Color(hex: "1E1C10")
    private let secondaryText = Color(hex: "55433E")
    private let accentBrown = Color(hex: "97462E")
    private let accentCoral = Color(hex: "F08C6E")
    private let starYellow = Color(hex: "845400")

    var body: some View {
        ZStack {
            creamBg.ignoresSafeArea()

            VStack(spacing: 0) {
                closeButton
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .zIndex(1)

                mainCard
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 12)
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
                    .background(Color(hex: "E9E2D0").opacity(0.5))
                    .background(.ultraThinMaterial.opacity(0.3))
                    .clipShape(Circle())
            }
        }
    }

    var mainCard: some View {
        VStack(spacing: 0) {
            heroSection

            VStack(spacing: 14) {
                copySection
                    .padding(.top, 16)

                benefitsSection
                    .padding(.horizontal, 8)

                pricingSection

                ctaSection

                footerLinks
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 40))
        .shadow(color: Color(hex: "1E1C10").opacity(0.06), radius: 24, x: 0, y: 8)
    }

    var heroSection: some View {
        ZStack(alignment: .topLeading) {
            Image("defaulttopupheader")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 180)
                .clipped()

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .white.opacity(0.4), location: 0.5),
                    .init(color: .white, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 180)

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                Text(NSLocalizedString("topup.credits_badge", comment: ""))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .tracking(0.6)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(starYellow)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            .padding(.leading, 16)
            .padding(.top, 16)
        }
        .frame(height: 180)
    }

    var copySection: some View {
        VStack(spacing: 6) {
            Text(NSLocalizedString("topup.title", comment: ""))
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(primaryText)
                .multilineTextAlignment(.center)
                .tracking(-0.5)

            Text(NSLocalizedString("topup.subtitle", comment: ""))
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
    }

    var benefitsSection: some View {
        VStack(spacing: 10) {
            BenefitRow(
                icon: "bolt.fill",
                text: NSLocalizedString("topup.benefit_instant", comment: ""),
                iconBg: Color(hex: "F08C6E").opacity(0.20),
                iconColor: Color(hex: "97462E")
            )
            BenefitRow(
                icon: "clock.fill",
                text: NSLocalizedString("topup.benefit_no_expiration", comment: ""),
                iconBg: Color(hex: "F08C6E").opacity(0.20),
                iconColor: Color(hex: "97462E")
            )
            BenefitRow(
                icon: "sparkles",
                text: NSLocalizedString("topup.benefit_all_templates", comment: ""),
                iconBg: Color(hex: "FB856D").opacity(0.20),
                iconColor: Color(hex: "9F402D")
            )
        }
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
                if subscriptionsManager.creditProducts.indices.contains(selectedPlan) {
                    let product = subscriptionsManager.creditProducts[selectedPlan]
                    Task {
                        do {
                            _ = try await subscriptionsManager.buyCreditProduct(product)
                            dismiss()
                        } catch {
                            print("Purchase failed: \(error)")
                            purchaseError = error.localizedDescription
                        }
                        isPurchasing = false
                    }
                } else {
                    isPurchasing = false
                }
            } label: {
                Text(NSLocalizedString("topup.purchase_credits", comment: ""))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [accentBrown, accentCoral],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 4)
            }
            .disabled(isPurchasing || subscriptionsManager.isLoadingCredits)
            .buttonStyle(.plain)

            if let error = purchaseError {
                Text(error)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.red)
            }

            Text(NSLocalizedString("topup.one_time_purchase", comment: ""))
                .font(.system(size: 12, weight: .medium))
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
            try? await BubsieAPI.shared.syncPurchases()
            await AuthManager.shared.fetchProfile()
            isPurchasing = false
            dismiss()
        } catch {
            isPurchasing = false
            purchaseError = error.localizedDescription
        }
    }

    var footerLinks: some View {
        HStack(spacing: 16) {
            Button { Task { await subscriptionsManager.restorePurchases() } } label: {
                Text(NSLocalizedString("premium.restore_purchase", comment: ""))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(secondaryText)
            }

            Text("•")
                .font(.system(size: 11))
                .foregroundStyle(secondaryText)

            Button { openURL(URL(string: "https://fagore.com/terms/")!) } label: {
                Text(NSLocalizedString("menu.terms_of_service", comment: ""))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(secondaryText)
            }

            Text("•")
                .font(.system(size: 11))
                .foregroundStyle(secondaryText)

            Button { openURL(URL(string: "https://fagore.com/privacy/")!) } label: {
                Text(NSLocalizedString("menu.privacy_policy", comment: ""))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(secondaryText)
            }
        }
        .padding(.bottom, 16)
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
    @State private var shimmerPhase: CGFloat = -1.5

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
                    // Reserve space for badge so text doesn't overlap
                    if plan.tag != nil {
                        Color.clear.frame(height: 10)
                    }

                    Text(plan.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(hex: "55433E"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(plan.subtitle)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color(hex: "1E1C10"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Spacer()

                    Text(bundleName)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color(hex: "55433E"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(12)
                .background(isSelected ? Color(hex: "E9E2D0") : Color(hex: "FAF3E0"))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(isSelected ? Color(hex: "97462E") : Color.clear, lineWidth: 2)
                )

                if let tag = plan.tag {
                    Text(tag)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .tracking(0.5)
                        .textCase(.uppercase)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Color(hex: "97462E"))
                        .overlay(
                            GeometryReader { geo in
                                LinearGradient(
                                    colors: [.clear, Color.white.opacity(0.55), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: geo.size.width * 0.6)
                                .offset(x: shimmerPhase * geo.size.width)
                            }
                        )
                        .clipShape(Capsule())
                        .offset(y: -8)
                        .onAppear {
                            withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                                shimmerPhase = 1.5
                            }
                        }
                }
            }
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
    }
}

#Preview("Topup") {
    TopupView()
        .environmentObject(SubscriptionsManager(entitlementManager: EntitlementManager()))
}
