import SwiftUI

// MARK: - Onboarding Screen (Warm Edition)
struct Intro: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var navigateToMain = false

    // Design colors
    private let bgColor = Color(hex: "FFF8F6")
    private let primaryText = Color(hex: "231917")
    private let secondaryText = Color(hex: "53433F")
    private let accentBrown = Color(hex: "904A33")
    private let accentCoral = Color(hex: "F08C6E")
    private let starColor = Color(hex: "6E5D2E")
    private let peachBlob = Color(hex: "FFDBD0")
    private let yellowBlob = Color(hex: "FAE1A6")

    var body: some View {
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea()

                backgroundGlows

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerBar
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        headlineSection
                            .padding(.horizontal, 24)
                            .padding(.top, 40)

                        heroVisual
                            .padding(.horizontal, 24)
                            .padding(.top, 48)

                        reviewsSection
                            .padding(.top, 40)

                        Color.clear.frame(height: 120)
                    }
                }

                bottomCTA
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .navigationDestination(isPresented: $navigateToMain) {
                MainTabView()
                    .navigationBarBackButtonHidden()
            }
        }
        .navigationBarBackButtonHidden()
        .preferredColorScheme(.light)
    }

    // MARK: Background Glows
    private var backgroundGlows: some View {
        ZStack {
            Circle()
                .fill(peachBlob.opacity(0.60))
                .frame(width: 500, height: 500)
                .blur(radius: 50)
                .offset(x: -150, y: -200)

            Circle()
                .fill(yellowBlob.opacity(0.60))
                .frame(width: 600, height: 600)
                .blur(radius: 60)
                .offset(x: 150, y: 100)

            Circle()
                .fill(peachBlob.opacity(0.40))
                .frame(width: 400, height: 400)
                .blur(radius: 50)
                .offset(x: 0, y: 450)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: Header Bar
    private var headerBar: some View {
        HStack {
            Spacer()

            Text("Bubsie")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(accentBrown)
                .tracking(-1.5)

            Spacer()
        }
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.40))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.60))
                .frame(height: 1),
            alignment: .bottom
        )
        .background(.ultraThinMaterial.opacity(0.3))
    }

    // MARK: Headline
    private var headlineSection: some View {
        VStack(spacing: 16) {
            Text("Turn giggles into\nMagical Moments")
                .font(.system(size: 36, weight: .heavy))
                .multilineTextAlignment(.center)
                .tracking(-0.9)
                .foregroundStyle(
                    LinearGradient(
                        colors: [accentBrown, accentCoral],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Watch your baby's photos come to life\nwith AI magic.")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
    }

    // MARK: Hero Visual
    private var heroVisual: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.40))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.80), lineWidth: 1)
                    )
                    .shadow(color: Color(hex: "904A33").opacity(0.05), radius: 32, x: 0, y: 8)

                VStack(spacing: 0) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "FEF1ED"))

                        Image("defaultpink")
                            .resizable()
                            .scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Floating UI Element
                        HStack(spacing: 12) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(accentBrown)
                                        .frame(width: 40, height: 40)
                                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)

                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.white)
                                }

                                Text("Processing magic...")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(primaryText)
                            }

                            Spacer()

                            // Loading dots
                            HStack(spacing: 4) {
                                ForEach(0..<3) { i in
                                    Circle()
                                        .fill(accentBrown)
                                        .frame(width: 8, height: 8)
                                        .opacity(0.6 + 0.4 * sin(Double(i) * 1.5))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.40))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.80), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color(hex: "904A33").opacity(0.05), radius: 32, x: 0, y: 8)
                        .background(.ultraThinMaterial.opacity(0.3))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                    .frame(height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(8)
                }
            }
        }
    }

    // MARK: Reviews Section
    private var reviewsSection: some View {
        VStack(spacing: 24) {
            Text("LOVED BY PARENTS")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(secondaryText)
                .tracking(1.4)
                .opacity(0.7)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ReviewCard(
                        quote: "\"Magical results! We couldn't\nstop watching the little dance\nvideo.\"",
                        initials: "SM",
                        name: "Sarah M.",
                        avatarBg: yellowBlob
                    )

                    ReviewCard(
                        quote: "\"So much fun! Sent it to the\ngrandparents and they cried\nlaughing.\"",
                        initials: "JR",
                        name: "James R.",
                        avatarBg: peachBlob
                    )
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: Bottom CTA
    private var bottomCTA: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.60))

            Button {
                hasSeenOnboarding = true
                navigateToMain = true
            } label: {
                HStack(spacing: 8) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .bold))

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [accentBrown, Color(hex: "A23F20")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color(hex: "904A33").opacity(0.30), radius: 40, x: 0, y: -10)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 40)
            .background(
                Color.white.opacity(0.40)
                    .overlay(
                        LinearGradient(
                            colors: [Color.white.opacity(0.40), Color.white.opacity(0.00)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
            )
            .background(.ultraThinMaterial.opacity(0.4))
        }
    }
}

// MARK: - Review Card
private struct ReviewCard: View {
    let quote: String
    let initials: String
    let name: String
    let avatarBg: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 4) {
                    ForEach(0..<5) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(hex: "6E5D2E"))
                    }
                }

                Text(quote)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(hex: "231917"))
                    .lineSpacing(2)
            }

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(avatarBg)
                        .frame(width: 32, height: 32)

                    Text(initials)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "241A00"))
                }

                Text(name)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color(hex: "53433F"))
            }
        }
        .padding(20)
        .frame(width: 288)
        .background(Color.white.opacity(0.40))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.80), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color(hex: "904A33").opacity(0.05), radius: 32, x: 0, y: 8)
        .background(.ultraThinMaterial.opacity(0.3))
    }
}

#Preview {
    Intro()
        .environmentObject(EntitlementManager())
        .environmentObject(SubscriptionsManager(entitlementManager: EntitlementManager()))
}
