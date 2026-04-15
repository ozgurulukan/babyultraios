import SwiftUI
import StoreKit

// MARK: - Premium Paywall
struct PremiumView: View {
    @Environment(\.presentationMode) var dismiss
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var subscriptionsManager: SubscriptionsManager
    @Environment(\.openURL) var openURL

    @State private var selectedPlan = 1
    @State private var isPurchasing = false

    private let plans: [PaywallPlan] = [
        PaywallPlan(title: "Weekly", titleEN: "Weekly", price: "₺49,99", period: "/ week", credits: "3 credits", description: "3 AI credits every week", tag: nil),
        PaywallPlan(title: "Monthly", titleEN: "Monthly", price: "₺149,99", period: "/ month", credits: "20 credits", description: "20 AI credits every month", tag: "BEST VALUE"),
    ]

    var body: some View {
        ZStack {
            AnimatedMeshBG()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    closeRow
                    upgradePill
                    heroSection
                    featureTable
                    purchaseButton
                    footerLinks
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    var closeRow: some View {
        HStack {
            Button { dismiss.wrappedValue.dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(10)
                    .background(Luris.surface)
                    .clipShape(Circle())
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    var upgradePill: some View {
        PremiumPill()
            .padding(.top, 8)
    }

    var heroSection: some View {
        VStack(spacing: 12) {
            Text("Unlock More Power with Our\nMost Advanced AI")
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.top, 24)

            Text("Get more messages, smarter responses, and\npremium features designed for seamless productivity.")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Luris.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
    }

    // MARK: Feature Comparison Table
    var featureTable: some View {
        VStack(spacing: 0) {
            // Header row
            HStack {
                Spacer()
                Text("Free")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Luris.textSecondary)
                    .frame(width: 50)
                HStack(spacing: 4) {
                    Text("Pro")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                    Image(systemName: "sparkles")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Luris.accentGradient)
                .clipShape(Capsule())
                .frame(width: 65)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            let features: [(String, String, Bool, Bool)] = [
                ("bolt.fill", "More Daily Messages — Stay connected without limits.", false, true),
                ("brain.head.profile", "Access Our Most Powerful Model — Faster, sharper, and more accurate answers.", false, true),
                ("gauge.with.dots.needle.67percent", "Priority Performance — Quicker response times when you need them most.", false, true),
                ("star.fill", "Premium Features — Advanced tools and upcoming AI upgrades, always first to you.", false, true),
            ]

            ForEach(features.indices, id: \.self) { idx in
                let (icon, text, free, pro) = features[idx]
                VStack(spacing: 0) {
                    if idx > 0 {
                        Rectangle().fill(Color(hex: "1C1C2E")).frame(height: 0.5)
                    }
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Luris.accent)
                            .frame(width: 22)

                        Text(attributedFeature(text))
                            .font(.system(size: 13))
                            .foregroundStyle(.white)
                            .lineSpacing(2)

                        Spacer()

                        Image(systemName: free ? "checkmark" : "minus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(free ? Luris.accent : Luris.textSecondary.opacity(0.4))
                            .frame(width: 50)

                        Image(systemName: pro ? "checkmark.circle.fill" : "minus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(pro ? Luris.accent : Luris.textSecondary.opacity(0.4))
                            .frame(width: 65)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                }
            }
        }
        .background(Luris.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "2A2A3E"), lineWidth: 0.5))
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
    }

    func attributedFeature(_ text: String) -> AttributedString {
        var result = AttributedString(text)
        if let dashRange = result.range(of: " — ") {
            result[result.startIndex..<dashRange.lowerBound].font = .system(size: 13, weight: .bold)
            result[dashRange.upperBound...].foregroundColor = Luris.textSecondary
        }
        return result
    }

    var purchaseButton: some View {
        PremiumGradientButton("Upgrade to Pro") {
            isPurchasing = true
            let product = subscriptionsManager.products.indices.contains(selectedPlan)
                ? subscriptionsManager.products[selectedPlan] : nil
            if let product = product {
                Task {
                    await subscriptionsManager.buyProduct(product)
                    isPurchasing = false
                }
            } else { isPurchasing = false }
        }
        .disabled(isPurchasing)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .onAppear { Task { await subscriptionsManager.loadProducts() } }
    }

    var footerLinks: some View {
        VStack(spacing: 6) {
            Text("Auto-renews ₺149,99/monthly, cancel anytime.")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Luris.textSecondary)
            HStack(spacing: 0) {
                Button { Task { await subscriptionsManager.restorePurchases() } } label: {
                    Text("Restore").font(.system(size: 12, weight: .medium)).foregroundStyle(Luris.textSecondary)
                }
                Text(" · ").foregroundStyle(Luris.textSecondary.opacity(0.4))
                Button { openURL(URL(string: "https://www.apple.com")!) } label: {
                    Text("Privacy").font(.system(size: 12, weight: .medium)).foregroundStyle(Luris.textSecondary)
                }
                Text(" · ").foregroundStyle(Luris.textSecondary.opacity(0.4))
                Button { openURL(URL(string: "https://www.apple.com")!) } label: {
                    Text("Terms").font(.system(size: 12, weight: .medium)).foregroundStyle(Luris.textSecondary)
                }
            }
        }
        .padding(.bottom, 40)
    }
}

// MARK: - Paywall Plan Model
struct PaywallPlan {
    let title: String
    let titleEN: String
    let price: String
    let period: String
    let credits: String
    let description: String
    let tag: String?
}

// MARK: - Plan Card
struct PlanCard: View {
    let plan: PaywallPlan
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    if isSelected {
                        Circle().stroke(Luris.accentGradient, lineWidth: 2).frame(width: 22, height: 22)
                        Circle().fill(Luris.accentGradient).frame(width: 12, height: 12).accentGlow(radius: 6)
                    } else {
                        Circle().stroke(Color(hex: "2A2A3E"), lineWidth: 2).frame(width: 22, height: 22)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.title).font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
                        if let tag = plan.tag {
                            Text(tag)
                                .font(.system(size: 8, weight: .black)).foregroundStyle(.white)
                                .padding(.horizontal, 7).padding(.vertical, 3)
                                .background(Luris.accentGradient).clipShape(Capsule())
                        }
                    }
                    Text(plan.description).font(.system(size: 12, weight: .medium)).foregroundStyle(Luris.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text(plan.price).font(.system(size: 20, weight: .heavy)).foregroundStyle(isSelected ? Luris.accent : .white)
                    Text(plan.period).font(.system(size: 11, weight: .medium)).foregroundStyle(Luris.textSecondary)
                }
            }
            .padding(18)
            .background(isSelected ? Luris.accentFill : LinearGradient(colors: [Luris.card], startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Luris.accentGradient : LinearGradient(colors: [Color(hex: "2A2A3E")], startPoint: .leading, endPoint: .trailing), lineWidth: isSelected ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PremiumView()
        .environmentObject(EntitlementManager())
        .environmentObject(SubscriptionsManager(entitlementManager: EntitlementManager()))
}
