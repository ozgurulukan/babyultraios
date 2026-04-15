import SwiftUI

// MARK: - Account View
struct AccountView: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var subscriptionManager: SubscriptionsManager
    @StateObject private var counter = CoinCounter()
    @StateObject private var auth = AuthManager.shared
    @State private var isPremiumShow = false
    @State private var showSettings = false
    @State private var showShareSheet = false
    @State private var showRedeemCode = false
    @Environment(\.openURL) var openURL

    /// Credits: prefer backend profile, fall back to local CoinCounter
    var displayCredits: Int { auth.currentUser?.credits ?? counter.coins }
    var isPro: Bool { auth.currentUser?.isPro ?? entitlementManager.hasPro }

    var body: some View {
        ZStack {
            Color.clear

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    profileHeader
                    creditsDashboard
                    if !isPro {
                        goPremiumCard
                    }
                    menuItems
                    versionTag
                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, 20)
            }
        }
        .task { await auth.fetchProfile() }
        .sheet(isPresented: $isPremiumShow) { PremiumView() }
        .sheet(isPresented: $showSettings) { Menu() }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: ["Check out Luris AI — stunning AI video & photo studio! 🎬 https://apps.apple.com"])
        }
        .sheet(isPresented: $showRedeemCode) { RedeemCodeView() }
    }

    // MARK: Profile Header
    var profileHeader: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Account")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(.white)
                if let name = auth.currentUser?.name, !name.isEmpty {
                    Text(name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Luris.textSecondary)
                        .lineLimit(1)
                }
                HStack(spacing: 6) {
                    if isPro {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Luris.accent)
                    }
                    Text(isPro ? "Premium Member" : "Free Plan")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(isPro ? Luris.accent : Luris.textSecondary)
                }
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(isPro ? Luris.accentGradient : LinearGradient(colors: [Luris.surface], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 52, height: 52)
                    .shadow(color: isPro ? Luris.accentRose.opacity(0.4) : .clear, radius: 8)
                Image(systemName: isPro ? "crown.fill" : "person.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isPro ? .white : Luris.textSecondary)
            }
        }
        .padding(.top, 16)
    }

    // MARK: Credits Dashboard
    var creditsDashboard: some View {
        let maxCredits = max(displayCredits, 8)
        return VStack(spacing: 16) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Credits Balance")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Luris.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("\(displayCredits)")
                            .font(.system(size: 48, weight: .heavy))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.5), value: displayCredits)
                        Text("credits")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Luris.textSecondary)
                            .padding(.bottom, 6)
                    }
                }
                Spacer()
                if let usage = auth.currentUser?.usage {
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("Today")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Luris.textSecondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        Text("\(usage.todayTotal)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                    }
                } else {
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("Used")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Luris.textSecondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        Text("\(max(0, 8 - displayCredits))")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Luris.surface)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Luris.progressGradient)
                            .frame(
                                width: geo.size.width * min(CGFloat(displayCredits) / CGFloat(maxCredits), 1.0),
                                height: 8
                            )
                            .animation(.spring(response: 0.6), value: displayCredits)
                            .shadow(color: Luris.accentRose.opacity(0.45), radius: 6)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("\(displayCredits)/\(maxCredits) remaining")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Luris.textSecondary)
                    Spacer()
                    if auth.isLoadingUser {
                        ProgressView().scaleEffect(0.7).tint(Luris.accent)
                    } else {
                        Text("Resets monthly")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Luris.textSecondary)
                    }
                }
            }
        }
        .padding(20)
        .background(Luris.card)
        .clipShape(RoundedRectangle(cornerRadius: Luris.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Luris.cardRadius)
                .stroke(Color(hex: "2A2A3E"), lineWidth: 0.5)
        )
    }

    // MARK: Go Premium
    var goPremiumCard: some View {
        Button { isPremiumShow = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Luris.accentFill)
                        .frame(width: 48, height: 48)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(
                            LinearGradient(colors: [Luris.accent, Luris.accentRose], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Go Premium")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Unlimited credits & all AI features")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Luris.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Luris.accent.opacity(0.8))
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color(hex: "100A1E"), Color(hex: "1A0A14")],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .gradientBorder(cornerRadius: 20, lineWidth: 1)
            .accentGlow(radius: 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: Menu Items
    var menuItems: some View {
        VStack(spacing: 0) {
            AccountRow(icon: "person.2.fill", color: Luris.accent, title: "Invite Friends", subtitle: "Share & earn bonus credits") {
                showShareSheet = true
            }
            menuDivider
            AccountRow(icon: "gift.fill", color: .orange, title: "Redeem Code", subtitle: "Enter your gift code") {
                showRedeemCode = true
            }
            menuDivider
            AccountRow(icon: "message.fill", color: .blue, title: "Contact Support", subtitle: "We're here to help") {
                openURL(URL(string: "https://support.apple.com")!)
            }
            menuDivider
            AccountRow(icon: "star.fill", color: .yellow, title: "Rate Us", subtitle: "Share your feedback") {
                openURL(URL(string: "https://apps.apple.com")!)
            }
            menuDivider
            AccountRow(icon: "gearshape.fill", color: Luris.textSecondary, title: "Settings", subtitle: "Preferences & privacy") {
                showSettings = true
            }
        }
        .background(Luris.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "2A2A3E"), lineWidth: 0.5))
    }

    var menuDivider: some View {
        Rectangle()
            .fill(Color(hex: "1C1C2E"))
            .frame(height: 0.5)
            .padding(.leading, 60)
    }

    var versionTag: some View {
        Text("Luris v1.0.2")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Luris.textSecondary)
            .padding(.top, 4)
    }
}

// MARK: - Account Row
struct AccountRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Luris.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Luris.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Redeem Code Sheet
struct RedeemCodeView: View {
    @Environment(\.presentationMode) var dismiss
    @State private var code = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedMeshBG()
                VStack(spacing: 24) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Luris.accent)
                        .padding(.top, 32)

                    Text("Redeem a Code")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(.white)

                    Text("Enter your gift code below to unlock credits or premium features.")
                        .font(.system(size: 15))
                        .foregroundStyle(Luris.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    TextField("XXXX-XXXX-XXXX", text: $code)
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                        .tint(Luris.accent)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Luris.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)

                    Button {
                        dismiss.wrappedValue.dismiss()
                    } label: {
                        Text("Apply Code")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Luris.accentGradient.opacity(code.isEmpty ? 0.35 : 1.0))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(code.isEmpty)
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationBarItems(leading: Button {
                dismiss.wrappedValue.dismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.white)
            })
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    AccountView()
        .environmentObject(EntitlementManager())
        .environmentObject(SubscriptionsManager(entitlementManager: EntitlementManager()))
}
