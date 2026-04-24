import SwiftUI
import StoreKit

// MARK: - Premium Paywall (New Design)
struct PremiumView: View {
    @Environment(\.presentationMode) var dismiss
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var subscriptionsManager: SubscriptionsManager
    @Environment(\.openURL) var openURL

    @State private var selectedPlan = 0
    @State private var isPurchasing = false

    private let planDisplays: [PlanDisplay] = [
        PlanDisplay(
            title: "Yearly",
            subtitle: "Just $4.16 / month",
            tag: "BEST VALUE",
            productIndex: 0
        ),
        PlanDisplay(
            title: "Weekly",
            subtitle: "Billed weekly",
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
                Text("PRO")
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
            Text("Unlock the Magic\nfor Bubsie")
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(primaryText)
                .multilineTextAlignment(.center)
                .tracking(-0.5)

            Text("Transform every giggle into a\nmasterpiece.")
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
                text: "Unlimited AI Transforms",
                iconBg: Color(hex: "F08C6E").opacity(0.20),
                iconColor: Color(hex: "97462E")
            )
            BenefitRow(
                icon: "tag.fill",
                text: "Access to all PRO Templates",
                iconBg: Color(hex: "FEB246").opacity(0.20),
                iconColor: Color(hex: "845400")
            )
            BenefitRow(
                icon: "drop.fill",
                text: "No Watermarks on results",
                iconBg: Color(hex: "FB856D").opacity(0.20),
                iconColor: Color(hex: "9F402D")
            )
            BenefitRow(
                icon: "arrow.down.circle.fill",
                text: "High-Resolution Downloads",
                iconBg: Color(hex: "F08C6E").opacity(0.20),
                iconColor: Color(hex: "97462E")
            )
        }
    }

    var pricingSection: some View {
        HStack(spacing: 16) {
            ForEach(planDisplays.indices, id: \.self) { index in
                PlanCardNew(
                    plan: planDisplays[index],
                    product: productForPlan(at: index),
                    isSelected: selectedPlan == index
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedPlan = index
                    }
                }
            }
        }
    }

    func productForPlan(at index: Int) -> Product? {
        let productIdx = planDisplays[index].productIndex
        guard subscriptionsManager.products.indices.contains(productIdx) else { return nil }
        return subscriptionsManager.products[productIdx]
    }

    var ctaSection: some View {
        VStack(spacing: 12) {
            Button {
                isPurchasing = true
                if let product = productForPlan(at: selectedPlan) {
                    Task {
                        await subscriptionsManager.buyProduct(product)
                        isPurchasing = false
                    }
                } else { isPurchasing = false }
            } label: {
                Text("Start My Free Trial")
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

            Text("3 days free, then $49.99/year.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(secondaryText)
        }
    }

    var footerLinks: some View {
        HStack(spacing: 16) {
            Button { Task { await subscriptionsManager.restorePurchases() } } label: {
                Text("Restore Purchase")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(secondaryText)
            }

            Text("•")
                .font(.system(size: 11))
                .foregroundStyle(secondaryText)

            Button { openURL(URL(string: "https://fagore.com/terms/")!) } label: {
                Text("Terms")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(secondaryText)
            }

            Text("•")
                .font(.system(size: 11))
                .foregroundStyle(secondaryText)

            Button { openURL(URL(string: "https://fagore.com/privacy/")!) } label: {
                Text("Privacy Policy")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(secondaryText)
            }
        }
        .padding(.bottom, 16)
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
    let product: Product?
    let isSelected: Bool
    let action: () -> Void

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

                    Text(product?.displayPrice ?? (plan.title == "Yearly" ? "$49.99" : "$14.99"))
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
                        .clipShape(Capsule())
                        .offset(y: -8)
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

    @State private var selectedPlan = 1
    @State private var isPurchasing = false

    // Placeholder credit packs — update prices later
    private let creditPlans: [CreditPlanDisplay] = [
        CreditPlanDisplay(
            title: "100 Credits",
            subtitle: "$14.99",
            tag: nil,
            credits: 100
        ),
        CreditPlanDisplay(
            title: "250 Credits",
            subtitle: "$29.99",
            tag: nil,
            credits: 250
        ),
        CreditPlanDisplay(
            title: "1,000 Credits",
            subtitle: "$99.99",
            tag: "BEST VALUE",
            credits: 1000
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
                Text("CREDITS")
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
            Text("Top Up Your\nCredits")
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(primaryText)
                .multilineTextAlignment(.center)
                .tracking(-0.5)

            Text("Get more AI transforms whenever\nyou need them.")
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
                text: "Instant Delivery",
                iconBg: Color(hex: "F08C6E").opacity(0.20),
                iconColor: Color(hex: "97462E")
            )
            BenefitRow(
                icon: "clock.fill",
                text: "Use Anytime — No Expiration",
                iconBg: Color(hex: "FEB246").opacity(0.20),
                iconColor: Color(hex: "845400")
            )
            BenefitRow(
                icon: "sparkles",
                text: "Works with All Templates",
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
                // TODO: Wire up purchase logic
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isPurchasing = false
                    dismiss()
                }
            } label: {
                Text("Purchase Credits")
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

            Text("One-time purchase. No subscription.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(secondaryText)
        }
    }

    var footerLinks: some View {
        HStack(spacing: 16) {
            Button { /* TODO: restore purchases if needed */ } label: {
                Text("Restore Purchase")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(secondaryText)
            }

            Text("•")
                .font(.system(size: 11))
                .foregroundStyle(secondaryText)

            Button { openURL(URL(string: "https://fagore.com/terms/")!) } label: {
                Text("Terms")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(secondaryText)
            }

            Text("•")
                .font(.system(size: 11))
                .foregroundStyle(secondaryText)

            Button { openURL(URL(string: "https://fagore.com/privacy/")!) } label: {
                Text("Privacy Policy")
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
}

// MARK: - Credit Plan Card
struct CreditPlanCard: View {
    let plan: CreditPlanDisplay
    let isSelected: Bool
    let action: () -> Void

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

                    Spacer()

                    Text("\(plan.credits) cr")
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
                        .clipShape(Capsule())
                        .offset(y: -8)
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
}
